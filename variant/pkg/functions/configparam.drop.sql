-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Reference functions:
DROP FUNCTION IF EXISTS mk_cparameter_value(
          par_param_base      t_cparameter_uni
        , par_value           t_cpvalue_uni
        , par_final_value     varchar
        , par_final_value_src t_cpvalue_final_source
        , par_type            t_confparam_type
        );
DROP FUNCTION IF EXISTS get_param_from_list(par_parlist t_cparameter_value_uni[], par_target_name varchar);

DROP FUNCTION IF EXISTS make_configparamkey(par_config_key t_config_key, param_key varchar, param_key_is_lnged boolean);
DROP FUNCTION IF EXISTS make_configparamkey_null();
DROP FUNCTION IF EXISTS make_configparamkey_bystr2(par_confentity_id integer, par_config_id varchar, par_param_key varchar);
DROP FUNCTION IF EXISTS make_configparamkey_bystr3(par_confentity_str varchar, par_config_id varchar, par_param_key varchar);
DROP FUNCTION IF EXISTS make_cop_from_cep(par_confparam_key t_confentityparam_key, par_config_id varchar, par_cfg_lnged boolean);
DROP FUNCTION IF EXISTS make_cep_from_cop(par_configparam_key t_configparam_key);
DROP FUNCTION IF EXISTS configparamkey_is_null(par_configparam_key t_configparam_key, par_total boolean);
DROP FUNCTION IF EXISTS show_configparamkey(par_configparam_key t_configparam_key);
DROP FUNCTION IF EXISTS optimized_cop_isit(par_configparam_key t_configparam_key);
DROP FUNCTION IF EXISTS cparameter_finval_persists(
          par_cparam_val      t_cparameter_value_uni
        , par_final_value_src t_cpvalue_final_source
        );


-- Lookup functions:
DROP FUNCTION IF EXISTS optimize_configparamkey(par_configparam_key t_configparam_key);
DROP FUNCTION IF EXISTS determine_cvalue_of_cop(par_configparam_key t_configparam_key);
DROP FUNCTION IF EXISTS determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              , par_link_buffer varchar[]
              );
DROP FUNCTION IF EXISTS determine_value_of_cvalue(
                par_allow_null  boolean
              , par_cparamvalue t_cparameter_value_uni
              , par_config_key  t_config_key
              );
DROP FUNCTION IF EXISTS determine_finvalue_by_cop(
                par_allow_null  boolean
              , par_configparam_key t_configparam_key
              )
;
DROP FUNCTION IF EXISTS get_paramvalues(
          par_allow_null_values boolean
        , par_config_key        t_config_key
        );


-- Administration functions:
DROP FUNCTION IF EXISTS set_confparam_value(par_configparam_key t_configparam_key, par_cpvalue t_cpvalue_uni, par_overwrite integer);
DROP FUNCTION IF EXISTS set_confparam_values_set(par_config t_config_key, par_pv_set t_paramvals__short[], par_overwrite integer);
DROP FUNCTION IF EXISTS new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              , par_paramvalues_set t_paramvals__short[]
              );
DROP FUNCTION IF EXISTS unset_confparam_value(par_configparam_key t_configparam_key, par_ifvalueexists boolean);

------------------------
-- Types

DROP TYPE IF EXISTS t_paramvals__short;
DROP TYPE IF EXISTS t_configparam_key;
DROP TYPE IF EXISTS t_cparameter_value_uni;
DROP TYPE IF EXISTS t_cpvalue_final_source;

