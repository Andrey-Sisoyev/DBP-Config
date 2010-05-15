-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- TYPE t_config_key AS (confentity_key t_confentity_key, config_id varchar, cfgid_is_lnged boolean)
-- TYPE t_confentity_param__short AS (ce_id integer, param_id varchar)
-- TYPE t_config_param_subcfg__short AS (ce_id integer, config_id varchar, param_id varchar)

-- Reference functions:
SELECT show_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', FALSE));
SELECT show_configkey(make_configkey(make_confentitykey(make_codekeyl_bystrl(make_codekey_bystr('rus'), 'Болванка_1_КС')), 'Болванка_1_КФГ', TRUE));
SELECT show_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Болванка_1_КФГ', TRUE));
SELECT show_configkey(make_configkey_null());
SELECT show_configkey(make_configkey_bystr(1, 'Dummy_1_CFG'));
SELECT show_configkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'));

SELECT config_is_null(make_configkey_null(), TRUE);
SELECT config_is_null(make_configkey_null(), FALSE);
SELECT config_is_null(make_configkey(NULL :: t_confentity_key, 'Dummy_1_CFG', FALSE), TRUE);
SELECT config_is_null(make_configkey(NULL :: t_confentity_key, 'Dummy_1_CFG', FALSE), FALSE);
SELECT config_is_null(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), NULL :: varchar, FALSE), TRUE);
SELECT config_is_null(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), NULL :: varchar, FALSE), FALSE);
SELECT config_is_null(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', NULL :: boolean), TRUE);
SELECT config_is_null(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', NULL :: boolean), FALSE);

SELECT show_configkeys_list(
                ARRAY[ make_configkey_bystr(1, 'Dummy_1_CFG')
                     , make_configkey_bystr(2, 'Dummy_2_CFG')
                     , make_configkey_bystr(3, 'Dummy_3_CFG')
                ] :: t_config_key[]
       );
SELECT show_configkeys_list(
                ARRAY[ make_configkey_bystr(1, 'Dummy_1_CFG')
                     , NULL :: t_config_key
                     , make_configkey_bystr(3, 'Dummy_3_CFG')
                ] :: t_config_key[]
       );
SELECT show_configkeys_list(
                ARRAY[ make_configkey_bystr(1, 'Dummy_1_CFG')
                     , make_configkey_null()
                     , make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Болванка_1_КФГ', TRUE)
                ] :: t_config_key[]
       );

SELECT optimized_configkey_isit(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', TRUE));
SELECT optimized_configkey_isit(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', FALSE));
\echo >>>> Must raise exception:
SELECT optimized_configkey_isit(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', NULL :: boolean));
SELECT optimized_configkey_isit(make_configkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(1, 'Болванка_1_КС'))), 'Болванка_1_КФГ', TRUE));
SELECT optimized_configkey_isit(make_configkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(1, 'Болванка_1_КС'))), 'Болванка_1_КФГ', FALSE));
SELECT optimized_configkey_isit(make_configkey(make_confentitykey(make_codekeyl(make_codekey(1, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'Болванка_1_КФГ', TRUE));
SELECT optimized_configkey_isit(make_configkey(make_confentitykey(make_codekeyl(make_codekey(1, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'Болванка_1_КФГ', FALSE));

-- Lookup functions:
\echo >>>>>> no lng error
SELECT optimize_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', TRUE) , TRUE);
SELECT optimize_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', FALSE), TRUE);
\echo >>>> Must raise exception:
SELECT optimize_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', NULL :: boolean), TRUE);
SELECT optimize_configkey(make_configkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'Болванка_1_КФГ', TRUE), TRUE);
\echo >>>>>> not found error
SELECT optimize_configkey(make_configkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'Болванка_1_КС', FALSE), TRUE);
\echo >>>>>> not found error
SELECT optimize_configkey(make_configkey_bystr(1, 'Dummy_1_CFG'), TRUE);
SELECT optimize_configkey(make_configkey_bystr(1, 'Dummy_1_CFG'), FALSE);

\echo >>>>>> no lng error
SELECT optimize_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', TRUE) , FALSE);
SELECT optimize_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', FALSE), FALSE);
\echo >>>> Must raise exception:
SELECT optimize_configkey(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', NULL :: boolean), FALSE);
SELECT optimize_configkey(make_configkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'Болванка_1_КФГ', TRUE), FALSE);
SELECT optimize_configkey(make_configkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'Болванка_1_КС', FALSE), FALSE);

SELECT is_confentity_default(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'));
SELECT is_confentity_default(make_configkey_bystr2('Dummy_1_CE', 'Dummy_3_CFG'));
SELECT is_confentity_default(make_configkey_bystr2('Dummy_2_CE', 'Dummy_1_CFG'));
SELECT is_confentity_default(make_configkey_bystr2('Dummy_2_CE', 'Dummy_2_CFG'));

SELECT read_completeness(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'));
SELECT read_completeness(make_configkey_bystr2('Dummy_2_CE', 'Dummy_2_CFG'));
SELECT read_completeness(make_configkey_bystr2('Dummy_2_CE', 'Dummy_3_CFG'));
\echo >>>>>> not found error
SELECT read_completeness(make_configkey_bystr2('Dummy_3_CE', 'Dummy_3_CFG'));

SELECT read_role__completeness_as_regulator(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'));
SELECT read_role__completeness_as_regulator(make_configkey_bystr2('Dummy_2_CE', 'Dummy_2_CFG'));
SELECT read_role__completeness_as_regulator(make_configkey_bystr2('Dummy_2_CE', 'Dummy_3_CFG'));
\echo >>>>>> not found error
SELECT read_role__completeness_as_regulator(make_configkey_bystr2('Dummy_3_CE', 'Dummy_3_CFG'));

-- Administration functions:
\echo >>>>>> overwrite forbidden
SELECT set_confentity_default(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), FALSE);
SELECT set_confentity_default(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), TRUE);
SELECT clone_config(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'Dummy_1_CFG_clone');
\echo >>>>>> overwrite forbidden
SELECT set_confentity_default(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG_clone'), FALSE);
SELECT set_confentity_default(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG_clone'), TRUE);
SELECT set_confentity_default(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), TRUE);
