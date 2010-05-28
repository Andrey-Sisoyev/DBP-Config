-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> completeness.drop.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Reference functions:
DROP FUNCTION IF EXISTS completeness_interpretation(par_completeness t_config_completeness_check_result);
DROP FUNCTION IF EXISTS show_completeness_check_result(par_completeness t_config_completeness_check_result);
DROP FUNCTION IF EXISTS mk_completeness_precheck_row(
        par_confentity_code_id integer
      , par_config_id          varchar
      , par_param_value        t_cparameter_value_uni
      , par_cc_null_cnstr_passed_ok    boolean
      , par_cc_cnstr_array_failure_idx integer
      , par_cc_subconfig_is_complete   t_config_completeness_check_result
      );
DROP FUNCTION IF EXISTS form_cc_report(par_cfgkey t_config_key, par_cc_rows t_completeness_check_row[]);


-- Analytic functions:
DROP FUNCTION IF EXISTS cc_null_check(par_cc_row t_completeness_check_row);
DROP FUNCTION IF EXISTS cc_cnstr_arr_check(par_cc_row t_completeness_check_row);
DROP FUNCTION IF EXISTS seek_paramvalues_cc_by_subcfg_ctr(par_config_tree_row t_configs_tree_rel, par_pvcc_set t_completeness_check_row[]);
DROP FUNCTION IF EXISTS cc_isit(par_cc_rows t_completeness_check_row[]);
DROP FUNCTION IF EXISTS check_paramvalues_cc(
          par_cc_rows                 t_completeness_check_row[]
        , par_perform_cnstr_checks    integer
        , par_thorough_report_warning t_thorough_report_warning_mode
        , par_val_lng_id              integer
        );


-- Lookup functions:
DROP FUNCTION IF EXISTS check_paramvalues_cc(
          par_cc_rows                 t_completeness_check_row[]
        , par_perform_cnstr_checks    integer
        , par_thorough_report_warning t_thorough_report_warning_mode
        , par_val_lng_id              integer
        );
DROP FUNCTION IF EXISTS get_paramvalues_cc(par_config_key t_config_key);


-- Administration functions:
DROP FUNCTION IF EXISTS config_completeness(
                  par_config_tree_row         t_configs_tree_rel
                , par_values_lng_id           integer
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                );
DROP FUNCTION IF EXISTS config_completeness(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                );
DROP FUNCTION IF EXISTS config_is_complete(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                );
DROP FUNCTION IF EXISTS try_to_complete_config(par_config_key t_config_key);
DROP FUNCTION IF EXISTS uncomplete_cfg(par_config_key t_config_key);

------------------------
-- Types

DROP TYPE IF EXISTS t_completeness_check_file;
DROP TYPE IF EXISTS t_completeness_check_row;
DROP TYPE IF EXISTS t_thorough_report_warning_mode;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> completeness.drop.sql [END]