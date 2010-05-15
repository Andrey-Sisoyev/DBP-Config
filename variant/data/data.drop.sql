-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> data.drop.sql

-- SELECT * FROM configurations;
\echo Notices on deletion won't be outputed, since triggers are already removed.
SELECT delete_cfgmgrsys_setup_confentity__();
DROP FUNCTION delete_cfgmgrsys_setup_confentity__();
DROP FUNCTION   init_cfgmgrsys_setup_confentity__();