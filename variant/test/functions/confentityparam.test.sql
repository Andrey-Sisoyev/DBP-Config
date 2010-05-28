-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- TYPE t_cpvalue_uni AS (
--           type                t_confparam_type
--         , value               varchar
--         , subcfg_ref_param_id varchar
--         , subcfg_ref_usage    t_subconfig_value_linking_read_rule
--         )
-- TYPE t_cparameter_uni AS (
--           param_id                    varchar
--         , type                        t_confparam_type
--         , constraints_array           t_confparam_constraint[]
--         , allow_null_final_value      boolean
--         , use_default_instead_of_null t_confparam_default_usage
--         , subconfentity_code_id       integer
--         , default_value               t_cpvalue_uni
--         )
-- TYPE t_confentityparam_key AS (confentity_key t_confentity_key, param_key varchar, param_key_is_lnged boolean)
-- TYPE t_config_param__short AS (config_id varchar, param_id varchar)


-- Reference functions:
SELECT mk_cpvalue_l('asd', NULL :: integer);
SELECT mk_cpvalue_l(NULL :: varchar, NULL :: integer);

SELECT mk_cpvalue_s('asd', 'asd', 'no_lnk');
SELECT mk_cpvalue_s(NULL :: varchar, 'asd', 'no_lnk');
SELECT mk_cpvalue_s(NULL :: varchar, NULL :: varchar, 'alw_onl_lnk');
SELECT mk_cpvalue_s('asd', 'asd', NULL :: t_subconfig_value_linking_read_rule);

SELECT isconsistent_cpvalue(mk_cpvalue_null());
SELECT isconsistent_cpvalue(mk_cpvalue_l('asd', NULL :: integer));
SELECT isconsistent_cpvalue(mk_cpvalue_l(NULL :: varchar, NULL :: integer));
SELECT isconsistent_cpvalue(mk_cpvalue_s('asd', 'asd', 'no_lnk'));
SELECT isconsistent_cpvalue(mk_cpvalue_s(NULL :: varchar, 'asd', 'no_lnk'));
SELECT isconsistent_cpvalue(mk_cpvalue_s(NULL :: varchar, NULL :: varchar, 'alw_onl_lnk'));
SELECT isconsistent_cpvalue(mk_cpvalue_s('asd', 'asd', NULL :: t_subconfig_value_linking_read_rule));

SELECT isdefined_cpvalue(mk_cpvalue_null());
SELECT isdefined_cpvalue(mk_cpvalue_l('asd', NULL :: integer));
SELECT isdefined_cpvalue(mk_cpvalue_l(NULL :: varchar, NULL :: integer));
SELECT isdefined_cpvalue(mk_cpvalue_s('asd', 'asd', 'no_lnk'));
SELECT isdefined_cpvalue(mk_cpvalue_s(NULL :: varchar, 'asd', 'no_lnk'));
SELECT isdefined_cpvalue(mk_cpvalue_s(NULL :: varchar, NULL :: varchar, 'alw_onl_lnk'));
SELECT isdefined_cpvalue(mk_cpvalue_s('asd', 'asd', NULL :: t_subconfig_value_linking_read_rule));

SELECT isnull_cpvalue(mk_cpvalue_null(), TRUE);
SELECT isnull_cpvalue(mk_cpvalue_l('asd', NULL :: integer), TRUE);
SELECT isnull_cpvalue(mk_cpvalue_l(NULL :: varchar, NULL :: integer), TRUE);
SELECT isnull_cpvalue(mk_cpvalue_s('asd', 'asd', 'no_lnk'), TRUE);
SELECT isnull_cpvalue(mk_cpvalue_s(NULL :: varchar, 'asd', 'no_lnk'), TRUE);
SELECT isnull_cpvalue(mk_cpvalue_s(NULL :: varchar, NULL :: varchar, 'alw_onl_lnk'), TRUE);
SELECT isnull_cpvalue(mk_cpvalue_s('asd', 'asd', NULL :: t_subconfig_value_linking_read_rule), TRUE);

SELECT isnull_cpvalue(mk_cpvalue_null(), FALSE);
SELECT isnull_cpvalue(mk_cpvalue_l('asd', NULL :: integer), FALSE);
SELECT isnull_cpvalue(mk_cpvalue_l(NULL :: varchar, NULL :: integer), FALSE);
SELECT isnull_cpvalue(mk_cpvalue_s('asd', 'asd', 'no_lnk'), FALSE);
SELECT isnull_cpvalue(mk_cpvalue_s(NULL :: varchar, 'asd', 'no_lnk'), FALSE);
SELECT isnull_cpvalue(mk_cpvalue_s(NULL :: varchar, NULL :: varchar, 'alw_onl_lnk'), FALSE);
SELECT isnull_cpvalue(mk_cpvalue_s('asd', 'asd', NULL :: t_subconfig_value_linking_read_rule), FALSE);

SELECT mk_cparameter_uni(
          'param_id'
        , 'subconfig'
        , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
        , TRUE
        , 'par_d'
        , 123
        , 'nonlnged_val'
        , mk_cpvalue_l('asd', NULL :: integer)
        );

SELECT show_confentityparamkey(make_confentityparamkey(make_confentitykey_bystr('Dummy_1_CE'), 'dummy_1_param_1', FALSE));
SELECT show_confentityparamkey(
         make_confentityparamkey(
           make_confentitykey(
             make_codekeyl(
               make_codekey(NULL :: integer, 'rus')
             , make_codekey(NULL :: integer, 'Болванка_1_КС')
           ) )
         , 'болванка_1_парам_1'
         , TRUE
       ) );
SELECT show_confentityparamkey(make_confentityparamkey_null());
SELECT show_confentityparamkey(make_confentityparamkey_bystr(1, 'sdf'));
SELECT show_confentityparamkey(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'));

SELECT confentityparam_is_null(make_confentityparamkey(make_confentitykey_bystr('Dummy_1_CE'), 'dummy_1_param_1', FALSE), FALSE);
SELECT confentityparam_is_null(
         make_confentityparamkey(
           make_confentitykey(
             make_codekeyl(
               make_codekey(NULL :: integer, 'rus')
             , make_codekey(NULL :: integer, 'Болванка_1_КС')
           ) )
         , 'болванка_1_парам_1'
         , TRUE
         )
       , FALSE
       );
SELECT confentityparam_is_null(
         make_confentityparamkey(
           make_confentitykey(
             make_codekeyl(
               make_codekey(NULL :: integer, 'rus')
             , make_codekey(NULL :: integer, NULL :: varchar)
           ) )
         , 'болванка_1_парам_1'
         , TRUE
         )
       , FALSE
       );
SELECT confentityparam_is_null(make_confentityparamkey_null(), FALSE);
SELECT confentityparam_is_null(make_confentityparamkey_bystr(1, 'sdf'), FALSE);
SELECT confentityparam_is_null(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'), FALSE);

SELECT confentityparam_is_null(make_confentityparamkey(make_confentitykey_bystr('Dummy_1_CE'), 'dummy_1_param_1', FALSE), TRUE);
SELECT confentityparam_is_null(
         make_confentityparamkey(
           make_confentitykey(
             make_codekeyl(
               make_codekey(NULL :: integer, 'rus')
             , make_codekey(NULL :: integer, 'Болванка_1_КС')
           ) )
         , 'болванка_1_парам_1'
         , TRUE
         )
       , TRUE
       );
SELECT confentityparam_is_null(
         make_confentityparamkey(
           make_confentitykey(
             make_codekeyl(
               make_codekey(NULL :: integer, 'rus')
             , make_codekey(NULL :: integer, NULL :: varchar)
           ) )
         , 'болванка_1_парам_1'
         , TRUE
         )
       , TRUE
       );
SELECT confentityparam_is_null(make_confentityparamkey_null(), TRUE);
SELECT confentityparam_is_null(make_confentityparamkey_bystr(1, 'sdf'), TRUE);
SELECT confentityparam_is_null(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'), TRUE);

SELECT optimized_confentityparamkey_isit(make_confentityparamkey(make_confentitykey_bystr('Dummy_1_CE'), 'dummy_1_param_1', FALSE));
SELECT optimized_confentityparamkey_isit(
         make_confentityparamkey(
           make_confentitykey(
             make_codekeyl(
               make_codekey(NULL :: integer, 'rus')
             , make_codekey(NULL :: integer, 'Болванка_1_КС')
           ) )
         , 'болванка_1_парам_1'
         , TRUE
       ) );
SELECT optimized_confentityparamkey_isit(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, NULL :: varchar))), 'болванка_1_парам_1', TRUE));
\echo >>>>>> NOT NULL violation error
SELECT optimized_confentityparamkey_isit(make_confentityparamkey_null());
SELECT optimized_confentityparamkey_isit(make_confentityparamkey_bystr(1, 'sdf'));
SELECT optimized_confentityparamkey_isit(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'));


-- Lookup functions:
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'), FALSE));
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'), TRUE));
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey_bystr(1, 'sdf'), FALSE));
\echo >>>>>> param not found error
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey_bystr(1, 'sdf'), TRUE));
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'dummy_1_param_1', FALSE), FALSE));
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'dummy_1_param_1', FALSE), TRUE));
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', TRUE), FALSE));
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', TRUE), TRUE));
\echo >>>>>> no lng error
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey_null(), FALSE));
\echo >>>>>> no lng error
SELECT show_confentityparamkey(optimize_confentityparamkey(make_confentityparamkey_null(), TRUE));

SELECT determine_cparameter(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'));
SELECT determine_cparameter(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_2'));
\echo >>>>>> not found error
SELECT determine_cparameter(make_confentityparamkey_bystr(1, 'sdf'));
SELECT determine_cparameter(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', TRUE));
SELECT determine_cparameter(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_2', TRUE));
\echo >>>>>> no lng error
SELECT determine_cparameter(make_confentityparamkey_null());

SELECT get_params(make_confentitykey_bystr('Dummy_1_CE'));

-- Administration functions:
SELECT confparam_instaniated_isit(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_1'));
SELECT confparam_instaniated_isit(make_confentityparamkey_bystr2('Dummy_1_CE', 'dummy_1_param_2'));

