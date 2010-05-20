-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>; -- , comn_funs, public; -- sets only for current session

\echo NOTICE >>>>> functions.drop.sql [BEGIN]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Top level functions and types
-- DROP FUNCTION IF EXISTS ...
-- DROP TYPE     IF EXISTS ...

-- Lookup functions:
DROP FUNCTION IF EXISTS read_cfgmngsys_setup();
DROP FUNCTION IF EXISTS read_cfgmngsys_setup__output_credel_notices();
DROP FUNCTION IF EXISTS read_cfgmngsys_setup__perform_completness_routines();

-- Administration functions:
DROP FUNCTION IF EXISTS update_cfgs_ondepmodify(par_deps_list t_configs_tree_rel[], par_exclude_cfg t_config_key);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> functions.drop.sql [END]

\i functions/completeness.drop.sql
\i functions/configs_tree.drop.sql
\i functions/configparam.drop.sql
\i functions/confentityparam.drop.sql
\i functions/config.drop.sql
\i functions/confentity.drop.sql