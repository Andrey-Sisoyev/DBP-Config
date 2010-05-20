-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> confentityparam.drop.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Reference functions:
DROP FUNCTION IF EXISTS mk_cpvalue_null();
DROP FUNCTION IF EXISTS mk_cpvalue_l(value varchar);
DROP FUNCTION IF EXISTS mk_cpvalue_s(value varchar, subcfg_ref_param_id varchar, subcfg_ref_usage t_subconfig_value_linking_read_rule);
DROP FUNCTION IF EXISTS isconsistent_cpvalue(par_value t_cpvalue_uni);
DROP FUNCTION IF EXISTS isdefined_cpvalue(par_value t_cpvalue_uni);
DROP FUNCTION IF EXISTS isnull_cpvalue(par_value t_cpvalue_uni, par_total boolean);

DROP FUNCTION IF EXISTS mk_cparameter_uni(
          par_param_id                    varchar
        , par_type                        t_confparam_type
        , par_constraints_array           t_confparam_constraint[]
        , par_allow_null_final_value      boolean
        , par_use_default_instead_of_null t_confparam_default_usage
        , par_subconfentity_code_id       integer
        , par_default_value               t_cpvalue_uni
        )
;

DROP FUNCTION IF EXISTS make_confentityparamkey(par_confentity_key t_confentity_key, key varchar, key_is_lnged boolean);
DROP FUNCTION IF EXISTS make_confentityparamkey_null();
DROP FUNCTION IF EXISTS make_confentityparamkey_bystr(par_confentity_id integer, par_param varchar);
DROP FUNCTION IF EXISTS make_confentityparamkey_bystr2(par_confentity_str varchar, par_param varchar);
DROP FUNCTION IF EXISTS confentityparam_is_null(par_confparam_key t_confentityparam_key, par_total boolean);
DROP FUNCTION IF EXISTS show_confentityparamkey(par_confparam_key t_confentityparam_key);
DROP FUNCTION IF EXISTS optimized_confentityparamkey_isit(par_confparam_key t_confentityparam_key);


-- Lookup functions:
DROP FUNCTION IF EXISTS optimize_confentityparamkey(par_confparam_key t_confentityparam_key, par_verify boolean);
DROP FUNCTION IF EXISTS determine_cparameter(par_confparam_key t_confentityparam_key);
DROP FUNCTION IF EXISTS get_params(par_confentity_key t_confentity_key);


-- Administration functions:
DROP FUNCTION IF EXISTS add_confparam_names(
                  par_confparam_key t_confentityparam_key
                , par_names         name_construction_input[]
                );
DROP FUNCTION IF EXISTS new_confparam_abstract(
                  par_confentity_key t_confentity_key
                , par_cparameter     t_cparameter_uni
                , par_ifdoesntexist  boolean
                );
DROP FUNCTION IF EXISTS instaniate_confparam_as_leaf(
                  par_confparam_key t_confentityparam_key
                , par_default_value varchar
                );
DROP FUNCTION IF EXISTS instaniate_confparam_as_subconfig(
          par_confparam_key    t_confentityparam_key
        , par_subconfentity_code_id integer
        , default_value        t_cpvalue_uni
        );
DROP FUNCTION IF EXISTS confparam_instaniated_isit(par_confparam_key t_confentityparam_key);
DROP FUNCTION IF EXISTS add_confparams(
                  par_confentity_key  t_confentity_key
                , par_cparameters_set t_cparameter_uni[]
                , par_ifdoesntexist   boolean
                );
DROP FUNCTION IF EXISTS new_confentity_w_params(
          par_ce_name         varchar
        , par_cparameters_set t_cparameter_uni[]
        );
DROP FUNCTION IF EXISTS deinstaniate_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                )
;
DROP FUNCTION IF EXISTS delete_confparam(
                  par_confparam_key                     t_confentityparam_key
                , par_cascade_setnull_subcfgrefernces   boolean
                , par_warn_with_list_of_subcfgrefernces boolean
                , par_dont_modify_anything              boolean
                )
;

------------------------
-- Types

DROP TYPE IF EXISTS t_cparameter_uni;
DROP TYPE IF EXISTS t_cpvalue_uni;
DROP TYPE IF EXISTS t_confentityparam_key;
DROP TYPE IF EXISTS t_config_param__short;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> confentityparam.drop.sql [END]
