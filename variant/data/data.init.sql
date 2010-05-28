-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner
SET search_path TO sch_<<$app_name$>>, comn_funs, public;
\set ECHO none

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> data.init.sql [BEGIN]

\set ECHO none

-------------------
-------------------

CREATE OR REPLACE FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__() RETURNS integer
LANGUAGE plpgsql
SET search_path TO sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE rows_cnt integer;
BEGIN
        PERFORM sch_<<$app_name$>>.delete_confentity(TRUE, sch_<<$app_name$>>.make_confentitykey_bystr('Configuration management system setup'), TRUE, FALSE);
        RETURN 0;
END;
$$;

COMMENT ON FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__() IS
'Deletes initial data from the database package "<<$pkg.name$>>" (version "<<$pkg.ver$>>").
This data is considered to be a part of the package.
Data is assumed to be inserted using "pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__()" function.
';

-------------------
-------------------

CREATE OR REPLACE FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__() RETURNS integer
LANGUAGE plpgsql
SET search_path TO sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE rows_cnt integer;
        setup_completeness   sch_<<$app_name$>>.t_config_completeness_check_result;
BEGIN
        PERFORM pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__();

        PERFORM new_confentity_w_params(
                        'Configuration management system setup'
                      , ARRAY[ mk_cparameter_uni(
                                  'when to check completeness'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('upper($1) IN (''FOR COMPLETE ONLY'', ''ALWAYS'') IS NOT NULL')] :: t_confparam_constraint[]
                                , FALSE                             -- not null
                                , 'par_d'                           -- usage of default
                                , NULL :: integer                   -- subconfentity_code_id (N/A)
                                , 'nonlnged_val' :: t_lnged_paramvalue_dflt_src
                                , mk_cpvalue_l('FOR COMPLETE ONLY', NULL :: integer) -- default value
                                )
                              , mk_cparameter_uni(
                                  'completeness as regulator'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('upper($1) IN (SELECT x.a :: varchar FROM unnest(enum_range(NULL :: t_completeness_as_regulator)) AS x(a)) IS NOT DISTINCT FROM TRUE')] :: t_confparam_constraint[]
                                , FALSE                             -- not null
                                , 'par_d'                           -- usage of default
                                , NULL :: integer                   -- subconfentity_code_id (N/A)
                                , 'nonlnged_val'
                                , mk_cpvalue_l('CHECK SET', NULL :: integer)         -- default value
                                )
                              , mk_cparameter_uni(
                                  'report on completeness check'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('upper($1) IN (SELECT x.a :: varchar FROM unnest(enum_range(NULL :: t_thorough_report_warning_mode)) AS x(a)) IS NOT DISTINCT FROM TRUE')] :: t_confparam_constraint[]
                                , FALSE                             -- not null
                                , 'par_d'                           -- usage of default
                                , NULL :: integer                   -- subconfentity_code_id (N/A)
                                , 'nonlnged_val'
                                , mk_cpvalue_l('WHEN LOSING COMPLETENESS', NULL :: integer)         -- default value
                                )
                              , mk_cparameter_uni(
                                  'notice config items creation/deletion'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('upper($1) IN (''ENABLED'', ''DISABLED'') IS NOT NULL')] :: t_confparam_constraint[]
                                , FALSE                             -- not null
                                , 'par_d'                           -- usage of default
                                , NULL :: integer                   -- subconfentity_code_id (N/A)
                                , 'nonlnged_val'
                                , mk_cpvalue_l('ENABLED', NULL :: integer)         -- default value
                                )
                              , mk_cparameter_uni(
                                  'completeness check routines'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('upper($1) IN (''ENABLED'', ''DISABLED'') IS NOT NULL')] :: t_confparam_constraint[]
                                , FALSE                           -- not null
                                , 'par_d'                         -- usage of default
                                , NULL :: integer                 -- subconfentity_code_id (N/A)
                                , 'nonlnged_val'
                                , mk_cpvalue_l('ENABLED', NULL :: integer)         -- default value
                                )
                              , mk_cparameter_uni(
                                  'autoadd languaged sub-/superconfigs'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('upper($1) IN (''ENABLED'', ''DISABLED'') IS NOT NULL')] :: t_confparam_constraint[]
                                , FALSE                           -- not null
                                , 'par_d'                         -- usage of default
                                , NULL :: integer                 -- subconfentity_code_id (N/A)
                                , 'nonlnged_val'
                                , mk_cpvalue_l('ENABLED', NULL :: integer)         -- default value
                                )
                               ] :: t_cparameter_uni[]
                        )
              ;

        PERFORM new_config(
                  FALSE
                , make_confentitykey_bystr('Configuration management system setup')
                , 'CMSS config #1'
                , ARRAY [ ROW('when to check completeness'  , mk_cpvalue_l('FOR COMPLETE ONLY', NULL :: integer))
                        , ROW('completeness as regulator'   , mk_cpvalue_l('SET INCOMPLETE', NULL :: integer))
                        , ROW('report on completeness check', mk_cpvalue_l('WHEN LOSING COMPLETENESS', NULL :: integer))
                        , ROW('notice config items creation/deletion'
                                                            , mk_cpvalue_l('DISABLED', NULL :: integer))
                        , ROW('completeness check routines' , mk_cpvalue_l('ENABLED', NULL :: integer))
                        , ROW('autoadd languaged sub-/superconfigs'
                                                            , mk_cpvalue_l('ENABLED', NULL :: integer))
                        ] :: t_paramvals__short[]
                );

        PERFORM set_confentity_default(
                   make_configkey_bystr2(
                        'Configuration management system setup'
                      , 'CMSS config #1'
                      )
                 , FALSE
                 );

        setup_completeness:= try_to_complete_config(
                                make_configkey_bystr2(
                                  'Configuration management system setup'
                                , 'CMSS config #1'
                             )  );

        IF NOT completeness_interpretation(setup_completeness) THEN
                RAISE EXCEPTION 'Unable to complete initial configuration for "Configuration management system setup"! Completeness check result: "%".', setup_completeness;
        END IF;

        ---------------------------------
        PERFORM add_confentity_names(
                  make_confentitykey_bystr('Configuration management system setup')
                , ARRAY[ mk_name_construction_input(
                                  make_codekeyl_bystr('eng')
                                , 'Configuration management system setup'
                                , make_codekeyl_null() -- 'configurable entity' by default here
                                ,
'Setup for the configuration management part of DBMS application - the part installed by "Config" package.
It''s parameters determines behaviour of triggers working on tables with configurations'' items.
Package uses config, which is set default to this configurable entity.
'
                                )
                       ]
                );

        PERFORM add_confparam_names(
                  make_confentityparamkey_bystr2('Configuration management system setup', 'when to check completeness')
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')   -- lng
                          , 'when to check completeness' -- languaged name
                          , make_codekeyl_null()         -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          ,
'The parameter determines cases, when parameter values must be checked to respect constraints.
The use of this parameter is coupled with parameter "completeness as regulator".
Possible values:
** "FOR COMPLETE ONLY" - values will be checked only for configurations that are complete ("configurations.complete_isit" = TRUE);
** "ALWAYS" - values will be checked only for any confuguration.
'
                         )
                       ] :: name_construction_input[]
                )
              , add_confparam_names(
                  make_confentityparamkey_bystr2('Configuration management system setup', 'completeness as regulator')
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'completeness as regulator'    -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'See comment to enum type "t_completeness_as_regulator".'
                          )
                       ] :: name_construction_input[]
                )
              , add_confparam_names(
                  make_confentityparamkey_bystr2('Configuration management system setup', 'report on completeness check')
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'report on completeness check' -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'See comment to enum type "t_thorough_report_warning_mode". You may want this disabled, if it''s a critical security priority not to flash extra data in the log file or in the interface with the administrative client.'
                          )
                       ] :: name_construction_input[]
                )
              , add_confparam_names(
                  make_confentityparamkey_bystr2('Configuration management system setup', 'notice config items creation/deletion')
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'notice config items creation/deletion' -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          ,                                -- description
'Should the creation/deletion NOTICES for configuration management items (confentities, configs, confparams, etc) be outputed?
Possible values:
** "ENABLED"
** "DISABLED"
You may want this disabled, if it''s a critical security priority not to flash extra data in the log file or in the interface with the administrative client.
'
                          )
                       ] :: name_construction_input[]
                )
              , add_confparam_names(
                  make_confentityparamkey_bystr2('Configuration management system setup', 'completeness check routines')
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'completeness check routines'  -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          ,                                -- description
'Should the configs be checked on completeness?
Possible values:
** "ENABLED"
** "DISABLED"
This option simply regulates, if "confentity_domain_onmodify" trigger function is active.
'
                          )
                       ] :: name_construction_input[]
                )
              , add_confparam_names(
                  make_confentityparamkey_bystr2('Configuration management system setup', 'autoadd languaged sub-/superconfigs')
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'autoadd languaged sub-/superconfigs' -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          ,                                -- description
'Whenever entry in "configurations_bylngs" is added (or updated to), should the entries for sub-/superconfigs be automatically added too?
Possible values:
** "ENABLED"
** "DISABLED"
It is highly recommended to keep this option enabled, since completeness check may fail, just because absence of
'
                          )
                       ] :: name_construction_input[]
                );

        PERFORM add_config_names(
                        make_configkey_bystr2(
                                  'Configuration management system setup'
                                , 'CMSS config #1'
                                )
                      , ARRAY [ mk_name_construction_input(
                                  make_codekeyl_bystr('eng')            -- lng
                                , 'CMSS config #1'                        -- languaged name
                                , make_codekeyl_null()                  -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                                , '<no comments>'                       -- description
                                )
                              ] :: name_construction_input[]
                );

        ---------------------------------------------------------

        RAISE NOTICE 'Configuration management system setup initiated.';

        RETURN 0;
END;
$$;

COMMENT ON FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__() IS
'Creates a setup, that is actually used by the configuration management part of DBMS application.
The function is alse a package usage self-example.

Inserts initial data into the database package "<<$pkg.name$>>" (version "<<$pkg.ver$>>").
This data is considered to be a part of the package.
Data is assumed to be possible to delete the initial data using "pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__()" function.
Also, this deletion function is called in the beginning of inserting function.
';

-------------------
-------------------

SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\set ECHO queries
SELECT pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__();
\set ECHO none

-------------------
-------------------

\echo NOTICE >>>>> data.init.sql [END]