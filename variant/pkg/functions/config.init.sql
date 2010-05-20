-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> config.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_config_key AS (confentity_key t_confentity_key, config_id varchar, cfgid_is_lnged boolean);

COMMENT ON TYPE t_config_key IS
'Extension of "t_confentity_key" - sufficient to address (also) any config.
The language of "config_key" field is assumed to be the same, as one specified for "confentity_key".
Field "cfgid_is_lnged" if TRUE, then there is assumed to be a language key somewhere outside of "t_config_key" data construct, which determines the language, in which "config_id" is given.
Many functions will raise exception, if value of "cfgid_is_lnged" is NULL.

';

--------------

CREATE OR REPLACE FUNCTION make_configkey(par_confentity_key t_confentity_key, par_config varchar, par_cfgid_is_lnged boolean) RETURNS t_config_key AS $$
        SELECT ROW($1, $2, $3) :: sch_<<$app_name$>>.t_config_key;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_configkey_null() RETURNS t_config_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_confentitykey_null(), NULL :: varchar, NULL :: boolean) :: sch_<<$app_name$>>.t_config_key;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_configkey_bystr(par_confentity_id integer, par_config varchar) RETURNS t_config_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_confentitykey_byid($1), $2, FALSE) :: sch_<<$app_name$>>.t_config_key;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_configkey_bystr2(par_confentity_str varchar, par_config varchar) RETURNS t_config_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_confentitykey_bystr($1), $2, FALSE) :: sch_<<$app_name$>>.t_config_key;
$$ LANGUAGE SQL IMMUTABLE;

--------------

CREATE OR REPLACE FUNCTION config_is_null(par_config_key t_config_key, par_total boolean) RETURNS boolean AS $$
        SELECT CASE WHEN $1 IS NULL THEN TRUE
                    ELSE (CASE WHEN $2 THEN
                                (sch_<<$app_name$>>.confentity_is_null(($1).confentity_key) AND (($1).config_id IS NULL) AND (($1).cfgid_is_lnged IS NULL))
                               ELSE
                                (sch_<<$app_name$>>.confentity_is_null(($1).confentity_key) OR  (($1).config_id IS NULL) OR  (($1).cfgid_is_lnged IS NULL))
                          END
                         )
               END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION config_is_null(par_config_key t_config_key) RETURNS boolean AS $$
        SELECT sch_<<$app_name$>>.config_is_null($1, FALSE);
$$ LANGUAGE SQL IMMUTABLE;

--------------

CREATE OR REPLACE FUNCTION show_configkey(par_configkey t_config_key) RETURNS varchar AS $$
        SELECT '{t_config_key | '
            || ( CASE WHEN config_is_null($1, TRUE) THEN 'NULL'
                      ELSE (  CASE WHEN confentity_is_null(($1).confentity_key) THEN ''
                                   ELSE 'confentity_key:' || show_confentitykey(($1).confentity_key) || ';'
                              END
                           )
                        || (  CASE WHEN ($1).config_id IS NULL THEN ''
                                   ELSE 'config_id:"' || ($1).config_id || '";'
                              END
                           )
                        || (  CASE WHEN ($1).cfgid_is_lnged IS NULL THEN ''
                                   ELSE 'cfgid_is_lnged:' || ($1).cfgid_is_lnged
                              END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL IMMUTABLE;

------------------------

CREATE OR REPLACE FUNCTION show_configkeys_list(par_configkeys_list t_config_key[]) RETURNS varchar
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE r varchar; i integer; l integer;
BEGIN
        l:= array_length(par_configkeys_list, 1); i:= 0;
        r:= '{';
        WHILE i < l LOOP
                IF i != 0 THEN r:= r || ';'; END IF;
                i:= i + 1;
                r:= r || '(' || sch_<<$app_name$>>.code_id_of_confentitykey((par_configkeys_list[i]).confentity_key) || ', "' || (par_configkeys_list[i]).config_id || '")';
        END LOOP;
        r:= r || '}';
        RETURN r;
END;
$$;

COMMENT ON FUNCTION show_configkeys_list(par_configkeys_list t_config_key[]) IS '
It is assumed, that target list contains all *optimized* keys - ones containing determined "confentity_code_id" and delanguaged "config_id" !!
If list contains "NULL :: t_config_key" (or "make_configkey_null()"), the whole result will be NULL.
';

--------------

CREATE OR REPLACE FUNCTION optimized_configkey_isit(par_configkey t_config_key) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE r boolean;
BEGIN
        IF par_configkey.cfgid_is_lnged IS NULL THEN
                RAISE EXCEPTION 'An error occurred in the "optimized_configkey_isit" function for parameter value: %! Argument is not allowed to have NULL in ".cfgid_is_lnged"!', sch_<<$app_name$>>.show_configkey(par_configkey);
        END IF;
        SELECT CASE WHEN sch_<<$app_name$>>.config_is_null($1, TRUE) THEN FALSE
                    ELSE sch_<<$app_name$>>.optimized_confentitykey_isit(par_configkey.confentity_key) AND par_configkey.config_id IS NOT NULL
               END
        INTO r;
        RETURN r;
END;
$$;

--------------

CREATE OR REPLACE FUNCTION optimize_configkey(par_configkey t_config_key, par_verify boolean) RETURNS t_config_key
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;
        n varchar;
        r sch_<<$app_name$>>.t_config_key;
        rows_count integer;
BEGIN
        IF sch_<<$app_name$>>.optimized_configkey_isit(par_configkey) AND NOT par_verify THEN
                RETURN par_configkey;
        END IF;

        g:= optimize_confentitykey(FALSE, par_configkey.confentity_key);

        IF codekey_type((g.confentity_codekeyl).key_lng) = 'c_id' AND par_configkey.cfgid_is_lnged THEN
                SELECT cfg_n.configuration_id
                INTO n
                FROM configurations_names AS cfg_n
                WHERE name = par_configkey.config_id
                  AND confentity_code_id = ((g.confentity_codekeyl).code_key).code_id
                  AND lng_of_name = ((g.confentity_codekeyl).key_lng).code_id;

                GET DIAGNOSTICS rows_count = ROW_COUNT;

                IF (rows_count != 1) THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_configkey" for key: %! Name not found.', show_configkey(par_configkey);
                END IF;
        ELSIF par_configkey.cfgid_is_lnged THEN
                RAISE EXCEPTION 'An error occurred in function "optimize_configkey" for key: %! Config ID is languaged, but language is not specified!', show_configkey(par_configkey);
        ELSE
                IF par_verify THEN
                        SELECT 1
                        INTO rows_count
                        FROM configurations AS c
                        WHERE configuration_id = par_configkey.config_id
                          AND confentity_code_id = ((g.confentity_codekeyl).code_key).code_id;

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF (rows_count != 1) THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_configkey" for key: %! Verification failed - target not found.', show_configkey(par_configkey);
                        END IF;
                END IF;
                n:= par_configkey.config_id;
        END IF;
        r:= make_configkey(g, n, FALSE);

        RETURN r;
END;
$$;

CREATE OR REPLACE FUNCTION optimize_configkey(par_configkey t_config_key) RETURNS t_config_key AS $$
        SELECT sch_<<$app_name$>>.optimize_configkey($1, FALSE);
$$ LANGUAGE SQL;

COMMENT ON FUNCTION optimize_configkey(par_configkey t_config_key) IS
'= optimize_configkey(par_configkey, FALSE)';

-------------

CREATE OR REPLACE FUNCTION is_confentity_default(par_configkey t_config_key) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_config_key;
        r boolean;
BEGIN
        g:= sch_<<$app_name$>>.optimize_configkey(par_configkey, FALSE);
        r:= (   sch_<<$app_name$>>.get_confentity_default(g.confentity_key) IS NOT DISTINCT FROM g.config_id
            AND g.config_id IS NOT NULL
            );
        RETURN r;
END;
$$;

COMMENT ON FUNCTION is_confentity_default(par_configkey t_config_key) IS
'It is advised to do the "optimize_configkey(par_configkey)" beforehand, if par_configkey is to be reused.
Raises an exception, if confentity is not optimized and isn''t found, but returns NULL, if config is not found.
';

-------------

CREATE OR REPLACE FUNCTION read_completeness(par_configkey t_config_key) RETURNS t_config_completeness_check_result
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_config_key;
        r sch_<<$app_name$>>.t_config_completeness_check_result:= NULL;
BEGIN
        g:= optimize_configkey(par_configkey, FALSE);

        SELECT complete_isit
        INTO r
        FROM configurations AS c
        WHERE c.confentity_code_id = code_id_of_confentitykey(g.confentity_key)
          AND c.configuration_id   = g.config_id;

        IF r IS NULL THEN r:= 'nf_X'; END IF;

        RETURN r;
END;
$$;

COMMENT ON FUNCTION is_confentity_default(par_configkey t_config_key) IS
'It is advised to do the "optimize_configkey(par_configkey)" beforehand, if par_configkey is to be reused.
Raises an exception, if confentity is not optimized and isn''t found, but returns ''nf_X'', if config is not found.
';

-------------

CREATE OR REPLACE FUNCTION read_role__completeness_as_regulator(par_configkey t_config_key) RETURNS t_completeness_as_regulator
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_config_key;
        r sch_<<$app_name$>>.t_completeness_as_regulator:= NULL;
BEGIN
        g:= optimize_configkey(par_configkey, FALSE);

        SELECT completeness_as_regulator
        INTO r
        FROM configurations AS c
        WHERE c.confentity_code_id = code_id_of_confentitykey(g.confentity_key)
          AND c.configuration_id   = g.config_id;

        RETURN r;
END;
$$;

COMMENT ON FUNCTION read_role__completeness_as_regulator(par_configkey t_config_key) IS
'It is advised to do the "optimize_configkey(par_configkey)" beforehand, if par_configkey is to be reused.
Reads "completeness_as_regulator" field value.
Raises an exception, if confentity is not optimized and isn''t found, but returns NULL, if config is not found.
';

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        target_confentity_id integer;
        rows_count integer;
        c_exists boolean;
        cfg sch_<<$app_name$>>.t_config_key;
BEGIN
        target_confentity_id:= code_id_of_confentitykey(optimize_confentitykey(FALSE, par_confentity_key));

        c_exists:= FALSE;
        IF par_ifdoesnt_exist = TRUE THEN
                SELECT TRUE
                INTO c_exists
                FROM configurations
                WHERE confentity_code_id = target_confentity_id
                  AND configuration_id   = par_config_id;

                IF c_exists IS NULL THEN c_exists:= FALSE; END IF;
        END IF;

        IF NOT c_exists THEN
                INSERT INTO configurations(confentity_code_id, configuration_id)
                VALUES (target_confentity_id, par_config_id);

                GET DIAGNOSTICS rows_count = ROW_COUNT;
        ELSE    rows_count:= 0;
        END IF;

        RETURN rows_count;
END;
$$;

COMMENT ON FUNCTION new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              ) IS
'Returns count of rows inserted. The "par_config_id" parameter is not languaged.
If "par_ifdoesnt_exist" is FALSE and config already exists, then exception is raised.';

--------------------------------------

CREATE OR REPLACE FUNCTION add_config_names(
                  par_config_key t_config_key
                , par_names      name_construction_input[]
                ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_config_key;
        target_confentity_id integer;
        taget_config_id varchar;
        cnt1 integer;
        cnt2 integer;
        dflt_lng_c_id integer;
BEGIN
        g:= optimize_configkey(par_config_key, FALSE);
        target_confentity_id:= code_id_of_confentitykey(g.confentity_key);
        taget_config_id:= g.config_id;

        FOR cnt1 IN
                SELECT 1 FROM unnest(par_names) AS inp WHERE codekeyl_type(inp.lng) = 'undef' LIMIT 1
        LOOP
                dflt_lng_c_id:= codifier_default_code(FALSE, make_codekeyl_bystr('Languages'));
        END LOOP;

        INSERT INTO configurations_names (confentity_code_id, configuration_id, lng_of_name, name, entity, description)
                SELECT target_confentity_id
                     , taget_config_id
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
        INSERT INTO configurations_names (confentity_code_id, configuration_id, lng_of_name, name, description)
                SELECT target_confentity_id
                     , taget_config_id
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

COMMENT ON FUNCTION add_config_names(
                  par_config_key t_config_key
                , par_names      name_construction_input[]
                ) IS
'Returns count of rows inserted.';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION clone_config(par_config_key t_config_key, par_clone_config_id varchar) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        target_confentity_id integer;
        rows_count integer;
        rows_count_add integer;
        compl sch_<<$app_name$>>.t_config_completeness_check_result;
        occa  sch_<<$app_name$>>.t_completeness_as_regulator;
        g     sch_<<$app_name$>>.t_config_key;
BEGIN
        g:= optimize_configkey(par_config_key, FALSE);
        target_confentity_id:= code_id_of_confentitykey(g.confentity_key);

        INSERT INTO configurations(confentity_code_id, configuration_id, complete_isit, completeness_as_regulator)
        VALUES (target_confentity_id, par_clone_config_id, 'li_chk_X', 'SET INCOMPLETE');
        rows_count:= 1;

        SELECT c.complete_isit, c.completeness_as_regulator
        INTO compl, occa
        FROM configurations AS c
        WHERE c.confentity_code_id = target_confentity_id
          AND c.configuration_id   = g.config_id;

        INSERT INTO configurations_parameters_values__subconfigs
               SELECT *
               FROM configurations_parameters_values__subconfigs AS cpv_s
               WHERE cpv_s.confentity_code_id = target_confentity_id
                 AND cpv_s.configuration_id   = g.config_id;

        GET DIAGNOSTICS rows_count_add = ROW_COUNT;
        rows_count:= rows_count_add + 1;

        INSERT INTO configurations_parameters_values__leafs
               SELECT *
               FROM configurations_parameters_values__leafs AS cpv_l
               WHERE cpv_l.confentity_code_id = target_confentity_id
                 AND cpv_l.configuration_id   = g.config_id;

        GET DIAGNOSTICS rows_count_add = ROW_COUNT;
        rows_count:= rows_count_add + 1;

        UPDATE configurations AS c
        SET complete_isit = compl
          , completeness_as_regulator = occa
        WHERE c.confentity_code_id = target_confentity_id
          AND c.configuration_id   = par_clone_config_id;

        RETURN rows_count;
END;
$$;

COMMENT ON FUNCTION clone_config(par_config_key t_config_key, par_clone_config_id varchar) IS
'Returns count of rows inserted (including rows in parameter-values tables).
Creates a copy of config identified by "par_config_key" parameter. Copy includes all the parameters.
The "par_clone_config_id" parameter is not languaged.
';


--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_confentity_default(par_config_key t_config_key, par_overwrite boolean) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE g sch_<<$app_name$>>.t_config_key;
        rows_count integer;
BEGIN
        g:= sch_<<$app_name$>>.optimize_configkey(par_config_key, FALSE);

        UPDATE sch_<<$app_name$>>.configurable_entities AS ce
        SET default_configuration_id = g.config_id
        WHERE ce.confentity_code_id = code_id_of_confentitykey(g.confentity_key)
          AND (ce.default_configuration_id IS NULL OR par_overwrite);

        GET DIAGNOSTICS rows_count = ROW_COUNT;
        RETURN rows_count;
END;
$$;

COMMENT ON FUNCTION set_confentity_default(par_config_key t_config_key, par_overwrite boolean) IS
'Returns count of rows modified.
';

--------------------------------------------------------------------------

CREATE TYPE t_confentity_param__short AS (ce_id integer, param_id varchar);
CREATE TYPE t_config_param_subcfg__short AS (ce_id integer, config_id varchar, param_id varchar);

CREATE OR REPLACE FUNCTION delete_config(
                par_config_key                         t_config_key
              , par_cascade_setnull_ce_dflt            boolean
              , par_cascade_setnull_param_dflt         boolean
              , par_cascade_setnull_param_val          boolean
              , par_warn_with_list_of_ce_dflt_users    boolean
              , par_warn_with_list_of_param_dflt_users boolean
              , par_warn_with_list_of_param_val_users  boolean
              , par_dont_modify_anything               boolean
              ) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_config_key;

        rows_count_accum integer;
        rows_count_add   integer;

        target_ce_id     integer;
        target_cfg_id    varchar;

        ce_dflt_act      varchar;
        param_dflt_act   varchar;
        param_val_act    varchar;
        act_sum          varchar;

        ce_dflt_pers     boolean;
        param_dflt_lst   sch_<<$app_name$>>.t_confentity_param__short[];
        param_val_lst    sch_<<$app_name$>>.t_config_param_subcfg__short[];
BEGIN
        g:= optimize_configkey(par_config_key, FALSE);
        target_ce_id := code_id_of_confentitykey(g.confentity_key);
        target_cfg_id:= g.config_id;

        rows_count_accum:= 0;
        rows_count_add:= 0;

        -- deal with target CONFENTITY DEFAULT
        IF par_cascade_setnull_ce_dflt AND NOT par_dont_modify_anything THEN
                UPDATE configurable_entities AS ce
                SET default_configuration_id = NULL
                WHERE ce.confentity_code_id = target_ce_id AND ce.default_configuration_id = target_cfg_id;

                GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                rows_count_accum:= rows_count_accum + rows_count_add;
                ce_dflt_pers:= rows_count_add > 0;
        ELSE
                SELECT ce.default_configuration_id IS NOT DISTINCT FROM target_cfg_id
                INTO ce_dflt_pers
                FROM configurable_entities AS ce
                WHERE ce.confentity_code_id = target_ce_id;

                GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                IF rows_count_add < 1 THEN RAISE EXCEPTION '"This should never happen" error #1.'; END IF;
        END IF;

        IF par_cascade_setnull_ce_dflt AND par_warn_with_list_of_ce_dflt_users AND NOT par_dont_modify_anything THEN
                ce_dflt_act:= ' (confentity default set to NULL)';
        ELSE
                ce_dflt_act:= '';
        END IF;

        IF par_warn_with_list_of_ce_dflt_users THEN
                ce_dflt_act:= 'Target config is used as a confentity default config' || ce_dflt_act || '.';
        END IF;

        -- deal with SUPERCONFIG PARAMETER DEFAULT that use target as subconfig
        param_dflt_lst:= ARRAY(
                SELECT ROW(cp_s.confentity_code_id, cp_s.parameter_id) :: t_confentity_param__short
                FROM configurations_parameters__subconfigs AS cp_s
                WHERE cp_s.subconfentity_code_id = target_ce_id AND cp_s.overload_default_subconfig = target_cfg_id
        );
        IF par_cascade_setnull_param_dflt AND NOT par_dont_modify_anything THEN
                UPDATE configurations_parameters__subconfigs AS cp_s
                SET overload_default_subconfig = NULL
                WHERE cp_s.subconfentity_code_id = target_ce_id AND cp_s.overload_default_subconfig = target_cfg_id;

                GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                rows_count_accum:= rows_count_accum + rows_count_add;
        END IF;

        IF par_cascade_setnull_param_dflt AND par_warn_with_list_of_param_dflt_users AND NOT par_dont_modify_anything THEN
                param_dflt_act:= ' (superconfig parameter default set to NULL)';
        ELSE
                param_dflt_act:= '';
        END IF;

        IF par_warn_with_list_of_param_dflt_users THEN
                param_dflt_act:= 'Superconfig parameter default uses target config' || param_dflt_act || ': ' || (param_dflt_lst :: varchar) || '.';
        END IF;

        -- deal with SUPERCONFIG PARAMETER VALUE that use target as subconfig
        param_val_lst:= ARRAY(
                SELECT ROW(cpv_s.confentity_code_id, cpv_s.configuration_id, cpv_s.parameter_id) :: t_config_param_subcfg__short
                FROM configurations_parameters_values__subconfigs AS cpv_s
                WHERE cpv_s.subconfentity_code_id = target_ce_id AND cpv_s.subconfiguration_id = target_cfg_id
        );
        IF par_cascade_setnull_param_val AND NOT par_dont_modify_anything THEN
                UPDATE configurations_parameters_values__subconfigs AS cpv_s
                SET subconfiguration_id = NULL
                WHERE cpv_s.subconfentity_code_id = target_ce_id AND cpv_s.subconfiguration_id = target_cfg_id;

                GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                rows_count_accum:= rows_count_accum + rows_count_add;
        END IF;

        IF par_cascade_setnull_param_val AND par_warn_with_list_of_param_val_users AND NOT par_dont_modify_anything THEN
                param_val_act:= ' (superconfig parameter value   set to NULL)';
        ELSE
                param_val_act:= '';
        END IF;

        IF par_warn_with_list_of_param_val_users THEN
                param_val_act:= 'Superconfig parameter value   uses target config' || param_val_act || ': ' || (param_val_lst :: varchar) || '.';
        END IF;

        ---------------------

        act_sum:= '';

        IF par_warn_with_list_of_param_val_users  THEN act_sum:= act_sum || E'\n ** ' || param_val_act;  END IF;
        IF par_warn_with_list_of_param_dflt_users THEN act_sum:= act_sum || E'\n ** ' || param_dflt_act; END IF;
        IF par_warn_with_list_of_ce_dflt_users    THEN act_sum:= act_sum || E'\n ** ' || ce_dflt_act;    END IF;
        IF act_sum != '' THEN
                act_sum:= 'Following items depend on target of configuration deletion:' || act_sum;
                RAISE WARNING '%', act_sum;
        END IF;

        IF NOT par_dont_modify_anything THEN
                DELETE FROM configurations AS c
                WHERE c.confentity_code_id = target_ce_id
                  AND c.configuration_id   = target_cfg_id;

                GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                rows_count_accum:= rows_count_accum + rows_count_add;
        END IF;

        RETURN rows_count_accum;
END;
$$;

COMMENT ON FUNCTION delete_config(
                par_config_key t_config_key
              , par_cascade_setnull_ce_dflt            boolean
              , par_cascade_setnull_param_dflt         boolean
              , par_cascade_setnull_param_val          boolean
              , par_warn_with_ce_dflt_use              boolean
              , par_warn_with_list_of_param_dflt_users boolean
              , par_warn_with_list_of_param_val_users  boolean
              , par_dont_modify_anything               boolean
             ) IS
'Returns count of rows deleted (from all tables).
The dependants, that may restrict configuration deletion:
** Configurable entity default
** Configurable entity parameter default
** Configurable entity parameter value
The function parmeters with "par_cascade_setnull_*" prefix -> sets their apropriate fields to NULL.
The function parmeters with "par_warn_with_*"       prefix -> outputs warning with list depending units.
';

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- GRANTS

-- Reference functions:
GRANT EXECUTE ON FUNCTION make_configkey(par_confentity_key t_confentity_key, par_config varchar, par_cfgid_is_lnged boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_configkey_null()TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_configkey_bystr(par_confentity_id integer, par_config varchar)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_configkey_bystr2(par_confentity_str varchar, par_config varchar)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION config_is_null(par_config_key t_config_key, par_total boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION config_is_null(par_config_key t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_configkey(par_configkey t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_configkeys_list(par_configkeys_list t_config_key[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_configkey_isit(par_configkey t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-- Lookup functions:
GRANT EXECUTE ON FUNCTION optimize_configkey(par_configkey t_config_key, par_verify boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimize_configkey(par_configkey t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION is_confentity_default(par_configkey t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION read_completeness(par_configkey t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION read_role__completeness_as_regulator(par_configkey t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-- Administration functions:
GRANT EXECUTE ON FUNCTION new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_config_names(par_config_key t_config_key, par_names name_construction_input[]) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION clone_config(par_config_key t_config_key, par_clone_config_id varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION set_confentity_default(par_config_key t_config_key, par_overwrite boolean) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION delete_config( par_config_key t_config_key
             , par_cascade_setnull_ce_dflt            boolean
             , par_cascade_setnull_param_dflt         boolean
             , par_cascade_setnull_param_val          boolean
             , par_warn_with_list_of_ce_dflt_users    boolean
             , par_warn_with_list_of_param_dflt_users boolean
             , par_warn_with_list_of_param_val_users  boolean
             , par_dont_modify_anything               boolean
             )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> config.init.sql [END]