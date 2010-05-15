-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- TYPE t_cpvalue_final_source AS ENUM ('ce_dflt', 'cp_dflt', 'cpv', 'cp_dflt_il', 'cpv_il', 'null')
-- TYPE t_cparameter_value_uni AS (
--           param_base      t_cparameter_uni
--         , value           t_cpvalue_uni
--         , final_value     varchar
--         , final_value_src t_cpvalue_final_source
--         )
-- TYPE t_configparam_key AS (config_key t_config_key, param_key varchar, param_key_is_lnged boolean)
-- TYPE t_paramvals__short AS (param_id varchar, value t_cpvalue_uni)


-- Reference functions:
\echo >>>>>> type unset error
SELECT mk_cparameter_value(
          mk_cparameter_uni(
                  'param_id'
                , 'subconfig'
                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                , TRUE
                , 'par_d'
                , 123
                , mk_cpvalue_l('asd')
                )
        , mk_cpvalue_l('asd')
        , 'asd'
        , NULL :: t_cpvalue_final_source
        , NULL :: t_confparam_type
        );
\echo >>>>>> types incoherence error
SELECT mk_cparameter_value(
          mk_cparameter_uni(
                  'param_id'
                , 'subconfig'
                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                , TRUE
                , 'par_d'
                , 123
                , mk_cpvalue_l('asd')
                )
        , mk_cpvalue_l('asd')
        , 'asd'
        , NULL :: t_cpvalue_final_source
        , 'leaf'
        );

SELECT mk_cparameter_value(
          mk_cparameter_uni(
                  'param_id'
                , 'leaf'
                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                , TRUE
                , 'par_d'
                , 123
                , mk_cpvalue_l('asd')
                )
        , mk_cpvalue_l('asd')
        , 'asd'
        , NULL :: t_cpvalue_final_source
        , 'leaf'
        );

\echo >>>>>> types incoherence error
SELECT mk_cparameter_value(
          mk_cparameter_uni(
                  'param_id'
                , 'leaf'
                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                , TRUE
                , 'par_d'
                , 123
                , mk_cpvalue_s('asd', 'asd', 'no_lnk')
                )
        , mk_cpvalue_l('asd')
        , 'asd'
        , NULL :: t_cpvalue_final_source
        , 'leaf'
        );

\echo >>>>>> types incoherence error
SELECT mk_cparameter_value(
          mk_cparameter_uni(
                  'param_id'
                , 'leaf'
                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                , TRUE
                , 'par_d'
                , 123
                , mk_cpvalue_l('asd')
                )
        , mk_cpvalue_s('asd', 'asd', 'no_lnk')
        , 'asd'
        , NULL :: t_cpvalue_final_source
        , 'leaf'
        );

\echo >>>>>> types incoherence error
SELECT mk_cparameter_value(
          mk_cparameter_uni(
                  'param_id'
                , 'leaf'
                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                , TRUE
                , 'par_d'
                , 123
                , mk_cpvalue_l('asd')
                )
        , mk_cpvalue_l('asd')
        , 'asd'
        , NULL :: t_cpvalue_final_source
        , 'subconfig'
        );
\echo >>>>>> types incoherence error
SELECT mk_cparameter_value(
          mk_cparameter_uni(
                  'param_id'
                , 'subconfig'
                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                , TRUE
                , 'par_d'
                , 123
                , mk_cpvalue_l('asd')
                )
        , mk_cpvalue_l('asd')
        , 'asd'
        , NULL :: t_cpvalue_final_source
        , 'leaf'
        );

-------------

SELECT get_param_from_list(
                 ARRAY[ mk_cparameter_value(
                          mk_cparameter_uni(
                                  'param_id_1'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                                , TRUE
                                , 'par_d'
                                , 123
                                , mk_cpvalue_l('asd')
                                )
                        , mk_cpvalue_l('asd')
                        , 'asd'
                        , NULL :: t_cpvalue_final_source
                        , 'leaf'
                        )
                      , mk_cparameter_value(
                          mk_cparameter_uni(
                                  'param_id_2'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                                , TRUE
                                , 'par_d'
                                , 123
                                , mk_cpvalue_l('asd')
                                )
                        , mk_cpvalue_l('asd')
                        , 'asd'
                        , NULL :: t_cpvalue_final_source
                        , 'leaf'
                        )
                ] :: t_cparameter_value_uni[]
              , 'param_id_2'
              );

\echo >>>>>> probably error
SELECT get_param_from_list(
                 ARRAY[ mk_cparameter_value(
                          mk_cparameter_uni(
                                  'param_id_1'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                                , TRUE
                                , 'par_d'
                                , 123
                                , mk_cpvalue_l('asd')
                                )
                        , mk_cpvalue_l('asd')
                        , 'asd'
                        , NULL :: t_cpvalue_final_source
                        , 'leaf'
                        )
                      , mk_cparameter_value(
                          mk_cparameter_uni(
                                  'param_id_2'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                                , TRUE
                                , 'par_d'
                                , 123
                                , mk_cpvalue_l('asd')
                                )
                        , mk_cpvalue_l('asd')
                        , 'asd'
                        , NULL :: t_cpvalue_final_source
                        , 'leaf'
                        )
                ] :: t_cparameter_value_uni[]
              , 'param_id_3');

------------------

SELECT show_configparamkey(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE));
SELECT show_configparamkey(make_configparamkey_null());
SELECT show_configparamkey(make_configparamkey_bystr2(1, 'Dummy_1_CFG', 'dummy_1_param_1'));
SELECT show_configparamkey(make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1'));

----------------

SELECT show_configparamkey(
              make_cop_from_cep(
                make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', TRUE)
              , 'Болванка_1_КФГ'
              , TRUE
              )
       );
SELECT show_confentityparamkey(
          make_cep_from_cop(
              make_cop_from_cep(
                make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', TRUE)
              , 'Dummy_1_CFG'
              , FALSE
              )
          )
       );

SELECT show_configparamkey(
              make_cop_from_cep(
                make_confentityparamkey_null()
              , 'Dummy_1_CFG'
              , FALSE
              )
       );
SELECT show_confentityparamkey(
          make_cep_from_cop(
              make_configparamkey_null()
          )
       );

---------------------

SELECT configparamkey_is_null(
                make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE)
              , FALSE
              );
SELECT configparamkey_is_null(make_configparamkey_null(), FALSE);
SELECT configparamkey_is_null(make_configparamkey(make_configkey_bystr(1, 'Dummy_1_CFG'), 'dummy_1_param_1', NULL :: boolean), FALSE);
SELECT configparamkey_is_null(make_configparamkey_bystr2(1, 'Dummy_1_CFG', NULL :: varchar), FALSE);


SELECT configparamkey_is_null(
                make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE)
              , TRUE
              );
SELECT configparamkey_is_null(make_configparamkey_null(), TRUE);
SELECT configparamkey_is_null(make_configparamkey(make_configkey_bystr(1, 'Dummy_1_CFG'), 'dummy_1_param_1', NULL :: boolean), TRUE);
SELECT configparamkey_is_null(make_configparamkey_bystr2(1, 'Dummy_1_CFG', NULL :: varchar), TRUE);

SELECT optimized_cop_isit(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE));
\echo >>>>>> param_id_lnged NOT NULL error
SELECT optimized_cop_isit(make_configparamkey_null());
\echo >>>>>> param_id_lnged NOT NULL error
SELECT optimized_cop_isit(make_configparamkey(make_configkey_bystr(1, 'Dummy_1_CFG'), 'dummy_1_param_1', NULL :: boolean));
\echo >>>>>> param_id NOT NULL error
SELECT optimized_cop_isit(make_configparamkey_bystr2(1, 'Dummy_1_CFG', NULL :: varchar));

-- Lookup functions:
SELECT show_configparamkey(optimize_configparamkey(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE)));
\echo >>>>>> param_id_lnged NOT NULL error
SELECT show_configparamkey(optimize_configparamkey(make_configparamkey_null()));
SELECT show_configparamkey(
         optimize_configparamkey(
           make_cop_from_cep(
             make_confentityparamkey(
               make_confentitykey(
                 make_codekeyl(
                   make_codekey(NULL :: integer, 'rus')
                 , make_codekey(NULL :: integer, 'Болванка_1_КС')
               ) )
             , 'болванка_1_парам_1'
             , TRUE
             )
           , 'Болванка_1_КФГ'
           , TRUE
       ) ) );
SELECT show_configparamkey(optimize_configparamkey(make_cop_from_cep(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', FALSE), 'Болванка_1_КФГ', TRUE)));
SELECT show_configparamkey(optimize_configparamkey(make_cop_from_cep(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'dummy_1_param_1', FALSE), 'Dummy_1_CFG', FALSE)));
\echo >>>>>> param not found error
SELECT show_configparamkey(optimize_configparamkey(make_cop_from_cep(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'dummy_1_param_1', TRUE), 'Dummy_1_CFG', FALSE)));

------------------------

SELECT determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE));
SELECT determine_cvalue_of_cop(make_cop_from_cep(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', TRUE), 'Болванка_1_КФГ', TRUE));
SELECT determine_cvalue_of_cop(make_cop_from_cep(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_1', TRUE), 'Dummy_1_CFG', FALSE));

------------------------

SELECT determine_value_of_cvalue(
                TRUE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_11', FALSE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );
\echo >>>>>> null not allowed in param_11 error
SELECT determine_value_of_cvalue(
                FALSE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_11', FALSE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );
SELECT determine_value_of_cvalue(
                TRUE
              , determine_cvalue_of_cop(make_cop_from_cep(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_11', TRUE), 'Болванка_1_КФГ', TRUE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );
\echo >>>>>> null not allowed in param_11 error
SELECT determine_value_of_cvalue(
                FALSE
              , determine_cvalue_of_cop(make_cop_from_cep(make_confentityparamkey(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'rus'), make_codekey(NULL :: integer, 'Болванка_1_КС'))), 'болванка_1_парам_11', TRUE), 'Болванка_1_КФГ', TRUE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );
SELECT determine_value_of_cvalue(
                TRUE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );
SELECT determine_value_of_cvalue(
                FALSE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_1', FALSE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );
SELECT determine_value_of_cvalue(
                TRUE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_2', FALSE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );
SELECT determine_value_of_cvalue(
                FALSE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG'), 'dummy_1_param_2', FALSE))
              , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              );

------------------------------------

SELECT get_paramvalues(
          TRUE
        , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
        );
\echo >>>>>> null not allowed in param_11 error
SELECT get_paramvalues(
          FALSE
        , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
        );


-- Administration functions:

\echo >>>>>> wrong value type error
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , mk_cpvalue_l('asd')
              , 10
              );
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , mk_cpvalue_s('Dummy_2_CFG_2', NULL :: varchar, 'no_lnk')
              , 10
              );
\echo >>>>>> overwrite restricted error
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , mk_cpvalue_s('Dummy_2_CFG', NULL :: varchar, 'no_lnk')
              , 10
              );
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , mk_cpvalue_s('Dummy_2_CFG', NULL :: varchar, 'no_lnk')
              , 1
              );
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , mk_cpvalue_s('Dummy_2_CFG_2', NULL :: varchar, 'no_lnk')
              , 1
              );
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_11')
              , mk_cpvalue_s('Dummy_2_CFG_2', NULL :: varchar, 'no_lnk')
              , 1
              );

SELECT get_paramvalues(
          FALSE
        , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
        );

SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , mk_cpvalue_s('Dummy_2_CFG', NULL :: varchar, 'no_lnk')
              , 1
              );
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_11')
              , mk_cpvalue_s(NULL :: varchar, 'dummy_1_param_1', 'alw_onl_lnk')
              , 1
              );

SELECT get_paramvalues(
          FALSE
        , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
        );

\echo >>>>>> probably error
SELECT set_confparam_values_set(
                make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              , ARRAY[ ROW( 'dummy_1_param_1'
                          , mk_cpvalue_s(NULL :: varchar, 'dummy_1_param_11', 'whn_vnull_lnk')
                          )
                     , ROW( 'dummy_1_param_11'
                          , mk_cpvalue_s(NULL :: varchar, 'dummy_1_param_1', 'whn_vnull_lnk')
                          )
                     , ROW( 'dummy_1_param_2'
                          , mk_cpvalue_l('asfsfsdfsdf1111111111')
                          )
                ] :: t_paramvals__short[]
              , 1
              );
\echo >>>>>> IL cycle error
SELECT get_paramvalues(
          FALSE
        , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
        );

SELECT set_confparam_values_set(
                make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              , ARRAY[ ROW( 'dummy_1_param_11'
                          , mk_cpvalue_s('Dummy_2_CFG_2', 'dummy_1_param_1', 'whn_vnull_lnk')
                          )
                     , ROW( 'dummy_1_param_2'
                          , mk_cpvalue_l('2222222222222222sdfsd2222')
                          )
                ] :: t_paramvals__short[]
              , 1
              );
SELECT get_paramvalues(
          FALSE
        , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
        );

----------------

SELECT unset_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , TRUE
              );
SELECT unset_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_2')
              , TRUE
              );

SELECT get_paramvalues(
          FALSE
        , make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
        );

SELECT unset_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , TRUE
              );
SELECT unset_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_2')
              , TRUE
              );

\echo >>>>>> value doesnt exist error
SELECT unset_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_1')
              , FALSE
              );

\echo >>>>>> value doesnt exist error
SELECT unset_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_2')
              , FALSE
              );

\echo >>>>>> param doesnt exist error
SELECT unset_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_234')
              , FALSE
              );

--------------

\echo >>>>>>>>>>>> MEGACHECKs <<<<<<<<<<<<<<

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public;
\set ECHO none

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__test_errorcases(par_tc_type integer) RETURNS varchar AS $$
DECLARE
        i integer;
        l integer;
        t_cv RECORD;
        oth_errorred integer := 0;
        nn_errorred  integer := 0;
        not_errorred integer := 0;
        report varchar;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        CASE par_tc_type
            WHEN 1 THEN
                FOR t_cv IN
                        SELECT *
                        FROM test1__cparameters_values as t
                        WHERE t.testcase_id = 1
                          AND t.error
                LOOP
                        BEGIN
                            PERFORM determine_finvalue_by_cop(
                                        FALSE
                                      , make_configparamkey_bystr3(
                                                t_cv.super_ce_1, t_cv.super_ce_1 || '__CFG_0'
                                              , LOWER(t_cv.super_ce_1 || '__' || t_cv.sub_ce_1)
                                              )
                                      );
                            not_errorred:= not_errorred + 1;
                            RAISE NOTICE 'Failed to raise exception testcase of type 1, ID: %.', t_cv.id;
                        EXCEPTION
                            WHEN null_value_not_allowed THEN
                                nn_errorred:= nn_errorred + 1;
                                -- RAISE NOTICE 'Raised "null_value_not_allowed" exception testcase of type 1, ID: %.', t_cv.id;
                            -- WHEN OTHERS THEN
                            --     oth_errorred:= oth_errorred + 1;
                            --     RAISE NOTICE 'Raised unexpected exception testcase of type 1, ID: %.', t_cv.id;
                        END;
                END LOOP;
            WHEN 4 THEN
                FOR t_cv IN
                        SELECT *
                        FROM test4__cparameters_values as t
                        WHERE t.testcase_id = 301
                          AND t.error
                LOOP
                        BEGIN
                            PERFORM determine_finvalue_by_cop(
                                        FALSE
                                      , make_configparamkey_bystr3(
                                                'TC4_301', 'TC4_301_CFG'
                                              , 'par_' || t_cv.id
                                              )
                                      );
                            not_errorred:= not_errorred + 1;
                            RAISE NOTICE 'Failed to raise exception testcase of type 4, ID: %.', t_cv.id;
                        EXCEPTION
                            WHEN null_value_not_allowed THEN
                                nn_errorred:= nn_errorred + 1;
                            -- WHEN OTHERS THEN
                            --     oth_errorred:= oth_errorred + 1;
                            --     RAISE NOTICE 'Raised unexpected exception testcase of type 4, ID: %.', t_cv.id;
                        END;
                END LOOP;
        END CASE;

        report:= 'Failed to raise exception: ' || not_errorred || E'\nRaised "null_value_not_allowed": ' || nn_errorred || E'\nRaised other exception: ' || oth_errorred || E'\nSum: ' || (oth_errorred + not_errorred + nn_errorred);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN report;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION pkg_<<$app_name$>>__test_errorcases(par_tc_type integer) TO user_<<$app_name$>>_data_admin;

\c <<$db_name$>> user_<<$app_name$>>_data_admin

SET search_path TO sch_<<$app_name$>>, public;
\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC1.#1 <<<<<<<<<<<<<<

SELECT t.id
     , CASE (t.r1).final_value_src IS DISTINCT FROM final_value_source__tobe
           WHEN TRUE THEN '--ERROR--ERROR--ERROR--ERROR--ERROR--ERROR--' || ROW(t.*)
           ELSE 'Ok!'
       END AS finval_src_test
     , CASE t.final_value_persists
           WHEN TRUE THEN
               CASE (t.r1).final_value IS NULL
                   WHEN TRUE THEN '--ERROR--ERROR--ERROR--ERROR--ERROR--ERROR--' || ROW(t.*)
                   ELSE 'Ok!'
               END
           ELSE 'Ok!'
       END AS finval_test
FROM ( SELECT determine_finvalue_by_cop(
                        TRUE
                      , make_configparamkey_bystr3(
                                t_cv.super_ce_1, t_cv.super_ce_1 || '__CFG_0'
                              , LOWER(t_cv.super_ce_1) || '__' || LOWER(t_cv.sub_ce_1)
                              )
                      ) as r1
            , '||||||||||'
            , t_cv.final_value_source AS final_value_source__tobe
            , t_cv.final_value_persists
            , t_cv.error
            , t_cv.testcase_id
            , t_cv.super_ce_1
            , t_cv.sub_ce_1
            , t_cv.id
       FROM test1__cparameters_values AS t_cv
       WHERE t_cv.testcase_id = 1
     ) AS t;

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC1.#2 <<<<<<<<<<<<<<

SELECT pkg_<<$app_name$>>__test_errorcases(1);

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC2: N/A

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC3 <<<<<<<<<<<<<<

SELECT determine_value_of_cvalue(
                FALSE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG'), 'par_link_chain_terminat', FALSE))
              , make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG')
              );
SELECT determine_value_of_cvalue(
                FALSE
              , determine_cvalue_of_cop(make_configparamkey(make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG'), 'par_first_lnk', FALSE))
              , make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG')
              );

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC4.#1 <<<<<<<<<<<<<<

SELECT t.id
     , CASE (t.r1).final_value_src IS DISTINCT FROM final_value_source__tobe
           WHEN TRUE THEN '--ERROR--ERROR--ERROR--ERROR--ERROR--ERROR--' || ROW(t.*)
           ELSE 'Ok!'
       END AS finval_src_test
     , CASE t.final_value_persists
           WHEN TRUE THEN
               CASE (t.r1).final_value IS NULL
                   WHEN TRUE THEN '--ERROR--ERROR--ERROR--ERROR--ERROR--ERROR--' || ROW(t.*)
                   ELSE 'Ok!'
               END
           ELSE 'Ok!'
       END AS finval_test
FROM ( SELECT determine_finvalue_by_cop(
                        TRUE
                      , make_configparamkey_bystr3(
                                'TC4_301', 'TC4_301_CFG'
                              , 'par_' || t_cv.id
                              )
                      ) AS r1
            , '||||||||||'
            , t_cv.final_value_source AS final_value_source__tobe
            , t_cv.final_value_persists
            , t_cv.error
            , t_cv.testcase_id
            , t_cv.id
       FROM test4__cparameters_values AS t_cv
       WHERE t_cv.testcase_id = 301
     ) AS t;

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC4.#2 <<<<<<<<<<<<<<

SELECT pkg_<<$app_name$>>__test_errorcases(4);

-----------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

DROP FUNCTION sch_<<$app_name$>>.pkg_<<$app_name$>>__test_errorcases(par_tc_type integer);

\c <<$db_name$>> user_<<$app_name$>>_data_admin
SET search_path TO sch_<<$app_name$>>, public;
\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);