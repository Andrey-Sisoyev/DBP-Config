-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> confentityparam.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_cpvalue_uni AS (
          type                t_confparam_type
        , value               varchar
        , lng_code_id         integer
        , subcfg_ref_param_id varchar
        , subcfg_ref_usage    t_subconfig_value_linking_read_rule
        );

CREATE OR REPLACE FUNCTION mk_cpvalue_null() RETURNS t_cpvalue_uni AS $$
        SELECT ROW(NULL :: t_confparam_type, NULL :: varchar, NULL :: integer, NULL :: varchar, NULL :: varchar) :: sch_<<$app_name$>>.t_cpvalue_uni;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION mk_cpvalue_l(value varchar, lng integer) RETURNS t_cpvalue_uni AS $$
        SELECT ROW('leaf' :: t_confparam_type, $1, $2, NULL :: varchar, NULL :: varchar) :: sch_<<$app_name$>>.t_cpvalue_uni;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION mk_cpvalue_s(
          value               varchar
        , subcfg_ref_param_id varchar
        , subcfg_ref_usage    t_subconfig_value_linking_read_rule
        ) RETURNS t_cpvalue_uni AS $$
        SELECT ROW('subconfig' :: t_confparam_type, $1, NULL :: integer, $2, $3) :: sch_<<$app_name$>>.t_cpvalue_uni;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION isconsistent_cpvalue(par_value t_cpvalue_uni) RETURNS boolean AS $$
        SELECT CASE $1 IS NULL
                   WHEN TRUE THEN TRUE
                   ELSE CASE
                            WHEN ($1.type IS NULL) THEN FALSE
                            ELSE ($1.type IS DISTINCT FROM 'subconfig') OR ($1.subcfg_ref_usage IS NOT NULL)
                        END
               END
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION isdefined_cpvalue(par_value t_cpvalue_uni) RETURNS boolean AS $$
        SELECT CASE $1 IS NULL
                   WHEN TRUE THEN FALSE
                   ELSE CASE
                            WHEN ($1.type IS NULL) THEN FALSE
                            WHEN ($1.type IS DISTINCT FROM 'subconfig') THEN ($1.value IS NOT NULL)
                            ELSE CASE
                                     WHEN ($1.subcfg_ref_usage IS NULL) THEN FALSE
                                     WHEN ($1.subcfg_ref_usage IS NOT DISTINCT FROM 'alw_onl_lnk') THEN ($1.subcfg_ref_param_id IS NOT NULL)
                                     WHEN ($1.subcfg_ref_usage IS NOT DISTINCT FROM      'no_lnk') THEN ($1.value IS NOT NULL)
                                     ELSE ($1.value IS NOT NULL) OR ($1.subcfg_ref_param_id IS NOT NULL)
                                 END
                        END
               END
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION isnull_cpvalue(
          par_value t_cpvalue_uni
        , par_total boolean
        ) RETURNS boolean AS $$
        SELECT CASE $1 IS NULL
                   WHEN TRUE THEN TRUE
                   ELSE CASE $2 IS NOT DISTINCT FROM TRUE
                            WHEN TRUE THEN
                                $1 IS NULL
                            ELSE NOT (sch_<<$app_name$>>.isconsistent_cpvalue($1) AND sch_<<$app_name$>>.isdefined_cpvalue($1))
                        END
               END
$$ LANGUAGE SQL IMMUTABLE;

--------------------------------------------------------------------------

CREATE TYPE t_cparameter_uni AS (
          param_id                    varchar
        , type                        t_confparam_type
        , constraints_array           t_confparam_constraint[]
        , allow_null_final_value      boolean
        , use_default_instead_of_null t_confparam_default_usage
        , subconfentity_code_id       integer
        , lnged_paramvalue_dflt_src   t_lnged_paramvalue_dflt_src
        , default_value               t_cpvalue_uni
        );

CREATE OR REPLACE FUNCTION mk_cparameter_uni(
          par_param_id                    varchar
        , par_type                        t_confparam_type
        , par_constraints_array           t_confparam_constraint[]
        , par_allow_null_final_value      boolean
        , par_use_default_instead_of_null t_confparam_default_usage
        , par_subconfentity_code_id       integer
        , par_lnged_paramvalue_dflt_src   t_lnged_paramvalue_dflt_src
        , par_default_value               t_cpvalue_uni
        ) RETURNS t_cparameter_uni AS $$
DECLARE r sch_<<$app_name$>>.t_cparameter_uni;
BEGIN
        IF par_type IS NOT NULL AND par_default_value IS NOT NULL THEN
                IF    (par_default_value.type IS NOT NULL)
                  AND (par_type IS DISTINCT FROM par_default_value.type)
                THEN RAISE EXCEPTION 'Incoherent types of parameter and it''s default value.';
                END IF;
        END IF;
        r:= ROW( par_param_id
               , par_type
               , par_constraints_array
               , par_allow_null_final_value
               , par_use_default_instead_of_null
               , par_subconfentity_code_id
               , par_lnged_paramvalue_dflt_src
               , par_default_value
               ) :: sch_<<$app_name$>>.t_cparameter_uni;
        RETURN r;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

--------------------------------------------------------------------------

CREATE TYPE t_confentityparam_key AS (confentity_key t_confentity_key, param_key varchar, param_key_is_lnged boolean);

COMMENT ON TYPE t_confentityparam_key IS
'If "t_confentityparam_key.key_is_lnged" is TRUE, then the language of "t_confentityparam_key.key" field is assumed to be the same, as one specified for "confentity_key".
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_confentityparamkey(par_confentity_key t_confentity_key, key varchar, key_is_lnged boolean) RETURNS t_confentityparam_key AS $$
        SELECT ROW($1, $2, $3) :: sch_<<$app_name$>>.t_confentityparam_key;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_confentityparamkey_null() RETURNS t_confentityparam_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_confentitykey_null(), NULL :: varchar, NULL :: varchar) :: sch_<<$app_name$>>.t_confentityparam_key;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_confentityparamkey_bystr(par_confentity_id integer, par_param varchar) RETURNS t_confentityparam_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_confentitykey_byid($1), $2, FALSE) :: sch_<<$app_name$>>.t_confentityparam_key;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_confentityparamkey_bystr2(par_confentity_str varchar, par_param varchar) RETURNS t_confentityparam_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_confentitykey_bystr($1), $2, FALSE) :: sch_<<$app_name$>>.t_confentityparam_key;
$$ LANGUAGE SQL IMMUTABLE;

--------------

CREATE OR REPLACE FUNCTION confentityparam_is_null(par_confparam_key t_confentityparam_key, par_total boolean) RETURNS boolean AS $$
        SELECT CASE WHEN $1 IS NULL THEN TRUE
                    ELSE CASE $2
                             WHEN TRUE THEN
                                 sch_<<$app_name$>>.confentity_is_null(($1).confentity_key) AND (($1).param_key IS NULL) AND (($1).param_key_is_lnged IS NULL)
                             WHEN FALSE THEN
                                 sch_<<$app_name$>>.confentity_is_null(($1).confentity_key) OR  (($1).param_key IS NULL) OR (($1).param_key_is_lnged IS NULL)
                         END
               END;
$$ LANGUAGE SQL IMMUTABLE;

--------------

CREATE OR REPLACE FUNCTION show_confentityparamkey(par_confparam_key t_confentityparam_key) RETURNS varchar AS $$
        SELECT '{t_confentityparam_key | '
            || ( CASE WHEN sch_<<$app_name$>>.confentityparam_is_null($1, TRUE) THEN 'NULL'
                      ELSE (  CASE WHEN sch_<<$app_name$>>.confentity_is_null(($1).confentity_key) THEN ''
                                   ELSE 'confentity_key:' || sch_<<$app_name$>>.show_confentitykey(($1).confentity_key) || ';'
                              END
                           )
                        || (  CASE WHEN ($1).param_key IS NULL THEN ''
                                   ELSE 'param_key:"' || ($1).param_key || '";'
                              END
                           )
                        || (  CASE WHEN ($1).param_key_is_lnged IS NULL THEN ''
                                   ELSE 'param_key_is_lnged:' || ($1).param_key_is_lnged
                              END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL IMMUTABLE;

--------------

CREATE OR REPLACE FUNCTION optimized_confentityparamkey_isit(par_confparam_key t_confentityparam_key) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE r boolean;
BEGIN
        IF par_confparam_key.param_key_is_lnged IS NULL THEN
                RAISE EXCEPTION 'An error occurred in the "optimized_confentityparamkey_isit" function! Argument is not allowed to have NULL in ".param_key_is_lnged"!';
        END IF;
        IF par_confparam_key.param_key IS NULL THEN
                RAISE EXCEPTION 'An error occurred in the "optimized_confentityparamkey_isit" function! Argument is not allowed to have NULL in ".param_key"!';
        END IF;
        SELECT CASE WHEN sch_<<$app_name$>>.confentityparam_is_null(par_confparam_key, FALSE) THEN FALSE
                    ELSE sch_<<$app_name$>>.optimized_confentitykey_isit(par_confparam_key.confentity_key)
                     AND NOT par_confparam_key.param_key_is_lnged
               END
        INTO r;
        RETURN r;
END;
$$;

--------------

CREATE OR REPLACE FUNCTION optimize_confentityparamkey(par_confparam_key t_confentityparam_key, par_verify boolean) RETURNS t_confentityparam_key
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;
        n varchar;
        r sch_<<$app_name$>>.t_confentityparam_key;
        rows_count integer;
BEGIN
        -- if (par_confparam_key.param).key_is_lnged IS NULL the exception is rised!
        IF sch_<<$app_name$>>.optimized_confentityparamkey_isit(par_confparam_key) AND NOT par_verify THEN
                RETURN par_confparam_key;
        END IF;

        g:= optimize_confentitykey(FALSE, par_confparam_key.confentity_key);

        IF codekey_type((g.confentity_codekeyl).key_lng) = 'c_id' AND par_confparam_key.param_key_is_lnged THEN
                SELECT p_n.parameter_id
                INTO n
                FROM configurations_parameters_names AS p_n
                WHERE p_n.name               = par_confparam_key.param_key
                  AND p_n.confentity_code_id = code_id_of_confentitykey(g)
                  AND p_n.lng_of_name        = ((g.confentity_codekeyl).key_lng).code_id;

                GET DIAGNOSTICS rows_count = ROW_COUNT;

                IF (rows_count != 1) THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_confentityparamkey" for key: %! Parameter not found.', show_confentityparamkey(par_confparam_key);
                END IF;
        ELSIF par_confparam_key.param_key_is_lnged THEN
                RAISE EXCEPTION 'An error occurred in function "optimize_confentityparamkey" for key: %! Parameter key is languaged, but language is not specified!', show_confentityparamkey(par_confparam_key);
        ELSE
                IF par_verify THEN
                        SELECT p.parameter_id
                        INTO n
                        FROM configurations_parameters AS p
                        WHERE p.parameter_id       = par_confparam_key.param_key
                          AND p.confentity_code_id = code_id_of_confentitykey(g);

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF (rows_count != 1) THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_confentityparamkey" for key: %! Verification failed - parameter not found.', show_confentityparamkey(par_confparam_key);
                        END IF;
                ELSE
                        n:= par_confparam_key.param_key;
                END IF;
        END IF;
        r:= make_confentityparamkey(g, n, FALSE);

        RETURN r;
END;
$$;

--------------

CREATE OR REPLACE FUNCTION determine_cparameter(par_confparam_key t_confentityparam_key) RETURNS t_cparameter_uni
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g  sch_<<$app_name$>>.t_confentityparam_key;
        n  varchar;
        r  sch_<<$app_name$>>.t_cparameter_uni;
        rec        RECORD;
        rows_count integer;
BEGIN
        g:= optimize_confentityparamkey(par_confparam_key, FALSE);

        SELECT mk_cparameter_uni(
                  g.param_key
                , cp.parameter_type
                , cp.constraints_array
                , cp.allow_null_final_value
                , cp.use_default_instead_of_null
                , NULL :: integer
                , NULL :: t_lnged_paramvalue_dflt_src
                , mk_cpvalue_null()
                ) AS r1
        INTO rec
        FROM configurations_parameters AS cp
        WHERE cp.parameter_id       = g.param_key
          AND cp.confentity_code_id = code_id_of_confentitykey(g.confentity_key);

        GET DIAGNOSTICS rows_count = ROW_COUNT;
        IF rows_count = 0 THEN
                RAISE EXCEPTION 'An error occurred in function "determine_cparameter" for key: %! Parameter not found.', show_confentityparamkey(g);
        END IF;

        r:= rec.r1;

        CASE r.type
            WHEN 'leaf' THEN
                FOR rec IN
                      SELECT mk_cpvalue_l(cp_l.default_value, NULL :: integer) AS r1
                           , cp_l.lnged_paramvalue_dflt_src AS r2
                      FROM configurations_parameters__leafs AS cp_l
                      WHERE cp_l.parameter_id       = g.param_key
                        AND cp_l.confentity_code_id = code_id_of_confentitykey(g.confentity_key)
                LOOP
                      r.default_value:= rec.r1;
                      r.lnged_paramvalue_dflt_src:= rec.r2;
                END LOOP;
            WHEN 'subconfig' THEN
                FOR rec IN
                      SELECT mk_cpvalue_s(
                                cp_s.overload_default_subconfig
                              , cp_s.overload_default_link
                              , cp_s.overload_default_link_usage
                              ) AS r1
                           , cp_s.subconfentity_code_id AS r2
                      FROM configurations_parameters__subconfigs AS cp_s
                      WHERE cp_s.parameter_id       = g.param_key
                        AND cp_s.confentity_code_id = code_id_of_confentitykey(g.confentity_key)
                LOOP
                      r.default_value        := rec.r1;
                      r.subconfentity_code_id:= rec.r2;
                END LOOP;
            ELSE RAISE EXCEPTION 'An error occurred in function "determine_cparameter" for key: %! Unsupported parameter type: "%".', show_confentityparamkey(g), r.type;
        END CASE;

        RETURN r;
END;
$$;

------------------

CREATE OR REPLACE FUNCTION get_params(par_confentity_key t_confentity_key) RETURNS t_cparameter_uni[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;
        r sch_<<$app_name$>>.t_cparameter_uni[];
BEGIN
        g:= optimize_confentitykey(TRUE, par_confentity_key);

        r:= ARRAY(
                SELECT mk_cparameter_uni(
                          cp_l.parameter_id
                        , cp_l.parameter_type
                        , cp_l.constraints_array
                        , cp_l.allow_null_final_value
                        , cp_l.use_default_instead_of_null
                        , NULL :: integer
                        , cp_l.lnged_paramvalue_dflt_src
                        , mk_cpvalue_l(cp_l.default_value, NULL :: integer)
                        )
                FROM ( configurations_parameters AS cp
                          LEFT OUTER JOIN
                       configurations_parameters__leafs AS _cp_l
                          USING(confentity_code_id, parameter_id, parameter_type)
                     ) AS cp_l
                WHERE cp_l.parameter_type     = 'leaf'
                  AND cp_l.confentity_code_id = code_id_of_confentitykey(g)
                UNION
                SELECT mk_cparameter_uni(
                          cp_s.parameter_id
                        , cp_s.parameter_type
                        , cp_s.constraints_array
                        , cp_s.allow_null_final_value
                        , cp_s.use_default_instead_of_null
                        , cp_s.subconfentity_code_id
                        , NULL :: t_lnged_paramvalue_dflt_src
                        , mk_cpvalue_s(
                            cp_s.overload_default_subconfig
                          , cp_s.overload_default_link
                          , cp_s.overload_default_link_usage
                          )
                        )
                FROM ( configurations_parameters AS cp
                          LEFT OUTER JOIN
                       configurations_parameters__subconfigs AS _cp_s
                          USING(confentity_code_id, parameter_id, parameter_type)
                     ) AS cp_s
                WHERE cp_s.parameter_type     = 'subconfig'
                  AND cp_s.confentity_code_id = code_id_of_confentitykey(g)
        );

        RETURN r;
END;
$$;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_confparam_names(
                  par_confparam_key t_confentityparam_key
                , par_names         name_construction_input[]
                ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g  sch_<<$app_name$>>.t_confentityparam_key;
        g2 sch_<<$app_name$>>.t_cparameter_uni;
        target_confentity_id integer;
        taget_param_name    varchar;
        cnt1 integer;
        cnt2 integer;
        dflt_lng_c_id integer;
BEGIN
        g := optimize_confentityparamkey(par_confparam_key, TRUE);
        g2:= determine_cparameter(g);
        target_confentity_id:= code_id_of_confentitykey(g.confentity_key);
        taget_param_name   := g.param_key;

        FOR cnt1 IN
                SELECT 1 FROM unnest(par_names) AS inp WHERE codekeyl_type(inp.lng) = 'undef' LIMIT 1
        LOOP
                dflt_lng_c_id:= codifier_default_code(FALSE, make_codekeyl_bystr('Languages'));
        END LOOP;

        INSERT INTO configurations_parameters_names (confentity_code_id, parameter_id, lng_of_name, name, entity, description)
                SELECT target_confentity_id
                     , taget_param_name
                     , v.lng_of_name
                     , v.name
                     , v.entity
                     , v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng))
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Entities'), inp.entity)) AS entity
                           , inp.description
                      FROM unnest(par_names) AS inp
                      WHERE codekeyl_type(inp.entity) != 'undef'
                      ) AS v;
        GET DIAGNOSTICS cnt1 = ROW_COUNT;

        -- it's a pity Postgres has poor semantics for inserting DEFAULT... well, it's not a big deal though
        INSERT INTO configurations_parameters_names (confentity_code_id, parameter_id, lng_of_name, name, description)
                SELECT target_confentity_id
                     , taget_param_name
                     , v.lng_of_name
                     , v.name
                     , v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng))
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , inp.description
                      FROM unnest(par_names) AS inp
                      WHERE codekeyl_type(inp.entity) = 'undef'
                      ) AS v;
        GET DIAGNOSTICS cnt2 = ROW_COUNT;

        RETURN (cnt1 + cnt2);
END;
$$;

COMMENT ON FUNCTION add_confparam_names(
                  par_confparam_key t_confentityparam_key
                , par_names         name_construction_input[]
                ) IS
'Returns count of rows inserted.';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_confparam_abstract(
                  par_confentity_key t_confentity_key
                , par_cparameter     t_cparameter_uni
                , par_ifdoesntexist  boolean
                ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;
        rows_count_add   integer;
        rows_count_accum integer;
        target_confentity_id integer;
        taget_param_name    varchar;
BEGIN
        g:= optimize_confentitykey(FALSE, par_confentity_key);
        target_confentity_id:= code_id_of_confentitykey(g);
        taget_param_name   := par_cparameter.param_id;
        rows_count_accum:= 0;

        IF target_confentity_id IS NULL OR taget_param_name IS NULL THEN
                RAISE EXCEPTION 'An error occurred in function "new_confparam" for key: %! Nor target confentity ID neither parameter name are allowed to be NULL!', par_cparameter;
        END IF;

        INSERT INTO configurations_parameters (
                         confentity_code_id
                       , parameter_id
                       , parameter_type
                       , constraints_array
                       , allow_null_final_value
                       , use_default_instead_of_null
                       )
                ( SELECT target_confentity_id
                       , taget_param_name
                       , par_cparameter.type
                       , par_cparameter.constraints_array
                       , par_cparameter.allow_null_final_value
                       , par_cparameter.use_default_instead_of_null
                  WHERE NOT par_ifdoesntexist
                     OR (ROW (target_confentity_id, taget_param_name)
                                   NOT IN ( SELECT cp.confentity_code_id, cp.parameter_id
                                            FROM configurations_parameters AS cp
                                            WHERE cp.confentity_code_id IS NOT DISTINCT FROM target_confentity_id
                                              AND cp.parameter_id       IS NOT DISTINCT FROM taget_param_name
                        )                 )
                );

        GET DIAGNOSTICS rows_count_add = ROW_COUNT;
        rows_count_accum:= rows_count_accum + rows_count_add;

        IF par_ifdoesntexist AND rows_count_add = 0 THEN
                RAISE EXCEPTION 'An error occurred in function "new_confparam" for key: %! Parameter aldeady exists!', par_cparameter;
        END IF;

        RETURN rows_count_accum;
END;
$$ ;

COMMENT ON FUNCTION new_confparam_abstract(
                  par_confentity_key t_confentity_key
                , par_cparameter     t_cparameter_uni
                , par_ifdoesntexist  boolean
                ) IS
'Creates abstract parameter. Returns count of rows inserted.
If "par_ifdoesntexist" is TRUE and parameter already exists, an exception gets rised.
';

--------------------------------------

CREATE OR REPLACE FUNCTION instaniate_confparam_as_leaf(
                  par_confparam_key t_confentityparam_key
                , par_default_value varchar
                ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentityparam_key;
        target_confentity_id integer;
        taget_param_name    varchar;
        rows_count          integer;
BEGIN
        g:= optimize_confentityparamkey(par_confparam_key, FALSE);
        target_confentity_id:= code_id_of_confentitykey(g.confentity_key);
        taget_param_name   := g.param_key;

        UPDATE configurations_parameters AS cp
        SET parameter_type = 'leaf'
        WHERE cp.confentity_code_id IS NOT DISTINCT FROM target_confentity_id
          AND cp.parameter_id       IS NOT DISTINCT FROM taget_param_name;

        GET DIAGNOSTICS rows_count = ROW_COUNT;

        IF rows_count != 1 THEN
                RAISE EXCEPTION 'An error occurred in function "instaniate_confparam_as_leaf" for key: %! Abstract parameter not found!', show_confentityparamkey(par_confparam_key);
        END IF;

        INSERT INTO configurations_parameters__leafs (
                 confentity_code_id
               , parameter_id
               , default_value
               )
        VALUES ( target_confentity_id
               , taget_param_name
               , par_default_value
               );

        RETURN 1;
END;
$$;

COMMENT ON FUNCTION instaniate_confparam_as_leaf(par_confparam_key t_confentityparam_key, par_dflt_val varchar) IS
'Returns count of rows inserted. Inserts row into "configurations_parameters__leafs" table.
The function won''t overwrite existing instaniation.
When the function is called, abstract parameter must preexist, orelse an exception will be rised. The type of abstract parameter will be updated anyway.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION instaniate_confparam_as_subconfig(
          par_confparam_key         t_confentityparam_key
        , par_subconfentity_code_id integer
        , default_value             t_cpvalue_uni
        ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentityparam_key;
        target_confentity_id integer;
        taget_param_name    varchar;
        rows_count          integer;
        dflt_lnk_usage sch_<<$app_name$>>.t_subconfig_value_linking_read_rule;
BEGIN
        g:= optimize_confentityparamkey(par_confparam_key, FALSE);
        target_confentity_id:= code_id_of_confentitykey(g.confentity_key);
        taget_param_name   := g.param_key;

        UPDATE configurations_parameters AS cp
        SET parameter_type = 'subconfig'
        WHERE cp.confentity_code_id IS NOT DISTINCT FROM target_confentity_id
          AND cp.parameter_id       IS NOT DISTINCT FROM taget_param_name;

        GET DIAGNOSTICS rows_count = ROW_COUNT;

        IF rows_count != 1 THEN
                RAISE EXCEPTION 'An error occurred in function "instaniate_confparam_as_subconfig" for key: %! Abstract parameter not found!', show_confentityparamkey(par_confparam_key);
        END IF;

        dflt_lnk_usage:= default_value.subcfg_ref_usage;
        IF isnull_cpvalue(default_value, TRUE) THEN
                dflt_lnk_usage:= 'no_lnk';
        END IF;

        INSERT INTO configurations_parameters__subconfigs (
                 confentity_code_id
               , parameter_id
               , subconfentity_code_id
               , overload_default_subconfig
               , overload_default_link
               , overload_default_link_usage
               )
        VALUES ( target_confentity_id
               , taget_param_name
               , par_subconfentity_code_id
               , default_value.value
               , default_value.subcfg_ref_param_id
               , dflt_lnk_usage
               );

        RETURN 1;
END;
$$;

COMMENT ON FUNCTION instaniate_confparam_as_subconfig(par_confparam_key t_confentityparam_key, par_subconfentity_code_id integer, default_value t_cpvalue_uni) IS
'Returns count of rows inserted. Inserts row into "configurations_parameters__subconfigs" table.
The function won''t overwrite existing instaniation.
When the function is called, abstract parameter must preexist, orelse an exception will be rised. The type of abstract parameter will be updated anyway.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION confparam_instaniated_isit(par_confparam_key t_confentityparam_key) RETURNS t_confparam_type
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g  sch_<<$app_name$>>.t_confentityparam_key;
        g1 sch_<<$app_name$>>.t_cparameter_uni;
        r  sch_<<$app_name$>>.t_confparam_type;
        target_confentity_id integer;
        taget_param_name    varchar;
        rows_count          integer;
BEGIN
        g := optimize_confentityparamkey(par_confparam_key, FALSE);
        g1:= determine_cparameter(g);
        target_confentity_id:= code_id_of_confentitykey(g.confentity_key);
        taget_param_name   := g.param_key;

        IF g1.type IS NULL THEN
                RETURN NULL;
        END IF;

        CASE g1.type
            WHEN 'leaf' THEN
                SELECT cpl.parameter_type
                INTO r
                FROM configurations_parameters__leafs AS cpl
                WHERE cpl.confentity_code_id IS NOT DISTINCT FROM target_confentity_id
                  AND cpl.parameter_id       IS NOT DISTINCT FROM taget_param_name;

                GET DIAGNOSTICS rows_count = ROW_COUNT;

                IF rows_count != 1 THEN
                        r:= NULL; -- perhaps, this is not needed...
                END IF;
            WHEN 'subconfig' THEN
                SELECT cps.parameter_type
                INTO r
                FROM configurations_parameters__subconfigs AS cps
                WHERE cps.confentity_code_id IS NOT DISTINCT FROM target_confentity_id
                  AND cps.parameter_id       IS NOT DISTINCT FROM taget_param_name;

                GET DIAGNOSTICS rows_count = ROW_COUNT;

                IF rows_count != 1 THEN
                        r:= NULL; -- perhaps, this is not needed...
                END IF;
            ELSE RAISE EXCEPTION 'An error occurred in function "confparam_instaniated_isit" for key: %! Unsupported parameter type: "%"!', show_confentityparamkey(par_confparam_key), g1.type;
        END CASE;

        RETURN r;
END;
$$;

COMMENT ON FUNCTION confparam_instaniated_isit(par_confparam_key t_confentityparam_key) IS
'Returns NULL, if parameter abstraction doesn''t exist or if parameter isn''t instaniated.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_confparams(
                  par_confentity_key  t_confentity_key
                , par_cparameters_set t_cparameter_uni[]
                , par_ifdoesntexist   boolean
                ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;
        rows_count_add   integer;
        rows_count_accum integer;
        l integer;
        i integer;
BEGIN
        g:= optimize_confentitykey(FALSE, par_confentity_key);
        rows_count_accum:= 0;

        l:= array_length(par_cparameters_set, 1);
        i:= 0;
        WHILE i < l LOOP
                i:= i + 1;
                SELECT new_confparam_abstract(
                          g
                        , par_cparameters_set[i]
                        , par_ifdoesntexist
                        )
                INTO rows_count_add;
                rows_count_accum:= rows_count_accum + rows_count_add;

                CASE (par_cparameters_set[i]).type
                    WHEN 'subconfig' THEN
                        SELECT instaniate_confparam_as_subconfig(
                                        make_confentityparamkey(g, (par_cparameters_set[i]).param_id, FALSE)
                                      , (par_cparameters_set[i]).subconfentity_code_id
                                      , (par_cparameters_set[i]).default_value
                                      )
                        INTO rows_count_add;
                        rows_count_accum:= rows_count_accum + rows_count_add;
                    WHEN 'leaf' THEN
                        SELECT instaniate_confparam_as_leaf(
                                        make_confentityparamkey(g, (par_cparameters_set[i]).param_id, FALSE)
                                      , ((par_cparameters_set[i]).default_value).value
                                      )
                        INTO rows_count_add;
                        rows_count_accum:= rows_count_accum + rows_count_add;
                    ELSE RAISE EXCEPTION 'An error occurred in function "add_confparams"! Unsupported parameter type "%" for parameter under index %!', (par_cparameters_set[i]).type, i;
                END CASE;
        END LOOP;

        RETURN rows_count_accum;
END;
$$;

COMMENT ON FUNCTION add_confparams(
                          par_confentity_key  t_confentity_key
                        , par_cparameters_set t_cparameter_uni[]
                        , par_ifdoesntexist   boolean
                        ) IS
'Returns cont of inserted rows.';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_confentity_w_params(
          par_ce_name         varchar
        , par_cparameters_set t_cparameter_uni[]
        ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;
        target_confentity_id integer;
BEGIN
        SELECT new_confentity(
                  par_ce_name
                , FALSE
                )
        INTO target_confentity_id;

        g:= make_confentitykey_byid(target_confentity_id);

        PERFORM add_confparams(g, par_cparameters_set, FALSE);

        RETURN target_confentity_id;
END;
$$;

COMMENT ON FUNCTION new_confentity_w_params(
          par_ce_name         varchar
        , par_cparameters_set t_cparameter_uni[]
        ) IS
'Returns new confentity ID.';

--------------------------------------------------------------------------

CREATE TYPE t_config_param__short AS (config_id varchar, param_id varchar);

CREATE OR REPLACE FUNCTION deinstaniate_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g  sch_<<$app_name$>>.t_confentityparam_key;
        g1 sch_<<$app_name$>>.t_cparameter_uni;
        rows_count_accum integer;
        rows_count_add   integer;
        target_ce_id     integer;
        l                integer;
        lnk_param_ids    varchar[];
        lnk_param_cfgs   sch_<<$app_name$>>.t_config_param__short[];
        act              varchar;
BEGIN
        g:=  optimize_confentityparamkey(par_confparam_key, FALSE);
        g1:= determine_cparameter(g);
        target_ce_id:= code_id_of_confentitykey(g.confentity_key);
        rows_count_accum:= 0;
        rows_count_add  := 0;

        CASE g1.type
             WHEN 'leaf' THEN
                IF NOT par_dont_modify_anything THEN
                        DELETE FROM configurations_parameters__leafs AS cp_l
                        WHERE cp_l.confentity_code_id = target_ce_id
                          AND cp_l.parameter_id = g.param_key;

                        GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                        rows_count_accum:= rows_count_add;
                END IF;
             WHEN 'subconfig' THEN
                IF par_cascade_setnull_subcfgrefernces AND par_warn_with_list_of_subcfgrefernces AND NOT par_dont_modify_anything THEN
                    act:= E'\nSET NULL action performed to them.';

                    lnk_param_ids:= ARRAY(
                            SELECT cp_s.parameter_id
                            FROM configurations_parameters__subconfigs AS cp_s
                            WHERE cp_s.confentity_code_id = target_ce_id
                              AND cp_s.overload_default_link = g.param_key
                    );

                    UPDATE configurations_parameters__subconfigs AS cp_s
                    SET overload_default_link = NULL
                    WHERE overload_default_link IS NOT NULL
                      AND cp_s.confentity_code_id = target_ce_id
                      AND cp_s.overload_default_link = g.param_key;

                    GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                    rows_count_accum:= rows_count_accum + rows_count_add;

                    lnk_param_cfgs:= ARRAY(
                            SELECT ROW(cpv_s.configuration_id, cpv_s.parameter_id) :: t_config_param__short
                            FROM configurations_parameters_values__subconfigs AS cpv_s
                            WHERE cpv_s.confentity_code_id = target_ce_id
                              AND cpv_s.subconfiguration_link = g.param_key
                    );

                    UPDATE configurations_parameters_values__subconfigs AS cpv_s
                    SET subconfiguration_link = NULL
                    WHERE subconfiguration_link IS NOT NULL
                      AND cpv_s.confentity_code_id = target_ce_id
                      AND cpv_s.subconfiguration_link = g.param_key;

                    GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                    rows_count_accum:= rows_count_accum + rows_count_add;
                ELSIF par_cascade_setnull_subcfgrefernces  AND NOT par_dont_modify_anything THEN
                    UPDATE configurations_parameters__subconfigs AS cp_s
                    SET overload_default_link = NULL
                    WHERE overload_default_link IS NOT NULL
                      AND cp_s.confentity_code_id = target_ce_id
                      AND cp_s.overload_default_link = g.param_key;

                    GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                    rows_count_accum:= rows_count_accum + rows_count_add;

                    UPDATE configurations_parameters_values__subconfigs AS cpv_s
                    SET subconfiguration_link = NULL
                    WHERE subconfiguration_link IS NOT NULL
                      AND cpv_s.confentity_code_id = target_ce_id
                      AND cpv_s.subconfiguration_link = g.param_key;

                    GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                    rows_count_accum:= rows_count_accum + rows_count_add;
                ELSE
                    act:= '';
                    lnk_param_ids:= ARRAY(
                            SELECT cp_s.parameter_id
                            FROM configurations_parameters__subconfigs AS cp_s
                            WHERE cp_s.confentity_code_id = target_ce_id
                              AND cp_s.overload_default_link = g.param_key
                    );
                    lnk_param_cfgs:= ARRAY(
                            SELECT ROW(cpv_s.configuration_id, cpv_s.parameter_id) :: t_config_param__short
                            FROM configurations_parameters_values__subconfigs AS cpv_s
                            WHERE cpv_s.confentity_code_id = target_ce_id
                              AND cpv_s.subconfiguration_link = g.param_key
                    );
                END IF;

                IF par_warn_with_list_of_subcfgrefernces THEN
                        l:= COALESCE(array_length(lnk_param_ids, 1), 0) + COALESCE(array_length(lnk_param_cfgs, 1), 0);
                        IF l > 0 THEN
                                RAISE WARNING E'Confentity parameter-subconfig (confentity: %; param: "%") DELETION: \nfollowing defaults of parameters-subconfigs are referencing target parameter: %\nfollowing values of parameters-subconfigs are referencing target parameter: % %', target_ce_id, g.param_key, lnk_param_ids, lnk_param_cfgs, act;
                                -- if no warning is enabled, then let user see output from exception on DELETE
                                IF NOT par_cascade_setnull_subcfgrefernces THEN RETURN 0; END IF;
                        END IF;
                END IF;

                IF NOT par_dont_modify_anything THEN
                        DELETE FROM configurations_parameters__subconfigs AS cp_s
                        WHERE cp_s.confentity_code_id = target_ce_id
                          AND cp_s.parameter_id = g.param_key;

                        GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                        rows_count_accum:= rows_count_accum + rows_count_add;
                END IF;

             ELSE RAISE EXCEPTION 'An error occurred in function "deinstaniate_confparam"! Unsupported parameter type: "%"!', g1.type;
        END CASE;

        RETURN rows_count_accum;
END;
$$;

COMMENT ON FUNCTION deinstaniate_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                ) IS
'Returns count of rows deleted (from all tables).
All values are deleted by cascade, silently.
If parameter "par_warn_with_list_of_subcfgrefernces" enabled, then list of those parameters/paramvalues under same confentity is outputed, that contain references on target parameter. If no dependents are there, warning is not displayed.
If such parameters/paramvalues persist and "par_cascade_setnull_subcfgrefernces" is FALSE, then deinstaniation transaction won''t be successful.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentityparam_key;
        rows_count_accum integer;
        rows_count_add   integer;
        target_ce_id     integer;
        lnk_param_ids    varchar[];
        lnk_param_cfgs   sch_<<$app_name$>>.t_config_param__short[];
        act              varchar;
BEGIN
        g:= optimize_confentityparamkey(par_confparam_key, FALSE);

        rows_count_accum:= deinstaniate_confparam(
                  g
                , par_cascade_setnull_subcfgrefernces
                , par_warn_with_list_of_subcfgrefernces
                , par_dont_modify_anything
                );

        IF NOT par_dont_modify_anything THEN
                DELETE FROM configuration_parameters AS cp
                WHERE cp_s.confentity_code_id = code_id_of_confentitykey(g.confentity_key)
                  AND cp_s.parameter_id = g.param_key;

                GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                rows_count_accum:= rows_count_accum + rows_count_add;
        END IF;

        RETURN rows_count_accum;
END;
$$;

COMMENT ON FUNCTION delete_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                ) IS
'Returns count of rows deleted (from all tables).
Relies on "deinstaniate_confparam" function.
';

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- GRANTS

-- Reference functions:
GRANT EXECUTE ON FUNCTION mk_cpvalue_null()TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION mk_cpvalue_l(value varchar, lng integer)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION mk_cpvalue_s(value varchar, subcfg_ref_param_id varchar, subcfg_ref_usage t_subconfig_value_linking_read_rule)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION isconsistent_cpvalue(par_value t_cpvalue_uni)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION isdefined_cpvalue(par_value t_cpvalue_uni)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION isnull_cpvalue(par_value t_cpvalue_uni, par_total boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

GRANT EXECUTE ON FUNCTION mk_cparameter_uni(
          par_param_id                    varchar
        , par_type                        t_confparam_type
        , par_constraints_array           t_confparam_constraint[]
        , par_allow_null_final_value      boolean
        , par_use_default_instead_of_null t_confparam_default_usage
        , par_subconfentity_code_id       integer
        , par_par_lnged_paramvalue_dflt_src t_lnged_paramvalue_dflt_src
        , par_default_value               t_cpvalue_uni
        ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


GRANT EXECUTE ON FUNCTION make_confentityparamkey(par_confentity_key t_confentity_key, key varchar, key_is_lnged boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_confentityparamkey_null()TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_confentityparamkey_bystr(par_confentity_id integer, par_param varchar)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_confentityparamkey_bystr2(par_confentity_str varchar, par_param varchar)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION confentityparam_is_null(par_confparam_key t_confentityparam_key, par_total boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_confentityparamkey(par_confparam_key t_confentityparam_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_confentityparamkey_isit(par_confparam_key t_confentityparam_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


-- Lookup functions:
GRANT EXECUTE ON FUNCTION optimize_confentityparamkey(par_confparam_key t_confentityparam_key, par_verify boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION determine_cparameter(par_confparam_key t_confentityparam_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_params(par_confentity_key t_confentity_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


-- Administration functions:
GRANT EXECUTE ON FUNCTION add_confparam_names(
                  par_confparam_key t_confentityparam_key
                , par_names         name_construction_input[]
                ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_confparam_abstract(
                  par_confentity_key t_confentity_key
                , par_cparameter     t_cparameter_uni
                , par_ifdoesntexist  boolean
                ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION instaniate_confparam_as_leaf(
                  par_confparam_key t_confentityparam_key
                , par_default_value varchar
                ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION instaniate_confparam_as_subconfig(
          par_confparam_key    t_confentityparam_key
        , par_subconfentity_code_id integer
        , default_value        t_cpvalue_uni
        ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION confparam_instaniated_isit(par_confparam_key t_confentityparam_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_confparams(
                  par_confentity_key  t_confentity_key
                , par_cparameters_set t_cparameter_uni[]
                , par_ifdoesntexist   boolean
                ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_confentity_w_params(
          par_ce_name         varchar
        , par_cparameters_set t_cparameter_uni[]
        ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION deinstaniate_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                )
 TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION delete_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                )
 TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> confentityparam.init.sql [END]