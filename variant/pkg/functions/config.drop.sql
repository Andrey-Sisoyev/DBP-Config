-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> config.drop.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Reference functions:
DROP FUNCTION IF EXISTS make_configkey(par_confentity_key t_confentity_key, par_config varchar, par_cfgid_is_lnged boolean, par_config_lng t_code_key_by_lng);
DROP FUNCTION IF EXISTS make_configkey_null();
DROP FUNCTION IF EXISTS make_configkey_bystr(par_confentity_id integer, par_config varchar);
DROP FUNCTION IF EXISTS make_configkey_bystr2(par_confentity_str varchar, par_config varchar);
DROP FUNCTION IF EXISTS config_is_null(par_config_key t_config_key, par_total boolean);
DROP FUNCTION IF EXISTS config_is_null(par_config_key t_config_key);
DROP FUNCTION IF EXISTS show_configkey(par_configkey t_config_key);
DROP FUNCTION IF EXISTS show_configkeys_list(par_configkeys_list t_config_key[]);
DROP FUNCTION IF EXISTS optimized_configkey_isit(par_configkey t_config_key);

-- Lookup functions:
DROP FUNCTION IF EXISTS optimize_configkey(par_configkey t_config_key, par_verify boolean);
DROP FUNCTION IF EXISTS optimize_configkey(par_configkey t_config_key);
DROP FUNCTION IF EXISTS is_confentity_default(par_configkey t_config_key);
DROP FUNCTION IF EXISTS read_completeness(par_configkey t_config_key);
DROP FUNCTION IF EXISTS read_role__completeness_as_regulator(par_configkey t_config_key);

-- Administration functions:
DROP FUNCTION IF EXISTS new_config(
                par_ifdoesnt_exist  boolean
              , par_confentity_key  t_confentity_key
              , par_config_id       varchar
              );
DROP FUNCTION IF EXISTS add_config_names(par_config_key t_config_key, par_names name_construction_input[]);
DROP FUNCTION IF EXISTS clone_config(par_config_key t_config_key, par_clone_config_id varchar);
DROP FUNCTION IF EXISTS set_confentity_default(par_config_key t_config_key, par_overwrite boolean);
DROP FUNCTION IF EXISTS delete_config( par_config_key t_config_key
             , par_cascade_setnull_ce_dflt            boolean
             , par_cascade_setnull_param_dflt         boolean
             , par_cascade_setnull_param_val          boolean
             , par_warn_with_list_of_ce_dflt_users    boolean
             , par_warn_with_list_of_param_dflt_users boolean
             , par_warn_with_list_of_param_val_users  boolean
             , par_dont_modify_anything               boolean
             );

------------------------
-- Types

DROP TYPE IF EXISTS t_config_key;
DROP TYPE IF EXISTS t_confentity_param__short;
DROP TYPE IF EXISTS t_config_param_subcfg__short;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> config.drop.sql [END]