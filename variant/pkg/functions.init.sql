-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, comn_funs, public; -- sets only for current session
\set ECHO none

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\i functions/confentity.init.sql
\i functions/config.init.sql
\i functions/confentityparam.init.sql
\i functions/configparam.init.sql
\i functions/configs_tree.init.sql
\i functions/completeness.init.sql

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> functions.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- use it together with "get_param_from_list(t_cparameter_value_uni[], varchar) :: integer"
CREATE OR REPLACE FUNCTION read_cfgmngsys_setup() RETURNS t_cparameter_value_uni[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE cnt integer;
        ce  sch_<<$app_name$>>.t_confentity_key;
        cfg sch_<<$app_name$>>.t_config_key;
        ps  sch_<<$app_name$>>.t_cparameter_value_uni[];
BEGIN
        ce:= make_confentitykey_bystr('Configuration management system setup');
        ce:= optimize_confentitykey(FALSE, ce);
        cfg:= make_configkey_bystr(
                  code_id_of_confentitykey(ce)
                , get_confentity_default(ce)
                );

        ps:= get_paramvalues(FALSE, cfg);
        -- raise notice '------------------------>>>>>>>>>>>>>>>>>>0> %', ps;

        RETURN ps;
END;
$$;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION read_cfgmngsys_setup__output_credel_notices() RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
        r boolean;
        o varchar;
        cms_setup sch_<<$app_name$>>.t_cparameter_value_uni[];
BEGIN
        cms_setup:= sch_<<$app_name$>>.read_cfgmngsys_setup();
        o:= upper((cms_setup[sch_<<$app_name$>>.get_param_from_list(cms_setup, 'notice config items creation/deletion')]).final_value);
        CASE o
            WHEN 'ENABLED'  THEN r:= TRUE;
            WHEN 'DISABLED' THEN r:= FALSE;
            ELSE RAISE EXCEPTION 'Error in the "read_cfgmngsys_setup__output_credel_notices" TRIGGER function! Unsupported option for "notice config items creation/deletion": "%".', o;
        END CASE;
        RETURN r;
END;
$$;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION read_cfgmngsys_setup__perform_completness_routines() RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
        r boolean;
        o varchar;
        cms_setup sch_<<$app_name$>>.t_cparameter_value_uni[];
BEGIN
        cms_setup:= sch_<<$app_name$>>.read_cfgmngsys_setup();
        o:= upper((cms_setup[sch_<<$app_name$>>.get_param_from_list(cms_setup, 'completeness check routines')]).final_value);
        CASE o
            WHEN 'ENABLED'  THEN r:= TRUE;
            WHEN 'DISABLED' THEN r:= FALSE;
            ELSE RAISE EXCEPTION 'Error in the "read_cfgmngsys_setup__perform_completness_routines" TRIGGER function! Unsupported option for "completeness check routines": "%".', o;
        END CASE;
        RETURN r;
END;
$$;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_cfgs_ondepmodify(par_deps_list t_configs_tree_rel[], par_exclude_cfg t_config_key) RETURNS boolean
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        j integer;
        i integer;
        l integer;
        k integer;
        rows_cnt     integer;
        always_isit  boolean;
        on_actualize varchar;
        report_mode  t_thorough_report_warning_mode;
        complete     boolean;
        cms_setup     sch_<<$app_name$>>.t_cparameter_value_uni[];
        analized_cfgs sch_<<$app_name$>>.t_analyzed_cfgs_set;
        cfgs_list     sch_<<$app_name$>>.t_config_keys_list;
        cfg           sch_<<$app_name$>>.t_config_key;
        occa          sch_<<$app_name$>>.t_completeness_as_regulator;
        occa_use_dflt boolean;
        occa_option_name varchar;
BEGIN
        cms_setup:= read_cfgmngsys_setup();
        occa_option_name:= 'completeness as regulator';
        always_isit:=  upper((cms_setup[get_param_from_list(cms_setup, 'when to check completeness'  )]).final_value) = 'ALWAYS';
        on_actualize:= upper((cms_setup[get_param_from_list(cms_setup, occa_option_name              )]).final_value);
        report_mode:=       ((cms_setup[get_param_from_list(cms_setup, 'report on completeness check')]).final_value) :: t_thorough_report_warning_mode;

        analized_cfgs:= analyze_cfgs_tree(par_deps_list, par_exclude_cfg, FALSE); -- we will process deepest configs first
        IF array_length(analized_cfgs.involved_in_cycles, 1) > 0 THEN
                RAISE WARNING 'Warning by "update_cfgs_ondepmodify" function! Referential cycle is detected for a set of configurations. Completeness check for configuration referential cycles are not supported in this version - it is assumed to be INCOMPLETE. In order to use this version of configuration control system properly, please, get rid of referential cycles in your configs graph. Configurations involved in cycles: % ; configurations that refers cycled subconfigs: % .', show_configkeys_list(analized_cfgs.involved_in_cycles), show_configkeys_list(analized_cfgs.dep_on_cycles);

                UPDATE configurations
                SET complete_isit = 'cy_X'
                WHERE complete_isit <> 'cy_X'
                  AND ROW(confentity_code_id, configuration_id)
                          IN ( SELECT code_id_of_confentitykey(x.confentity_key)
                                    , x.config_id
                               FROM unnest (analized_cfgs.involved_in_cycles) AS x -- t_config_key
                               UNION
                               SELECT code_id_of_confentitykey(x.confentity_key)
                                    , x.config_id
                               FROM unnest (analized_cfgs.dep_on_cycles) AS x -- t_config_key
                             );
        END IF;

        l:= array_length(analized_cfgs.sorted_by_depth, 1);
        i:= 0;
        WHILE i < l LOOP
                i:= i + 1;
                j:= 0;
                cfgs_list:= (analized_cfgs.sorted_by_depth)[i];
                k:= array_length(cfgs_list.list, 1);
                WHILE j < k LOOP
                        j:= j + 1;
                        cfg:= (cfgs_list.list)[j];
                        occa:= read_role__completeness_as_regulator(cfg);
                        occa_use_dflt:= occa IS NULL;
                        IF occa_use_dflt THEN
                                occa:= on_actualize;
                        END IF;

                        CASE occa
                            WHEN 'RESTRICT' THEN
                                RAISE EXCEPTION 'Halt by "update_cfgs_ondepmodify" function! Any change that leaves any involved configuration incomplete is currently restricted in the "Configuration management system setup". Halt triggered for config that has option {"%" == "%", by default: %}, where config is %.', occa_option_name, occa, occa_use_dflt, show_configkey(cfg);
                            WHEN 'STRICT CHECK' THEN
                                complete:= NULL;
                                SELECT completeness_interpretation(
                                                config_completeness(
                                                  cfg         -- target
                                                , 1           -- thorough check current cfg, light check subs.
                                                , report_mode -- report
                                                , 0           -- no update
                                       )        )
                                INTO complete
                                FROM configurations AS c
                                WHERE c.configuration_id   = cfg.config_id
                                  AND c.confentity_code_id = code_id_of_confentitykey(cfg.confentity_key)
                                  AND (always_isit OR completeness_interpretation(c.complete_isit));

                                GET DIAGNOSTICS rows_cnt = ROW_COUNT;

                                IF (complete IS NOT DISTINCT FROM TRUE) OR (complete IS NULL AND rows_cnt = 0) THEN
                                        -- ok!
                                ELSE
                                        RAISE EXCEPTION 'Halt by "update_cfgs_ondepmodify" function! Any change that leaves any involved configuration incomplete is currently restricted in the "Configuration management system setup". Halt triggered for config that has option {"%" == "%", by default: %}, where config is %.', occa_option_name, occa, occa_use_dflt, show_configkey(cfg);
                                END IF;
                            WHEN 'CHECK SET'      THEN
                                PERFORM completeness_interpretation(config_completeness(
                                          cfg         -- target
                                        , 1           -- thorough check current cfg, light check subs.
                                        , report_mode -- report
                                        , 10          -- update only current config
                                       ))
                                FROM configurations AS c
                                WHERE c.configuration_id   = cfg.config_id
                                  AND c.confentity_code_id = code_id_of_confentitykey(cfg.confentity_key)
                                  AND (always_isit OR completeness_interpretation(c.complete_isit));
                            WHEN 'SET INCOMPLETE' THEN
                                UPDATE configurations AS c
                                SET complete_isit = 'li_chk_X'
                                WHERE complete_isit <> 'li_chk_X'
                                  AND c.configuration_id   = cfg.config_id
                                  AND c.confentity_code_id = code_id_of_confentitykey(cfg.confentity_key)
                                  AND completeness_interpretation(c.complete_isit);

                                GET DIAGNOSTICS rows_cnt = ROW_COUNT;

                                IF    (rows_cnt != 0)
                                  AND (  report_mode IS NOT DISTINCT FROM 'ALWAYS'
                                      OR report_mode IS NOT DISTINCT FROM 'WHEN LOSING COMPLETENESS'
                                      ) THEN
                                        RAISE WARNING 'Configuration set incomplete: %.', show_configkey(cfg);
                                END IF;
                            ELSE RAISE EXCEPTION 'Error in the "update_cfgs_ondepmodify" function! Unsupported mode in the setup parameter "completeness as regulator": "%".', upper((cms_setup[get_param_from_list(cms_setup, 'on completeness check actualization')]).final_value);
                        END CASE;
                END LOOP;
        END LOOP;

        RETURN TRUE;
END;
$$;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- GRANTS

-- Lookup functions:
GRANT EXECUTE ON FUNCTION read_cfgmngsys_setup()TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION read_cfgmngsys_setup__output_credel_notices()TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-- Administration functions:
GRANT EXECUTE ON FUNCTION update_cfgs_ondepmodify(par_deps_list t_configs_tree_rel[], par_exclude_cfg t_config_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> functions.init.sql [END]
