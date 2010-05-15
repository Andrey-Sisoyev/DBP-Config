-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> confentity.test.sql
\i functions/confentity.test.sql

\echo NOTICE >>>>> config.test.sql
\i functions/config.test.sql

\echo NOTICE >>>>> confentityparam.test.sql
\i functions/confentityparam.test.sql

\echo NOTICE >>>>> configparam.test.sql
\i functions/configparam.test.sql

\echo NOTICE >>>>> configs_tree.test.sql
\i functions/configs_tree.test.sql

\echo NOTICE >>>>> completeness.test.sql
\i functions/completeness.test.sql

-- Reference functions:
-- none

\echo ----------------------------------------------
-- Lookup functions:

\echo testing NOTICE: read_cfgmngsys_setup() RETURNS t_cparameter_value_uni[]
SELECT read_cfgmngsys_setup();

\echo testing NOTICE: read_cfgmngsys_setup__output_credel_notices() RETURNS boolean
SELECT read_cfgmngsys_setup__output_credel_notices();