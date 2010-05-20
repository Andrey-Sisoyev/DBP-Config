-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.drop.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

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

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.drop.sql [END]