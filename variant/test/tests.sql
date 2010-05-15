-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public;
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\echo WARNING!!! This tester is not guaranteed to be safe for user data - do not apply it where user already defined it's codes!!

------------------------------------------
-- Just in case... if anything is lost, at least one will be able to recover it from log...

SELECT * FROM configurable_entities;
SELECT * FROM configurations;
SELECT * FROM configurations_names;
SELECT * FROM configurations_parameters;
SELECT * FROM configurations_parameters_names;
SELECT * FROM configurations_parameters__leafs;
SELECT * FROM configurations_parameters__subconfigs;
SELECT * FROM configurations_parameters_values__leafs;
SELECT * FROM configurations_parameters_values__subconfigs;

\echo
\echo --------------------------------------------------------------
\echo

\i prepare.sql

\echo
\echo --------------------------------------------------------------
\echo

SELECT ce.*, c.code_text FROM configurable_entities AS ce, codes AS c WHERE code_id = confentity_code_id ORDER BY confentity_code_id;
SELECT * FROM configurations ORDER BY confentity_code_id, configuration_id;
SELECT * FROM configurations_names ORDER BY confentity_code_id;
SELECT * FROM configurations_parameters ORDER BY confentity_code_id, parameter_id;
SELECT * FROM configurations_parameters_names ORDER BY confentity_code_id, parameter_id;
SELECT * FROM configurations_parameters__leafs ORDER BY confentity_code_id, parameter_id;
SELECT * FROM configurations_parameters__subconfigs ORDER BY confentity_code_id, parameter_id;
SELECT * FROM configurations_parameters_values__leafs ORDER BY confentity_code_id, configuration_id, parameter_id;
SELECT * FROM configurations_parameters_values__subconfigs ORDER BY confentity_code_id, configuration_id, parameter_id;

\echo
\echo --------------------------------------------------------------
\echo

\c <<$db_name$>> user_<<$app_name$>>_data_admin

SET search_path TO sch_<<$app_name$>>, public;
\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\i functions.tests.sql

\echo
\echo --------------------------------------------------------------
\echo

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public;
\set ECHO none
SELECT set_config('client_min_messages', 'NOTICE', FALSE);


-- \i cleanup.sql

\echo
\echo --------------------------------------------------------------
\echo NOTICE: Aftertest data

SELECT * FROM configurable_entities;
SELECT * FROM configurations;
SELECT * FROM configurations_names;
SELECT * FROM configurations_parameters;
SELECT * FROM configurations_parameters_names;
SELECT * FROM configurations_parameters__leafs;
SELECT * FROM configurations_parameters__subconfigs;
SELECT * FROM configurations_parameters_values__leafs;
SELECT * FROM configurations_parameters_values__subconfigs;

\echo NOTICE: Testing END