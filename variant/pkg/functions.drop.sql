-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> functions.drop.sql

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

\echo NOTICE >>>>> completeness.drop.sql
\i functions/completeness.drop.sql
\echo NOTICE >>>>> configs_tree.drop.sql
\i functions/configs_tree.drop.sql
\echo NOTICE >>>>> configparam.drop.sql
\i functions/configparam.drop.sql
\echo NOTICE >>>>> confentityparam.drop.sql
\i functions/confentityparam.drop.sql
\echo NOTICE >>>>> config.drop.sql
\i functions/config.drop.sql
\echo NOTICE >>>>> confentity.drop.sql
\i functions/confentity.drop.sql
