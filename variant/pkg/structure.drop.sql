-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner
\set ECHO queries

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

DELETE FROM dbp_packages WHERE package_name = '<<$pkg.name$>>'
                           AND package_version = '<<$pkg.ver$>>'
                           AND dbp_standard_version = '<<$pkg.std_ver$>>';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> structure.drop.sql (part 1)

-- cleanup testing stuff (hust in case it's not cleaned up by tester itself due to the crash or ^C)
DROP TABLE IF EXISTS pkg_test_cases__;
DROP TABLE IF EXISTS test4__cparameters_values;
DROP TABLE IF EXISTS test3__cparameters_values;
DROP TABLE IF EXISTS test2__confentities;
DROP TABLE IF EXISTS test2__rels;
DROP TABLE IF EXISTS test1__cparameters_values;

DROP TRIGGER tri_confentity_onmodify         ON configurable_entities;
DROP TRIGGER tri_config_onmodify             ON configurations;
DROP TRIGGER tri_confparam_onmodify          ON configurations_parameters;
DROP TRIGGER tri_confparam_l_onmodify        ON configurations_parameters__leafs;
DROP TRIGGER tri_confparamvalue_l_onmodify   ON configurations_parameters_values__leafs;
DROP TRIGGER tri_confparam_s_onmodify        ON configurations_parameters__subconfigs;
DROP TRIGGER tri_confparamvalue_s_onmodify   ON configurations_parameters_values__subconfigs;
DROP FUNCTION confentity_domain_onmonify();

DROP TRIGGER tri_z_confentity_oncredel       ON configurable_entities;
DROP TRIGGER tri_z_config_oncredel           ON configurations;
DROP TRIGGER tri_z_confparam_oncredel        ON configurations_parameters;
DROP TRIGGER tri_z_confparam_l_oncredel      ON configurations_parameters__leafs;
DROP TRIGGER tri_z_confparamvalue_l_oncredel ON configurations_parameters_values__leafs;
DROP TRIGGER tri_z_confparam_s_oncredel      ON configurations_parameters__subconfigs;
DROP TRIGGER tri_z_confparamvalue_s_oncredel ON configurations_parameters_values__subconfigs;
DROP FUNCTION cfgunit_oncredel();

DROP TRIGGER tri_a_confentity_ondelete       ON sch_<<$app_name$>>.configurable_entities;
DROP FUNCTION confentity_ondelete();

\i ../data/data.drop.sql
\i functions.drop.sql

\echo NOTICE >>>>> structure.drop.sql (part 2)

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
