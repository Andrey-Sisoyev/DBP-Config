-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>; -- , comn_funs, public; -- sets only for current session

DELETE FROM dbp_packages WHERE package_name = '<<$pkg.name$>>'
                           AND package_version = '<<$pkg.ver$>>'
                           AND dbp_standard_version = '<<$pkg.std_ver$>>';

-- IF DROPPING CUSTOM ROLES/TABLESPACES, then don't forget to unregister
-- them (under application owner DB account) using
-- FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
--        par_cwobj_name varchar
--      , par_cwobj_type t_clusterwide_obj_types
--      )
-- , where TYPE public.t_clusterwide_obj_types IS ENUM ('tablespace', 'role')

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\i triggers.drop.sql
\i ../data/data.drop.sql
\i functions.drop.sql

-------------------------------------------------------------------------------

\echo NOTICE >>>>> structure.drop.sql [BEGIN]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP INDEX pvs_confentities_of_params_idx;
DROP INDEX pvs_params_of_confentities_idx;
DROP TABLE configurations_parameters_values__subconfigs;
DROP INDEX ps_confentities_of_params_idx;
DROP INDEX ps_params_of_confentities_idx;
DROP INDEX          cp_s_ilref_base_uidx;
DROP TABLE configurations_parameters__subconfigs;
DROP TYPE t_subconfig_value_linking_read_rule;
DROP INDEX pvl_confentities_of_params_idx;
DROP INDEX pvl_params_of_confentities_idx;
DROP TABLE configurations_parameters_values__leafs;
DROP INDEX pl_confentities_of_params_idx;
DROP INDEX pl_params_of_confentities_idx;
DROP TABLE configurations_parameters__leafs;
DROP INDEX names_of_confparams_idx;
DROP TABLE configurations_parameters_names;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Named entities', 'configuration parameter'), TRUE, TRUE, TRUE);

DROP INDEX confentities_of_params_idx;
DROP INDEX params_of_confentities_idx;
DROP TABLE configurations_parameters;
DROP TYPE t_confparam_default_usage;
DROP FUNCTION mk_confparam_constraint(par_fun varchar);
DROP TYPE t_confparam_constraint;
DROP TYPE t_confparam_type;
DROP INDEX names_of_configs_idx;
DROP TABLE configurations_names;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Named entities', 'configuration'), TRUE, TRUE, TRUE);

DROP INDEX configs_confentities_idx;

ALTER TABLE configurable_entities DROP CONSTRAINT cnstr_confentities_default_configs;

DROP TABLE configurations;
DROP TYPE t_completeness_as_regulator;
DROP TYPE t_config_completeness_check_result;
DROP TABLE configurable_entities;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Named entities' , 'configurable entity')  , TRUE, TRUE, TRUE);
SELECT remove_code(TRUE, make_acodekeyl_bystr2('Usual codifiers', 'Configurable entities'), TRUE, TRUE, TRUE);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> structure.drop.sql [END]