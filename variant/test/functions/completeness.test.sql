-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- TYPE t_thorough_report_warning_mode AS ENUM ('WHEN LOSING COMPLETENESS', 'ALWAYS', 'NEVER')
-- TYPE t_completeness_check_row AS (
--         confentity_code_id integer
--       , config_id          varchar
--       , param_value        t_cparameter_value_uni

--       , cc_null_cnstr_passed_ok    boolean
--       , cc_cnstr_array_failure_idx integer
--       , cc_subconfig_is_complete   t_config_completeness_check_result
--       )
-- TYPE t_completeness_check_file (
--         cc_rows_set          t_completeness_check_row[]
--       , nn_cnstr_viol_count  integer
--       , cc_cnstr_viol_count  integer
--       , subcfg_incompl_count integer
--       , errors_report        varchar
--       , fully_checked_isit   boolean
--       , is_complete          boolean
--       )


-- Reference functions:
SELECT completeness_interpretation('th_chk_V');
SELECT completeness_interpretation('th_chk_X');
SELECT completeness_interpretation('li_chk_V');
SELECT completeness_interpretation('li_chk_X');
SELECT completeness_interpretation('nf_X');
SELECT completeness_interpretation('cy_X');
SELECT completeness_interpretation('le_V');

SELECT show_completeness_check_result('th_chk_V');
SELECT show_completeness_check_result('th_chk_X');
SELECT show_completeness_check_result('li_chk_V');
SELECT show_completeness_check_result('li_chk_X');
SELECT show_completeness_check_result('nf_X');
SELECT show_completeness_check_result('cy_X');
SELECT show_completeness_check_result('le_V');

SELECT mk_completeness_precheck_row(
        111
      , 'cfg'
      , NULL :: t_cparameter_value_uni
      , FALSE
      , 1
      , 'nf_X'
      );

SELECT form_cc_report(
                make_configkey_bystr(111, 'cfg1')
              , ARRAY[ mk_completeness_precheck_row(111, 'cfg1', NULL :: t_cparameter_value_uni, TRUE, -1, 'th_chk_V')
                     , mk_completeness_precheck_row(112, 'cfg2', NULL :: t_cparameter_value_uni, NULL :: boolean, -1, 'th_chk_V')
                     , mk_completeness_precheck_row(113, 'cfg3', NULL :: t_cparameter_value_uni, TRUE, NULL :: integer, 'th_chk_V')
                     , mk_completeness_precheck_row(114, 'cfg4', NULL :: t_cparameter_value_uni, TRUE, -1, NULL :: t_config_completeness_check_result)
                     , mk_completeness_precheck_row(115, 'cfg5', NULL :: t_cparameter_value_uni, NULL :: boolean, NULL :: integer, NULL :: t_config_completeness_check_result)
                     , mk_completeness_precheck_row(116, 'cfg6', NULL :: t_cparameter_value_uni, FALSE, -1, 'th_chk_V')
                     , mk_completeness_precheck_row(117, 'cfg7', NULL :: t_cparameter_value_uni, TRUE, 11, 'th_chk_V')
                     , mk_completeness_precheck_row(118, 'cfg8', NULL :: t_cparameter_value_uni, TRUE, -1, 'cy_X')
                ] :: t_completeness_check_row[]
       );

-- Analytic functions:
SELECT cc_null_check(
           mk_completeness_precheck_row(
                get_confentity_id('TC4_301')
              , 'TC4_301_CFG'
              , determine_finvalue_by_cop(
                        TRUE
                      , make_configparamkey_bystr3(
                                'TC4_301', 'TC4_301_CFG'
                              , x.a
                              )
                      )
              , NULL :: boolean
              , NULL :: integer
              , NULL :: t_config_completeness_check_result
              )
       )
FROM unnest(ARRAY['par_7', 'par_8', 'par_9'] :: varchar[]) AS x(a);

---------------

SELECT cc_cnstr_arr_check(
           mk_completeness_precheck_row(
                get_confentity_id('TC4_301')
              , 'TC4_301_CFG'
              , determine_finvalue_by_cop(
                        TRUE
                      , make_configparamkey_bystr3(
                                'TC4_301', 'TC4_301_CFG'
                              , x.a
                              )
                      )
              , NULL :: boolean
              , NULL :: integer
              , NULL :: t_config_completeness_check_result
              )
       )
FROM unnest(ARRAY['par_5', 'par_4', 'par_7', 'par_13', 'par_14', 'par_15'] :: varchar[]) AS x(a);

-- cc_isit(par_cc_rows t_completeness_check_row[])


-- Lookup functions:
-------------

SELECT * FROM unnest(get_paramvalues_cc(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'))) AS a;

-------------

SELECT y.b AS thorough_mode
     , cc_subcfg_compl_check(ROW(x.*) :: t_completeness_check_row, y.b, 'ALWAYS')
FROM unnest(get_paramvalues_cc(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'))) AS x
   , unnest(ARRAY[0,1,2,3] :: integer[]) y(b)
ORDER BY thorough_mode;

SELECT y.b AS thorough_mode
     , cc_subcfg_compl_check(ROW(x.*) :: t_completeness_check_row, y.b, 'ALWAYS')
FROM unnest(get_paramvalues_cc(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_incor'))) AS x
   , unnest(ARRAY[0,1,2,3] :: integer[]) y(b)
ORDER BY thorough_mode;


-- Administration functions:
SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> Won't succeed - subconfigs are incorrect
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'ALWAYS', 111);

\echo NOTICE >>>>>> Won't succeed - subconfigs are incorrect
\echo NOTICE >>>>>> Deeper walking
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 3, 'ALWAYS', 111);

\echo NOTICE >>>>>> Won't succeed - subconfigs are incorrect
\echo NOTICE >>>>>> Less reporting
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'WHEN LOSING COMPLETENESS', 111);

\echo NOTICE >>>>>> Won't succeed - subconfigs are incorrect
\echo NOTICE >>>>>> Deeper walking
\echo NOTICE >>>>>> Less reporting
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 3, 'WHEN LOSING COMPLETENESS', 111);

\echo NOTICE >>>>>> Won't succeed - subconfigs are incorrect
\echo NOTICE >>>>>> No reporting
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'NEVER', 111);

\echo NOTICE >>>>>> Won't succeed - subconfigs are incorrect
\echo NOTICE >>>>>> Deeper walking
\echo NOTICE >>>>>> No reporting
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 3, 'NEVER', 111);

\echo NOTICE >>>>>> -------------------------------------------
\echo NOTICE >>>>>> -------------------------------------------
\echo NOTICE >>>>>> Changing parameters to correct values

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> Won't succeed - subconfigs are incorrect
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'ALWAYS', 111);

\echo NOTICE >>>>>> --- NEXT ITERATION

SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')
              , ARRAY[ ROW( 'a_f', mk_cpvalue_s('TC5_F_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     , ROW( 'a_e', mk_cpvalue_s('TC5_E_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              );

\echo NOTICE >>>>>> Still won't succeed - subSUBconfigs are incorrect
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'ALWAYS', 111);

\echo NOTICE >>>>>> --- NEXT ITERATION

SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')
              , ARRAY[ ROW( 'e_g', mk_cpvalue_s('TC5_G_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              )
     , set_confparam_values_set(
                make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')
              , ARRAY[ ROW( 'f_g', mk_cpvalue_s('TC5_G_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              );

\echo NOTICE >>>>>> Current and subs are all correct - must be complete
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'ALWAYS', 111);

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION

SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')
              , ARRAY[ ROW( 'b_a', mk_cpvalue_s('TC5_A_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              )
     , set_confparam_values_set(
                make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')
              , ARRAY[ ROW( 'c_a', mk_cpvalue_s('TC5_A_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              )
     , set_confparam_values_set(
                make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')
              , ARRAY[ ROW( 'd_b', mk_cpvalue_s('TC5_B_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     , ROW( 'd_c', mk_cpvalue_s('TC5_C_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              );

\echo NOTICE >>>>>> C must be complete, B still refers incorrect H
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'ALWAYS', 111);

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION

SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')
              , ARRAY[ ROW( 'b_h', mk_cpvalue_s('TC5_H_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              )
     , set_confparam_values_set(
                make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')
              , ARRAY[ ROW( 'i_f', mk_cpvalue_s('TC5_F_401_CFG_cor', NULL :: varchar, 'no_lnk'))
                     ] :: t_paramvals__short[]
              , 1
              )
     ;

\echo NOTICE >>>>>> B still refers correct H, but H isn't checked to become complete
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'ALWAYS', 111);

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION

SELECT try_to_complete_config(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor'));

\echo NOTICE >>>>>> Now everyone (except for I) must be complete
SELECT config_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor'), 2, 'ALWAYS', 111);

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION
\echo NOTICE >>>>>> Let's peek the result for completeness check of I
SELECT config_is_complete(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor'), 3, 'ALWAYS');

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- LAST ITERATION
SELECT config_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor'), 3, 'ALWAYS', 111);

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> ------------------------------------------
\echo NOTICE >>>>>> Let's test some triggers

UPDATE configurations AS c SET completeness_as_regulator = 'CHECK SET'
WHERE (confentity_code_id = get_confentity_id('TC5_A_401') AND configuration_id = 'TC5_A_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_B_401') AND configuration_id = 'TC5_B_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_C_401') AND configuration_id = 'TC5_C_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_D_401') AND configuration_id = 'TC5_D_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_E_401') AND configuration_id = 'TC5_E_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_F_401') AND configuration_id = 'TC5_F_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_G_401') AND configuration_id = 'TC5_G_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_H_401') AND configuration_id = 'TC5_H_401_CFG_cor')
   OR (confentity_code_id = get_confentity_id('TC5_I_401') AND configuration_id = 'TC5_I_401_CFG_cor');

UPDATE configurations AS c SET completeness_as_regulator = 'RESTRICT'
WHERE (confentity_code_id = get_confentity_id('TC5_D_401') AND configuration_id = 'TC5_D_401_CFG_cor');

\echo NOTICE >>>>>> This must make no change !!!
SELECT uncomplete_cfg(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor'));

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION

\echo NOTICE >>>>>> This must fail!!!

SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')
              , ARRAY[ ROW( 'h_1', mk_cpvalue_l('incorrect value'))
                     ] :: t_paramvals__short[]
              , 1
              );

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION

UPDATE configurations AS c SET completeness_as_regulator = 'CHECK SET'
WHERE (confentity_code_id = get_confentity_id('TC5_D_401') AND configuration_id = 'TC5_D_401_CFG_cor');

\echo NOTICE >>>>>> H, B and D must become incomplete automatically.
SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')
              , ARRAY[ ROW( 'h_1', mk_cpvalue_l('incorrect value'))
                     ] :: t_paramvals__short[]
              , 1
              );

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION

UPDATE configurations AS c SET completeness_as_regulator = 'STRICT CHECK'
WHERE (confentity_code_id = get_confentity_id('TC5_D_401') AND configuration_id = 'TC5_D_401_CFG_cor');

SELECT set_confparam_values_set(
                make_configkey_bystr2('Configuration management system setup', 'CMSS config #1')
              , ARRAY[ ROW( 'when to check completeness', mk_cpvalue_l('ALWAYS'))
                     ] :: t_paramvals__short[]
              , 1
              );

\echo NOTICE >>>>>> Thist must fail.
SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')
              , ARRAY[ ROW( 'h_1', mk_cpvalue_l('incorrect value 2'))
                     ] :: t_paramvals__short[]
              , 1
              );

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

\echo NOTICE >>>>>> --- NEXT ITERATION

\echo NOTICE >>>>>> H, B and D must become complete again automatically.
SELECT set_confparam_values_set(
                make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')
              , ARRAY[ ROW( 'h_1', mk_cpvalue_l('correct value'))
                     ] :: t_paramvals__short[]
              , 1
              );

SELECT read_completeness(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')) AS a
     , read_completeness(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')) AS b
     , read_completeness(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')) AS c
     , read_completeness(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')) AS d
     , read_completeness(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')) AS e
     , read_completeness(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')) AS f
     , read_completeness(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')) AS g
     , read_completeness(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')) AS h
     , read_completeness(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')) AS i
     ;

SELECT set_confparam_values_set(
                make_configkey_bystr2('Configuration management system setup', 'CMSS config #1')
              , ARRAY[ ROW( 'when to check completeness', mk_cpvalue_l('FOR COMPLETE ONLY'))
                     ] :: t_paramvals__short[]
              , 1
              );