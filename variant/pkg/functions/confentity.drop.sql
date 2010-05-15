-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Reference functions:
DROP FUNCTION IF EXISTS make_confentitykey(par_confentity_key t_code_key_by_lng);
DROP FUNCTION IF EXISTS make_confentitykey_null();
DROP FUNCTION IF EXISTS make_confentitykey_bystr(par_confentity_str varchar);
DROP FUNCTION IF EXISTS make_confentitykey_byid(par_confentity_id integer);
DROP FUNCTION IF EXISTS code_id_of_confentitykey(par_confentity_key t_confentity_key);
DROP FUNCTION IF EXISTS confentity_is_null(par_confentity_key t_confentity_key);
DROP FUNCTION IF EXISTS confentity_has_lng(par_confentity_key t_confentity_key);
DROP FUNCTION IF EXISTS show_confentitykey(par_confentitykey t_confentity_key);
DROP FUNCTION IF EXISTS optimized_confentitykey_isit(par_confentitykey t_confentity_key, par_opt_lng boolean);
DROP FUNCTION IF EXISTS optimized_confentitykey_isit(par_confentitykey t_confentity_key);

-- Lookup functions:
DROP FUNCTION IF EXISTS optimize_confentitykey(par_ifexists boolean, par_confentitykey t_confentity_key);
DROP FUNCTION IF EXISTS get_confentity_default(par_confentity_key t_confentity_key);
DROP FUNCTION IF EXISTS get_confentity_id(par_confentity_name varchar);
DROP FUNCTION IF EXISTS get_confentity_id(par_confentity_key t_confentity_key);

-- Administration functions:
DROP FUNCTION IF EXISTS add_confentity_names(par_confentity_key t_confentity_key, par_names name_construction_input[]);
DROP FUNCTION IF EXISTS new_confentity(par_name varchar, par_ifdoesnt_exist boolean);
DROP FUNCTION IF EXISTS new_confentity(
          par_name           varchar
        , par_ifdoesnt_exist boolean
        , par_lng_names      name_construction_input[]
        );
DROP FUNCTION IF EXISTS delete_confentity(
                  par_ifexists                           boolean
                , par_confentity_key                     t_confentity_key
                , par_cascade_deinstan_referrers_params  boolean
                , par_cascade_del_configs                boolean
                , par_warn_with_list_of_referrers_params boolean
                , par_warn_with_list_of_configs          boolean
                , par_dont_modify_anything               boolean

                , par_cascade_setnull_ce_dflt            boolean
                , par_cascade_setnull_param_dflt         boolean
                , par_cascade_setnull_param_val          boolean
                , par_warn_with_list_of_ce_dflt_users    boolean
                , par_warn_with_list_of_param_dflt_users boolean
                , par_warn_with_list_of_param_val_users  boolean
                , par_dont_modify_any_config             boolean

                , par_cascade_setnull_subcfgrefernces    boolean
                , par_warn_with_list_of_subcfgrefernces  boolean
                , par_dont_modify_any_referrer_param     boolean
                );
DROP FUNCTION IF EXISTS delete_confentity(
                  par_if_exists            boolean
                , par_confentity_key       t_confentity_key
                , par_cascade              boolean
                , par_dont_modify_anything boolean
                );

------------------------
-- Types

DROP TYPE IF EXISTS t_confentity_key;
DROP TYPE IF EXISTS t_confentity_param_wdelstats__short;
DROP TYPE IF EXISTS t_cfg_wdelstats__short;
