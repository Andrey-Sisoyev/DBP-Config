-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_cpvalue_final_source AS ENUM ('ce_dflt', 'cp_dflt', 'cpv', 'cp_dflt_il', 'cpv_il', 'null');
COMMENT ON TYPE t_cpvalue_final_source IS '
Parameter value is may finally be determined from different sources, but always by same standard scheme.
Paramvalues sources:
** cpv        - a value in the "configurations_parameters_values__..." table.
** cp_dflt    - a default value in the "configurations_parameters__..." table.
** ce_dflt    - a default value in the "configurable_entities" table.
** cpv_il     - a value determined when following link from the "configurations_parameters_values__subconfigs" table. Since PostreSQL won''t allow recursive types, deeper information about source is not accessible.
** cp_dflt_il - a value determined when following link from the "configurations_parameters__subconfigs"        table. Since PostreSQL won''t allow recursive types, deeper information about source is not accessible.
** null       - a value is null

The algorithm to determine value is followng:
      Use "cpv"       , if parameter value is NOT NULL in the "configurations_parameters_values__..." table, and, if it''s subconfig, then "subconfiguration_link_usage" is not "alw_onl_lnk".
ELSE, use "cpv_il"    , if it''s subconfig, and "subconfiguration_link" is NOT NULL, and ("subconfiguration_link_usage" is "alw_onl_lnk" OR ("subconfiguration_link_usage" is "whn_vnull_lnk", and "subconfiguration_id" IS NULL)), and if determination of value of referenced parameter returns NOT NULL.
ELSE, use "cp_dflt"   , if usage of DEFAULT is allowed in the parameter setting, and parameter DEFAULT value is NOT NULL in the "configurations_parameters__..." table, and, if it''s subconfig, then "overload_default_link_usage" is not "alw_onl_lnk".
ELSE, use "cp_dflt_il", if it''s subconfig, and usage of DEFAULT is allowed in the parameter setting, and "overload_default_link" is NOT NULL, and ("overload_default_link_usage" is "alw_onl_lnk" OR ("overload_default_link_usage" is "whn_vnull_lnk", and "overload_default_subconfig" IS NULL)), and if determination of value of referenced parameter returns NOT NULL.
ELSE, use "ce_dflt"   , if usage of DEFAULT is allowed in the parameter setting, and if subconfentity is specified, and "default_configuration_id" for subconfentity is NOT NULL.
ELSE, use "null"
';

-------------

CREATE TYPE t_cparameter_value_uni AS (
          param_base      t_cparameter_uni
        , value           t_cpvalue_uni
        , final_value     varchar
        , final_value_src t_cpvalue_final_source
        );

COMMENT ON TYPE t_cparameter_value_uni IS '
To determine "final_value" and "final_value_src" use "determine_value_of_cvalue" function,
but make sure, that all other fields on input are filled - for this purpose use "determine_cvalue_of_cop".
';

CREATE OR REPLACE FUNCTION mk_cparameter_value(
          par_param_base      t_cparameter_uni
        , par_value           t_cpvalue_uni
        , par_final_value     varchar
        , par_final_value_src t_cpvalue_final_source
        , par_type            t_confparam_type
        ) RETURNS t_cparameter_value_uni AS $$
DECLARE
        cr1 boolean;
        cr2 boolean;
        cr3 boolean;
        r sch_<<$app_name$>>.t_cparameter_value_uni;
BEGIN
        IF par_param_base IS NULL THEN
                cr1:= TRUE;
                cr3:= TRUE;
        ELSE    cr1:= (par_param_base.type IS NOT DISTINCT FROM par_type);
                IF par_param_base.default_value IS NULL THEN
                        cr3:= TRUE;
                ELSE    cr3:= (par_param_base.default_value).type IS NOT DISTINCT FROM par_type;
                END IF;
        END IF;

        IF par_value IS NULL THEN
                cr2:= TRUE;
        ELSE    cr2:= (par_value.type IS NOT DISTINCT FROM par_type);
        END IF;

        IF cr1 AND cr2 AND cr3 THEN
                r:= ROW(par_param_base, par_value, par_final_value, par_final_value_src) :: sch_<<$app_name$>>.t_cparameter_value_uni;
                RETURN r;
        ELSE    RAISE EXCEPTION 'Ar error occurred in the "mk_cparameter_value" function! Parameter type inconsistency.';
        END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mk_cparameter_value(
          par_param_base      t_cparameter_uni
        , par_value           t_cpvalue_uni
        , par_final_value     varchar
        , par_final_value_src t_cpvalue_final_source
        , par_type            t_confparam_type
        ) IS
'The function will check, that type of parameter in every part of a constructed data structure is the same.
It will be tolefant, however to cases, when type holder parent construction is NULL. F.e., if "par_value" is NULL, then "par_value.type" won''t be checked.
';
------------------------------

CREATE OR REPLACE FUNCTION cparameter_finval_persists(
          par_cparam_val      t_cparameter_value_uni
        , par_final_value_src t_cpvalue_final_source
        ) RETURNS boolean AS $$
        SELECT $1.final_value IS NOT NULL AND $1.final_value_src IS NOT DISTINCT FROM $2;
$$ LANGUAGE SQL;

------------------------------

CREATE OR REPLACE FUNCTION get_param_from_list(par_parlist t_cparameter_value_uni[], par_target_name varchar) RETURNS integer AS $$
DECLARE
        i integer;
        l integer;
BEGIN
        l:= array_length(par_parlist, 1);
        i:= 1;
        WHILE (i <= l) AND (par_target_name != ((par_parlist[i]).param_base).param_id) LOOP
                i:= i + 1;
        END LOOP;

        IF i > l THEN RETURN NULL;
        ELSE RETURN i;
        END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_configparam_key AS (config_key t_config_key, param_key varchar, param_key_is_lnged boolean);

COMMENT ON TYPE t_configparam_key IS
'If "param_key_is_lnged" is TRUE, then the language of "param_key" field is assumed to be the same, as one specified for "config_key".';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_configparamkey(par_config_key t_config_key, param_key varchar, param_key_is_lnged boolean) RETURNS t_configparam_key AS $$
        SELECT ROW($1, $2, $3) :: sch_<<$app_name$>>.t_configparam_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_configparamkey_null() RETURNS t_configparam_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_configkey_null(), NULL :: varchar, NULL :: boolean) :: sch_<<$app_name$>>.t_configparam_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_configparamkey_bystr2(par_confentity_id integer, par_config_id varchar, par_param_key varchar) RETURNS t_configparam_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_configkey_bystr($1, $2), $3, FALSE) :: sch_<<$app_name$>>.t_configparam_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_configparamkey_bystr3(par_confentity_str varchar, par_config_id varchar, par_param_key varchar) RETURNS t_configparam_key AS $$
        SELECT ROW(sch_<<$app_name$>>.make_configkey_bystr2($1, $2), $3, FALSE) :: sch_<<$app_name$>>.t_configparam_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_cop_from_cep(par_confparam_key t_confentityparam_key, par_config_id varchar, par_cfg_lnged boolean) RETURNS t_configparam_key AS $$
        SELECT sch_<<$app_name$>>.make_configparamkey(
                        sch_<<$app_name$>>.make_configkey(($1).confentity_key, $2, $3)
                      , ($1).param_key
                      , ($1).param_key_is_lnged
                      ) :: sch_<<$app_name$>>.t_configparam_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_cep_from_cop(par_configparam_key t_configparam_key) RETURNS t_confentityparam_key AS $$
        SELECT sch_<<$app_name$>>.make_confentityparamkey(
                        (($1).config_key).confentity_key
                      , ($1).param_key
                      , ($1).param_key_is_lnged
                      ) :: sch_<<$app_name$>>.t_confentityparam_key;
$$ LANGUAGE SQL;

------------

CREATE OR REPLACE FUNCTION configparamkey_is_null(par_configparam_key t_configparam_key, par_total boolean) RETURNS boolean AS $$
        SELECT CASE WHEN $1 IS NULL THEN TRUE
                    ELSE CASE $2
                             WHEN TRUE  THEN sch_<<$app_name$>>.config_is_null($1.config_key, $2) AND ($1.param_key IS NULL) AND ($1.param_key_is_lnged IS NULL)
                             WHEN FALSE THEN sch_<<$app_name$>>.config_is_null($1.config_key, $2) OR  ($1.param_key IS NULL) OR  ($1.param_key_is_lnged IS NULL)
                         END
               END;
$$ LANGUAGE SQL;

--------------

CREATE OR REPLACE FUNCTION show_configparamkey(par_configparam_key t_configparam_key) RETURNS varchar AS $$
        SELECT '{t_configparam_key | '
            || ( CASE WHEN sch_<<$app_name$>>.configparamkey_is_null($1, TRUE) THEN 'NULL'
                      ELSE (  CASE WHEN sch_<<$app_name$>>.config_is_null(($1).config_key, TRUE) THEN ''
                                   ELSE 'config_key: '  || sch_<<$app_name$>>.show_configkey(($1).config_key) || ';'
                              END
                           )
                        || (  CASE WHEN ($1).param_key IS NULL THEN ''
                                   ELSE 'param_key: "' || ($1).param_key || '";'
                              END
                           )
                        || (  CASE WHEN ($1).param_key_is_lnged IS NULL THEN ''
                                   ELSE 'param_key_is_lnged: ' || ($1).param_key_is_lnged
                              END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL;

--------------

CREATE OR REPLACE FUNCTION optimized_cop_isit(par_configparam_key t_configparam_key) RETURNS boolean AS $$
DECLARE r boolean;
BEGIN
        IF par_configparam_key.param_key_is_lnged IS NULL THEN
                RAISE EXCEPTION 'An error occurred in the "optimized_cop_isit" function! Argument is not allowed to have NULL in ".param_key_is_lnged"!';
        END IF;
        IF par_configparam_key.param_key IS NULL THEN
                RAISE EXCEPTION 'An error occurred in the "optimized_cop_isit" function! Argument is not allowed to have NULL in ".param_key"!';
        END IF;
        IF sch_<<$app_name$>>.config_is_null(par_configparam_key.config_key, TRUE) THEN
                RAISE EXCEPTION 'An error occurred in the "optimized_cop_isit" function! Argument is not allowed to have NULL in ".config_key"!';
        END IF;

        r:= NOT par_configparam_key.param_key_is_lnged AND sch_<<$app_name$>>.optimized_configkey_isit(par_configparam_key.config_key);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

--------------

CREATE OR REPLACE FUNCTION optimize_configparamkey(par_configparam_key t_configparam_key) RETURNS t_configparam_key AS $$
DECLARE
        cop            sch_<<$app_name$>>.t_configparam_key;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        IF sch_<<$app_name$>>.optimized_cop_isit(par_configparam_key) THEN
                RETURN par_configparam_key;
        END IF;
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        cop := make_configparamkey(
                        optimize_configkey(par_configparam_key.config_key)
                      , par_configparam_key.param_key
                      , par_configparam_key.param_key_is_lnged
                      );
        cop := make_cop_from_cep(
                        optimize_confentityparamkey(make_cep_from_cop(cop), FALSE)
                      , (cop.config_key).config_id
                      , FALSE
                      );

        PERFORM leave_schema_namespace(namespace_info);
        RETURN cop ;
END;
$$ LANGUAGE plpgsql;

--------------

CREATE OR REPLACE FUNCTION determine_cvalue_of_cop(par_configparam_key t_configparam_key) RETURNS t_cparameter_value_uni AS $$
DECLARE
        cop      sch_<<$app_name$>>.t_configparam_key;
        cval     sch_<<$app_name$>>.t_cpvalue_uni;
        pt       sch_<<$app_name$>>.t_confparam_type;
        cparam   sch_<<$app_name$>>.t_cparameter_uni;
        r        sch_<<$app_name$>>.t_cparameter_value_uni;
        rec      RECORD;

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        cop := optimize_configparamkey(par_configparam_key);

        cparam:= determine_cparameter(make_cep_from_cop(cop));
        pt:= cparam.type;
        IF pt IS NULL THEN
                RAISE EXCEPTION 'An error occurred in function "determine_cvalue_of_cop" for key: %! Failed to determine type of parameter.', show_confentity_paramvalue(cop );
        END IF;

        CASE pt
            WHEN 'leaf' THEN
                SELECT mk_cpvalue_l(cpv_l.value) AS r1
                INTO rec
                FROM configurations_parameters_values__leafs AS cpv_l
                WHERE cpv_l.configuration_id   = (cop.config_key).config_id
                  AND cpv_l.confentity_code_id = code_id_of_confentitykey((cop.config_key).confentity_key)
                  AND cpv_l.parameter_id       = cop.param_key;

                cval:= rec.r1;

            WHEN 'subconfig' THEN
                SELECT mk_cpvalue_s(
                               cpv_s.subconfiguration_id
                             , cpv_s.subconfiguration_link
                             , cpv_s.subconfiguration_link_usage
                             ) AS r1
                INTO rec
                FROM configurations_parameters_values__subconfigs AS cpv_s
                WHERE cpv_s.configuration_id   = (cop.config_key).config_id
                  AND cpv_s.confentity_code_id = code_id_of_confentitykey((cop.config_key).confentity_key)
                  AND cpv_s.parameter_id       = cop.param_key;

                cval:= rec.r1;

            ELSE RAISE EXCEPTION 'An error occurred in function "determine_cvalue_of_cop" for key: %! Unsupported parameter type: "%".', show_confentity_paramvalue(cop ), pt;
        END CASE;

        r:= mk_cparameter_value(cparam, cval, NULL :: varchar, NULL :: t_cpvalue_final_source, pt);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION determine_cvalue_of_cop(
                par_configparam_key t_configparam_key
              ) IS '
The function won''t fill fields "final_value" and "final_value_src", but will fill everything else.
To determine final value, use output as an input to the "determine_value_of_cvalue" function.
';

--------------------------

CREATE OR REPLACE FUNCTION determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              , par_link_buffer varchar[]
              ) RETURNS t_cparameter_value_uni AS $$
DECLARE
        cp_f_val_lnk sch_<<$app_name$>>.t_cparameter_value_uni;
        cfg          sch_<<$app_name$>>.t_config_key;
        pt           sch_<<$app_name$>>.t_confparam_type;
        r            sch_<<$app_name$>>.t_cparameter_value_uni;

        value_source sch_<<$app_name$>>.t_cpvalue_final_source;
        val          varchar;
        lnk_param_id varchar;
        cur_parar_id varchar;
        new_lnk_buf  varchar[];

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        r:= par_cparamvalue;
        r.final_value:= NULL;
        r.final_value_src:= 'null';

        IF par_cparamvalue IS NULL THEN
                RETURN r;
        ELSIF par_cparamvalue.param_base IS NULL THEN
                RETURN r;
        END IF;

        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        pt          := (par_cparamvalue.param_base).type;
        cur_parar_id:= (par_cparamvalue.param_base).param_id;

        IF pt IS NULL THEN
                RAISE EXCEPTION 'An error occurred in function "determine_value_of_cvalue" for key: %! Failed to determine type of parameter.', par_cparamvalue;
        END IF;

        CASE pt
            WHEN 'leaf' THEN
                value_source:= 'null';
                val:= NULL;
                IF NOT isnull_cpvalue(par_cparamvalue.value, FALSE) THEN
                    IF (par_cparamvalue.value).value IS NOT NULL THEN
                        value_source:= 'cpv';
                        val:= (par_cparamvalue.value).value;
                    END IF;
                END IF;

                IF    value_source = 'null'
                  AND (par_cparamvalue.param_base).use_default_instead_of_null = 'par_d'
                  AND (NOT isnull_cpvalue((par_cparamvalue.param_base).default_value, FALSE))
                THEN
                    IF ((par_cparamvalue.param_base).default_value).value IS NOT NULL THEN
                        value_source:= 'cp_dflt';
                        val:= ((par_cparamvalue.param_base).default_value).value;
                    END IF;
                END IF;

            WHEN 'subconfig' THEN

                value_source:= 'null';
                val:= NULL;

                -- first check value
                IF NOT isnull_cpvalue(par_cparamvalue.value, FALSE) THEN
                        IF (par_cparamvalue.value).subcfg_ref_usage IS NOT NULL THEN
                            CASE (par_cparamvalue.value).subcfg_ref_usage
                                WHEN 'no_lnk' THEN
                                    IF (par_cparamvalue.value).value IS NOT NULL THEN
                                        value_source:= 'cpv';
                                        val:= (par_cparamvalue.value).value;
                                    END IF;
                                WHEN 'alw_onl_lnk' THEN
                                    IF (par_cparamvalue.value).subcfg_ref_param_id IS NOT NULL THEN
                                        value_source:= 'cpv_il';
                                        lnk_param_id:= (par_cparamvalue.value).subcfg_ref_param_id;
                                    END IF;
                                WHEN 'whn_vnull_lnk' THEN
                                    IF (par_cparamvalue.value).value IS NOT NULL THEN
                                        value_source:= 'cpv';
                                        val:= (par_cparamvalue.value).value;
                                    ELSIF (par_cparamvalue.value).subcfg_ref_param_id IS NOT NULL THEN
                                        value_source:= 'cpv_il';
                                        lnk_param_id:= (par_cparamvalue.value).subcfg_ref_param_id;
                                    END IF;
                                ELSE RAISE EXCEPTION 'An error occurred in function "determine_value_of_cvalue" for key: %! Unsupported type of subconfig-parameter link usage: %.', par_cparamvalue, (par_cparamvalue.value).subcfg_ref_usage;
                            END CASE;
                        END IF;
                END IF;

                -- if link persists, then extract it
                IF value_source = 'cpv_il' THEN
                        new_lnk_buf:= par_link_buffer || cur_parar_id;

                        IF lnk_param_id IN (SELECT * FROM unnest(new_lnk_buf) AS x) THEN
                                RAISE EXCEPTION 'An error occurred in the "determine_value_of_cvalue" function for key: %! Parameters-subconfigs references one another forming cycle: %!', par_cparamvalue, new_lnk_buf;
                        END IF;

                        cfg:= optimize_configkey(par_config_key, FALSE);

                        cp_f_val_lnk:= determine_value_of_cvalue(
                                par_allow_null
                              , determine_cvalue_of_cop(
                                        make_configparamkey(
                                                cfg
                                              , lnk_param_id
                                              , FALSE
                                              )
                                )
                              , cfg
                              , new_lnk_buf
                        );

                        val:= cp_f_val_lnk.final_value;
                        IF val IS NULL THEN value_source:= 'null'; END IF;
                END IF;

                -- then check default value
                IF    value_source = 'null'
                  AND (par_cparamvalue.param_base).use_default_instead_of_null IN ('par_d', 'par_d_sce_d')
                  AND (NOT isnull_cpvalue((par_cparamvalue.param_base).default_value, FALSE))
                THEN
                        IF ((par_cparamvalue.param_base).default_value).subcfg_ref_usage IS NOT NULL THEN
                            CASE ((par_cparamvalue.param_base).default_value).subcfg_ref_usage
                                WHEN 'no_lnk' THEN
                                    IF ((par_cparamvalue.param_base).default_value).value IS NOT NULL THEN
                                        value_source:= 'cp_dflt';
                                        val:= ((par_cparamvalue.param_base).default_value).value;
                                    END IF;
                                WHEN 'alw_onl_lnk' THEN
                                    IF ((par_cparamvalue.param_base).default_value).subcfg_ref_param_id IS NOT NULL THEN
                                        value_source:= 'cp_dflt_il';
                                        lnk_param_id:= ((par_cparamvalue.param_base).default_value).subcfg_ref_param_id;
                                    END IF;
                                WHEN 'whn_vnull_lnk' THEN
                                    IF ((par_cparamvalue.param_base).default_value).value IS NOT NULL THEN
                                        value_source:= 'cp_dflt';
                                        val:= ((par_cparamvalue.param_base).default_value).value;
                                    ELSIF ((par_cparamvalue.param_base).default_value).subcfg_ref_param_id IS NOT NULL THEN
                                        value_source:= 'cp_dflt_il';
                                        lnk_param_id:= ((par_cparamvalue.param_base).default_value).subcfg_ref_param_id;
                                    END IF;
                                ELSE RAISE EXCEPTION 'An error occurred in function "determine_value_of_cvalue" for key: %! Unsupported type of subconfig-parameter link usage: %.', par_cparamvalue, ((par_cparamvalue.param_base).default_value).subcfg_ref_usage;
                            END CASE;
                        END IF;
                END IF;

                IF value_source = 'cp_dflt_il' THEN
                        new_lnk_buf:= par_link_buffer || cur_parar_id;

                        IF lnk_param_id IN (SELECT * FROM unnest(new_lnk_buf) AS x) THEN
                                RAISE EXCEPTION 'An error occurred in the "determine_value_of_cvalue" function for key: %! Parameters-subconfigs references one another forming cycle: %!', par_cparamvalue, new_lnk_buf;
                        END IF;

                        cfg:= optimize_configkey(par_config_key, FALSE);

                        cp_f_val_lnk:= determine_value_of_cvalue(
                                par_allow_null
                              , determine_cvalue_of_cop(
                                        make_configparamkey(
                                                cfg
                                              , lnk_param_id
                                              , FALSE
                                              )
                                )
                              , cfg
                              , new_lnk_buf
                        );

                        val:= cp_f_val_lnk.final_value;
                        IF val IS NULL THEN value_source:= 'null'; END IF;
                END IF;

                IF    value_source = 'null'
                  AND (par_cparamvalue.param_base).use_default_instead_of_null IN ('sce_d', 'par_d_sce_d')
                  AND (par_cparamvalue.param_base).subconfentity_code_id IS NOT NULL
                THEN
                        val:= get_confentity_default(make_confentitykey_byid((par_cparamvalue.param_base).subconfentity_code_id));
                        IF val IS NOT NULL THEN value_source:= 'ce_dflt'; END IF;
                END IF;

            ELSE RAISE EXCEPTION 'An error occurred in function "determine_value_of_cvalue" for key: %! Unsupported parameter type: "%".', par_cparamvalue, pt;
        END CASE;

        r.final_value:= val;
        r.final_value_src:= value_source;

        IF     val IS NULL
           AND (NOT (par_allow_null OR (par_cparamvalue.param_base).allow_null_final_value))
        THEN RAISE EXCEPTION null_value_not_allowed USING HINT='Determined final value of config parameter "' || (par_cparamvalue.param_base).param_id || '" is not allowed to be NULL.';
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              , par_link_buffer varchar[]
              ) IS
'Parameter "par_allow_null" regulates, whether exception should be raised, when final value apperears to be NULL, but null is not allowed by confparameter setting.
Parameter "par_link_buffer" is for internal recursive use - just leave it ARRAY[] :: varchar[].

The function fills fields "final_value" and "final_value_src", given all other fields are filled.
The function is aimed to be used on the output of "determine_cvalue_of_cop" function.
';

-----

CREATE OR REPLACE FUNCTION determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              ) RETURNS t_cparameter_value_uni AS $$
        SELECT sch_<<$app_name$>>.determine_value_of_cvalue($1, $2, $3, ARRAY[] :: varchar[]);
$$ LANGUAGE SQL;

COMMENT ON FUNCTION determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              ) IS
'Wrapper around "determine_value_of_cvalue($1, $2, $3, ARRAY[] :: varchar[])".';

---------------------------

CREATE OR REPLACE FUNCTION determine_finvalue_by_cop(
                par_allow_null  boolean
              , par_configparam_key t_configparam_key
              ) RETURNS t_cparameter_value_uni AS $$
        SELECT sch_<<$app_name$>>.determine_value_of_cvalue(
                                $1
                              , sch_<<$app_name$>>.determine_cvalue_of_cop(ROW (x.*) :: sch_<<$app_name$>>.t_configparam_key)
                              , x.config_key
                              )
        FROM unnest(ARRAY(SELECT sch_<<$app_name$>>.optimize_configparamkey($2))) AS x;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION determine_finvalue_by_cop(
                par_allow_null  boolean
              , par_configparam_key t_configparam_key
              ) IS
'Wrapper around "determine_value_of_cvalue" and "determine_cvalue_of_cop" functions.';

---------------------------

CREATE OR REPLACE FUNCTION get_paramvalues(
          par_allow_null_values boolean
        , par_config_key        t_config_key
        ) RETURNS t_cparameter_value_uni[] AS $$
DECLARE
        g  sch_<<$app_name$>>.t_config_key;
        ps sch_<<$app_name$>>.t_cparameter_uni[];
        r  sch_<<$app_name$>>.t_cparameter_value_uni[];

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        g:= optimize_configkey(par_config_key, FALSE);
        ps:= get_params(g.confentity_key);

        r:= ARRAY(
                SELECT determine_finvalue_by_cop(
                                par_allow_null_values
                              , make_configparamkey(
                                                g
                                              , cps.param_id
                                              , FALSE
                                              )
                       )
                FROM unnest(ps) AS cps -- t_cparameter_uni
        );

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_paramvalues(par_allow_null_values boolean, par_config_key t_config_key) IS
'Wrapper around "get_params" and "determine_cvalue_of_cop(par_allow_null_values, ..." functions.
';

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_confparam_value(par_configparam_key t_configparam_key, par_cpvalue t_cpvalue_uni, par_overwrite integer) RETURNS integer AS $$
DECLARE
        g sch_<<$app_name$>>.t_configparam_key;
        test boolean;
        rows_cnt_add   integer;
        rows_cnt_accum integer;
        old_val varchar;
        sce_id  integer;
        old_lnk varchar;
        old_lnk_usage  sch_<<$app_name$>>.t_subconfig_value_linking_read_rule;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        IF par_overwrite NOT IN (0,1,10) THEN
                RAISE EXCEPTION 'An error occurred in function "set_confparam_value"! Wrong mode specified in "par_overwrite" parameter: %.', par_overwrite;
        END IF;

        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        IF NOT isconsistent_cpvalue(par_cpvalue) THEN
                RAISE EXCEPTION 'An error occurred in function "set_confparam_value"! Inconsistent value parameter (par_cpvalue).';
        END IF;
        rows_cnt_accum:= 0;

        g:= optimize_configparamkey(par_configparam_key);
        CASE par_cpvalue.type
            WHEN 'leaf' THEN
                SELECT cpv_l.value
                INTO old_val
                FROM configurations_parameters_values__leafs AS cpv_l
                WHERE cpv_l.confentity_code_id = code_id_of_confentitykey((g.config_key).confentity_key)
                  AND cpv_l.configuration_id   = (g.config_key).config_id
                  AND cpv_l.parameter_id       = g.param_key;

                GET DIAGNOSTICS rows_cnt_add = ROW_COUNT;

                IF rows_cnt_add = 0 THEN
                        SELECT TRUE
                        INTO test
                        FROM configurations_parameters__leafs AS cp_l
                        WHERE cp_l.confentity_code_id = code_id_of_confentitykey((g.config_key).confentity_key)
                          AND cp_l.parameter_id       = g.param_key;

                        GET DIAGNOSTICS rows_cnt_add = ROW_COUNT;

                        IF rows_cnt_add = 0 THEN
                                RAISE EXCEPTION 'Exception raised by the "set_confparam_value" function for key %! Confentity parameter-leaf not found!', show_configparamkey(par_configparam_key);
                        END IF;

                        INSERT INTO configurations_parameters_values__leafs (confentity_code_id, configuration_id, parameter_id, value)
                        VALUES ( code_id_of_confentitykey((g.config_key).confentity_key)
                               , (g.config_key).config_id
                               , g.param_key
                               , par_cpvalue.value
                               );

                        GET DIAGNOSTICS rows_cnt_add = ROW_COUNT;
                ELSE -- rows_cnt_add = 1
                        IF (par_overwrite = 1) OR (old_val IS NULL) THEN
                                UPDATE configurations_parameters_values__leafs AS cpv_l
                                SET value = par_cpvalue.value
                                WHERE cpv_l.confentity_code_id = code_id_of_confentitykey((g.config_key).confentity_key)
                                  AND cpv_l.configuration_id   = (g.config_key).config_id
                                  AND cpv_l.parameter_id       = g.param_key;

                                GET DIAGNOSTICS rows_cnt_add = ROW_COUNT;
                        ELSIF par_overwrite = 10 THEN
                                RAISE EXCEPTION 'Exception raised by the "set_confparam_value" function! Confparam value is already set - overwriting is restricted.';
                        END IF;
                END IF;
            WHEN 'subconfig' THEN
                SELECT cpv_s.subconfiguration_id
                     , cpv_s.subconfiguration_link
                     , cpv_s.subconfiguration_link_usage
                     , cpv_s.subconfentity_code_id
                INTO old_val, old_lnk, old_lnk_usage, sce_id
                FROM ((configurations AS c
                          INNER JOIN
                       configurations_parameters__subconfigs AS cp_s_
                          USING (confentity_code_id)
                      )
                        LEFT OUTER JOIN
                      configurations_parameters_values__subconfigs AS cpv_s_
                        USING (confentity_code_id, parameter_id, configuration_id, subconfentity_code_id)
                     ) AS cpv_s
                WHERE cpv_s.configuration_id      = (g.config_key).config_id
                  AND cpv_s.confentity_code_id    = code_id_of_confentitykey((g.config_key).confentity_key)
                  AND cpv_s.parameter_id          = g.param_key;

                GET DIAGNOSTICS rows_cnt_add = ROW_COUNT;

                IF rows_cnt_add = 0 THEN
                        RAISE EXCEPTION 'Exception raised by the "set_confparam_value" function for key %! Confentity parameter-subconfig not found!', show_configparamkey(par_configparam_key);
                END IF;

                IF old_lnk_usage IS NULL THEN
                        INSERT INTO configurations_parameters_values__subconfigs (
                                 confentity_code_id
                               , configuration_id
                               , parameter_id
                               , subconfentity_code_id
                               , subconfiguration_id
                               , subconfiguration_link
                               , subconfiguration_link_usage
                               )
                        VALUES ( code_id_of_confentitykey((g.config_key).confentity_key)
                               , (g.config_key).config_id
                               , g.param_key
                               , sce_id
                               , par_cpvalue.value
                               , par_cpvalue.subcfg_ref_param_id
                               , par_cpvalue.subcfg_ref_usage
                               );

                        GET DIAGNOSTICS rows_cnt_add = ROW_COUNT;
                ELSE
                        IF    par_overwrite = 1
                           OR (   old_lnk_usage IS NOT DISTINCT FROM par_cpvalue.subcfg_ref_usage
                              AND old_val IS NULL
                              AND old_lnk IS NULL
                              )
                        THEN
                                UPDATE configurations_parameters_values__subconfigs AS cpv_s
                                SET subconfiguration_id         = par_cpvalue.value
                                  , subconfiguration_link       = par_cpvalue.subcfg_ref_param_id
                                  , subconfiguration_link_usage = par_cpvalue.subcfg_ref_usage
                                WHERE cpv_s.confentity_code_id    = code_id_of_confentitykey((g.config_key).confentity_key)
                                  AND cpv_s.configuration_id      = (g.config_key).config_id
                                  AND cpv_s.parameter_id          = g.param_key;

                                GET DIAGNOSTICS rows_cnt_add = ROW_COUNT;
                        ELSIF par_overwrite = 10 THEN
                                RAISE EXCEPTION 'Exception raised by the "set_confparam_value" function! Confparam value is already set - overwriting is restricted.';
                        END IF;
                END IF;
            ELSE RAISE EXCEPTION 'Error in the "set_confparam_value" function! Unsupported parameter type: "%".', par_cpvalue.type;
        END CASE;

        rows_cnt_accum:= rows_cnt_accum + rows_cnt_add;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_cnt_accum;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_confparam_value(par_configparam_key t_configparam_key, par_cpvalue t_cpvalue_uni, par_overwrite integer) IS '
Returns number of rows modified.
Parameter "par_overwrite" values:
**  0 restrict overwrite - silent
** 10 restrict overwrite - raise exception
**  1          overwrite
No special overwrite permission is needed in case, when entry for confparam value is persistent (in the "configurations_parameters_values__...") table, but value there is NULL - this case is assumed to be "no value".
';

-----------------------

CREATE TYPE t_paramvals__short AS (param_id varchar, value t_cpvalue_uni);

CREATE OR REPLACE FUNCTION set_confparam_values_set(par_config t_config_key, par_pv_set t_paramvals__short[], par_overwrite integer) RETURNS integer AS $$
DECLARE
        g                   sch_<<$app_name$>>.t_config_key;
        cfg_params          sch_<<$app_name$>>.t_cparameter_uni[];
        cfg_params_vals     sch_<<$app_name$>>.t_cparameter_value_uni[];
        rows_accum integer;
        rows_add   integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        IF par_overwrite NOT IN (0,1,10) THEN
                RAISE EXCEPTION 'An error occurred in function "set_confparam_values_set"! Wrong mode specified in "par_overwrite" parameter: %.', par_overwrite;
        END IF;

        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        g:= optimize_configkey(par_config, FALSE);
        cfg_params:= get_params(g.confentity_key);

        -- types coherence checked here
        cfg_params_vals:= ARRAY(
                SELECT mk_cparameter_value(
                          ROW(x.*) :: t_cparameter_uni
                        , CASE x.type
                              WHEN 'leaf'      THEN mk_cpvalue_l(((ROW(y.*) :: t_paramvals__short).value).value)
                              WHEN 'subconfig' THEN mk_cpvalue_s(
                                                          ((ROW(y.*) :: t_paramvals__short).value).value
                                                        , ((ROW(y.*) :: t_paramvals__short).value).subcfg_ref_param_id
                                                        , ((ROW(y.*) :: t_paramvals__short).value).subcfg_ref_usage
                                                        )
                          END
                        , NULL :: varchar
                        , NULL :: t_cpvalue_final_source
                        , x.type
                        )
                FROM unnest(cfg_params) AS x -- t_cparameter_uni
                        INNER JOIN
                     unnest(par_pv_set) AS y -- t_paramvals__short
                        using (param_id)
        );

        rows_accum:= 0;
        SELECT SUM(set_confparam_value(
                        make_configparamkey(g, ((ROW(x.*) :: t_cparameter_value_uni).param_base).param_id, FALSE)
                      , (ROW(x.*) :: t_cparameter_value_uni).value
                      , par_overwrite
                  )   )
        INTO rows_accum
        FROM unnest(cfg_params_vals) AS x; -- t_cparameter_value_uni

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_accum;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_confparam_values_set(par_config t_config_key, par_pv_set t_paramvals__short[], par_overwrite integer) IS
'Returns number of rows modified.
Parameter "par_overwrite" values:
**  0 restrict overwrite (silent)          - if at least 1 parameter was to be overwritten, the whole operation is cancelled
** 10 restrict overwrite (raise exception) - if at least 1 parameter was to be overwritten, the whole operation is cancelled
**  1          overwrite - overwrite every value
No special overwrite permission is needed in case, when entry for confparam value is persistent (in the "configurations_parameters_values__...") table, but value there is NULL - this case is assumed to be "no value".
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              , par_paramvalues_set t_paramvals__short[]
              ) RETURNS integer AS $$
DECLARE
        target_confentity_id integer;
        rows_count_add   integer;
        rows_count_accum integer;
        cfg sch_<<$app_name$>>.t_config_key;
        g   sch_<<$app_name$>>.t_confentity_key;

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        g:= optimize_confentitykey(FALSE, par_confentity_key);
        rows_count_accum:= new_config(par_ifdoesnt_exist, g, par_config_id);

        target_confentity_id:= code_id_of_confentitykey(g);

        cfg:= make_configkey(g, par_config_id, FALSE);

        rows_count_add:= set_confparam_values_set(cfg, par_paramvalues_set, 10);
        rows_count_accum:= rows_count_accum + rows_count_add;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_count_accum;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              , par_paramvalues_set t_paramvals__short[]
              ) IS
'Returns count of rows inserted.
The "par_config_id" parameter is not languaged.
Relies on "new_config(par_ifdoesnt_exist boolean, par_confentity_key t_confentity_key, par_config_id varchar)" and "set_confparam_values_set(par_config t_config_key, par_pv_set t_paramvals__short[], par_overwrite integer)".
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION unset_confparam_value(par_configparam_key t_configparam_key, par_ifvalueexists boolean) RETURNS integer AS $$
DECLARE g  sch_<<$app_name$>>.t_configparam_key;
        pv sch_<<$app_name$>>.t_cparameter_uni;
        rows_cnt integer;

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        g := optimize_configparamkey(par_configparam_key);
        pv:= determine_cparameter(make_cep_from_cop(g));

        CASE pv.type
            WHEN 'leaf' THEN
                DELETE FROM configurations_parameters_values__leafs AS cpv_l
                WHERE cpv_l.confentity_code_id = code_id_of_confentitykey((g.config_key).confentity_key)
                  AND cpv_l.configuration_id   = (g.config_key).config_id
                  AND cpv_l.parameter_id       = g.param_key;
            WHEN 'subconfig' THEN
                DELETE FROM configurations_parameters_values__subconfigs AS cpv_s
                WHERE cpv_s.confentity_code_id    = code_id_of_confentitykey((g.config_key).confentity_key)
                  AND cpv_s.configuration_id      = (g.config_key).config_id
                  AND cpv_s.parameter_id          = g.param_key;
            ELSE RAISE EXCEPTION 'Error in the "unset_confparam_value" function! Unsupported parameter type: "%".', pv.type;
        END CASE;

        GET DIAGNOSTICS rows_cnt = ROW_COUNT;

        IF (rows_cnt = 0) THEN
                IF par_ifvalueexists IS NOT DISTINCT FROM FALSE THEN
                        RAISE EXCEPTION 'Exception raised by the "unset_confparam_value" function! Value not found!';
                ELSE
                        SELECT 1
                        INTO rows_cnt
                        FROM configurations_parameters AS cp
                        WHERE cp.confentity_code_id = code_id_of_confentitykey((g.config_key).confentity_key)
                          AND cp.parameter_id       = g.param_key;

                        GET DIAGNOSTICS rows_cnt = ROW_COUNT;
                        IF rows_cnt = 0 THEN
                                RAISE EXCEPTION 'Exception raised by the "unset_confparam_value" function! Parameter not found!';
                        END IF;
                        rows_cnt:= 0;
                END IF;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION unset_confparam_value(par_configparam_key t_configparam_key, par_ifvalueexists boolean) IS '
Deletes entry from "configurations_parameters_values__(leafs|subconfigs)" table.
Parameter "par_ifparamexists":TRUE -> if parameter not found, then exception is rised (won''t rise exception if parameter is abstract)
Parameter "par_ifvalueexists":TRUE -> if   value was not set, then exception is rised (won''t rise exception if value entry was there in the values-table, but was NULL)
';

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- GRANTS

-- Reference functions:
GRANT EXECUTE ON FUNCTION mk_cparameter_value(
          par_param_base      t_cparameter_uni
        , par_value           t_cpvalue_uni
        , par_final_value     varchar
        , par_final_value_src t_cpvalue_final_source
        , par_type            t_confparam_type
        )TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_param_from_list(par_parlist t_cparameter_value_uni[], par_target_name varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

GRANT EXECUTE ON FUNCTION make_configparamkey(par_config_key t_config_key, param_key varchar, param_key_is_lnged boolean)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_configparamkey_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_configparamkey_bystr2(par_confentity_id integer , par_config_id varchar, par_param_key varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_configparamkey_bystr3(par_confentity_str varchar, par_config_id varchar, par_param_key varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_cop_from_cep(par_confparam_key t_confentityparam_key, par_config_id varchar, par_cfg_lnged boolean)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_cep_from_cop(par_configparam_key t_configparam_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION configparamkey_is_null(par_configparam_key t_configparam_key, par_total boolean)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_configparamkey(par_configparam_key t_configparam_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_cop_isit(par_configparam_key t_configparam_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION cparameter_finval_persists(
          par_cparam_val      t_cparameter_value_uni
        , par_final_value_src t_cpvalue_final_source
        )TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;


-- Lookup functions:
GRANT EXECUTE ON FUNCTION optimize_configparamkey(par_configparam_key t_configparam_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION determine_cvalue_of_cop(par_configparam_key t_configparam_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              , par_link_buffer varchar[]
              )TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              )TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION determine_finvalue_by_cop(
                par_allow_null  boolean
              , par_configparam_key t_configparam_key
              )
TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_paramvalues(
          par_allow_null_values boolean
        , par_config_key        t_config_key
        )TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;


-- Administration functions:
GRANT EXECUTE ON FUNCTION set_confparam_value(par_configparam_key t_configparam_key, par_cpvalue t_cpvalue_uni, par_overwrite integer) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION set_confparam_values_set(par_config t_config_key, par_pv_set t_paramvals__short[], par_overwrite integer) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              , par_paramvalues_set t_paramvals__short[]
              ) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION unset_confparam_value(par_configparam_key t_configparam_key, par_ifvalueexists boolean) TO user_<<$app_name$>>_data_admin;
