-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE: Functions to create and then cleanup test cases.
\echo


CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_dummies() RETURNS integer AS $$
DECLARE rows_cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('Dummy_1_CE'), TRUE, FALSE)
              , delete_confentity(TRUE, make_confentitykey_bystr('Dummy_2_CE'), TRUE, FALSE);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

---------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_dummies() RETURNS integer AS $$
DECLARE rows_cnt integer;
        dummy_1_ce_id integer;
        dummy_2_ce_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_dummies();

        SELECT new_confentity_w_params(
                        'Dummy_1_CE'
                      , ARRAY[] :: t_cparameter_uni[]
                      )
             , new_confentity_w_params(
                        'Dummy_2_CE'
                      , ARRAY[] :: t_cparameter_uni[]
                      )
        INTO dummy_1_ce_id, dummy_2_ce_id;

        PERFORM new_config(
                    FALSE
                  , make_confentitykey_byid(dummy_1_ce_id)
                  , 'Dummy_1_CFG'
                  )
              , new_config(
                    FALSE
                  , make_confentitykey_byid(dummy_1_ce_id)
                  , 'Dummy_1_CFG_2'
                  )
              , new_config(
                    FALSE
                  , make_confentitykey_byid(dummy_2_ce_id)
                  , 'Dummy_2_CFG'
                  )
              , new_config(
                    FALSE
                  , make_confentitykey_byid(dummy_2_ce_id)
                  , 'Dummy_2_CFG_2'
                  );

        PERFORM set_confentity_default(make_configkey(make_confentitykey_bystr('Dummy_1_CE'), 'Dummy_1_CFG', FALSE), FALSE);
        PERFORM add_confentity_names(
                          make_confentitykey_bystr('Dummy_1_CE')
                        , ARRAY[
                             mk_name_construction_input(
                                    make_codekeyl_bystr('eng')     -- lng
                                  , 'Dummy_1_CE__eng'              -- languaged name
                                  , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                                  , 'Dummy_1_CE__eng description'
                                )
                           , mk_name_construction_input(
                                    make_codekeyl_bystr('rus')     -- lng
                                  , 'Болванка_1_КС'                -- languaged name
                                  , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                                  , 'Описание Болванка_1_КС'
                                )
                          ] :: name_construction_input[]
                );
        PERFORM add_config_names(
                          make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
                        , ARRAY[
                             mk_name_construction_input(
                                    make_codekeyl_bystr('eng')     -- lng
                                  , 'Dummy_1_CFG__eng'             -- languaged name
                                  , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                                  , 'Dummy_1_CFG__eng description'
                                )
                           , mk_name_construction_input(
                                    make_codekeyl_bystr('rus')     -- lng
                                  , 'Болванка_1_КФГ'               -- languaged name
                                  , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                                  , 'Описание Болванка_1_КФГ'
                                )
                          ] :: name_construction_input[]
                        );

        PERFORM add_confparams(
                  make_confentitykey_byid(dummy_1_ce_id)
                , ARRAY[ mk_cparameter_uni(
                                  'dummy_1_param_1'
                                , 'subconfig'
                                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                                , TRUE
                                , 'par_d'
                                , dummy_2_ce_id
                                , mk_cpvalue_s(
                                        'Dummy_2_CFG'
                                      , NULL :: varchar
                                      , 'no_lnk'
                                  )
                                )
                       , mk_cparameter_uni(
                                  'dummy_1_param_2'
                                , 'leaf'
                                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                                , TRUE
                                , 'par_d'
                                , NULL :: integer
                                , mk_cpvalue_l('Yo!')
                                )
                       , mk_cparameter_uni(
                                  'dummy_1_param_11'
                                , 'subconfig'
                                , ARRAY[ mk_confparam_constraint('TRUE') ] :: t_confparam_constraint[]
                                , FALSE
                                , 'par_d'
                                , dummy_2_ce_id
                                , mk_cpvalue_null()
                                )
                  ] :: t_cparameter_uni[]
                , TRUE
                );

        PERFORM add_confparam_names(
                  make_confentityparamkey(make_confentitykey_bystr('Dummy_1_CE'), 'dummy_1_param_1', FALSE)
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'dummy_1_param_1__eng'         -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'dummy_1_param_1__eng description'
                          )
                       , mk_name_construction_input(
                            make_codekeyl_bystr('rus')     -- lng
                          , 'болванка_1_парам_1'           -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'болванка_1_парам_1 описание'
                          )
                       ] :: name_construction_input[]
                )
              , add_confparam_names(
                  make_confentityparamkey(make_confentitykey_bystr('Dummy_1_CE'), 'dummy_1_param_2', FALSE)
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'dummy_1_param_2__eng'         -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'dummy_1_param_2__eng description'
                          )
                       , mk_name_construction_input(
                            make_codekeyl_bystr('rus')     -- lng
                          , 'болванка_1_парам_2'           -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'болванка_1_парам_2 описание'
                          )
                       ] :: name_construction_input[]
                )
              , add_confparam_names(
                  make_confentityparamkey(make_confentitykey_bystr('Dummy_1_CE'), 'dummy_1_param_11', FALSE)
                , ARRAY[ mk_name_construction_input(
                            make_codekeyl_bystr('eng')     -- lng
                          , 'dummy_1_param_11__eng'        -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'dummy_1_param_11__eng description'
                          )
                       , mk_name_construction_input(
                            make_codekeyl_bystr('rus')     -- lng
                          , 'болванка_1_парам_11'          -- languaged name
                          , make_codekeyl_null()           -- nameable entity (dont confuse with configurable entity) (NULL refers to default)
                          , 'болванка_1_парам_11 описание'
                          )
                       ] :: name_construction_input[]
                );

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------
-- type 1 -------------------------------------------------
-----------------------------------------------------------

CREATE TABLE test1__cparameters_values (
        testcase_id        integer NOT NULL CHECK (testcase_id > 0 AND testcase_id < 100)
      , super_ce_1         varchar NOT NULL
      , sub_ce_1           varchar NOT NULL
      , super_ce_2         varchar NOT NULL
      , sub_ce_2           varchar NOT NULL
      , id                 integer NOT NULL

      , final_null_allowed            boolean NOT NULL
      , use_dflt                      t_confparam_default_usage NOT NULL
      , subconfentity_dflt_persists   boolean NOT NULL
      , refed_param_has_value         boolean NOT NULL
      , param_lnk_usage               t_subconfig_value_linking_read_rule NOT NULL
      , param_dflt_value_persistance  boolean NOT NULL
      , param_dflt_lnk_persistance    boolean NOT NULL
      , value_lnk_usage	   t_subconfig_value_linking_read_rule NOT NULL
      , value_persistance  boolean NOT NULL
      , lnk_persistance	   boolean     NULL
      , value_level_value_source      t_cpvalue_final_source NOT NULL
      , param_level_value_source      t_cpvalue_final_source NOT NULL
      , confentity_level_value_source t_cpvalue_final_source NOT NULL
      , final_value_source            t_cpvalue_final_source NOT NULL
      , final_value_persists          boolean NOT NULL
      , error                         boolean NOT NULL
      , PRIMARY KEY(testcase_id, id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test1__cparameters_values TO user_<<$app_name$>>_data_admin;

-----------------------------------------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_testcases_of_t1(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_A0'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_A1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_A2'), TRUE, FALSE);

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr(t_cv.super_ce_1), TRUE, FALSE)
        FROM ( SELECT DISTINCT t_cv_.id, t_cv_.super_ce_1
               FROM test1__cparameters_values AS t_cv_
               WHERE t_cv_.testcase_id = par_tc_id
             ) AS t_cv;

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr(t_cv.sub_ce_1), TRUE, FALSE)
        FROM ( SELECT DISTINCT t_cv_.id, t_cv_.sub_ce_1
               FROM test1__cparameters_values AS t_cv_
               WHERE t_cv_.testcase_id = par_tc_id
             ) AS t_cv;

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_D1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_D2'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_E1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_F1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_F2'), TRUE, FALSE);


        PERFORM delete_confentity(TRUE, make_confentitykey_bystr(t_cv.super_ce_2), TRUE, FALSE)
        FROM ( SELECT DISTINCT t_cv_.id, t_cv_.super_ce_2
               FROM test1__cparameters_values AS t_cv_
               WHERE t_cv_.testcase_id = par_tc_id
             ) AS t_cv;


        PERFORM delete_confentity(TRUE, make_confentitykey_bystr(t_cv.sub_ce_2), TRUE, FALSE)
        FROM ( SELECT DISTINCT t_cv_.id, t_cv_.sub_ce_2
               FROM test1__cparameters_values AS t_cv_
               WHERE t_cv_.testcase_id = par_tc_id
             ) AS t_cv;

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_I1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_I2'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_K1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_L1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_L2'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_M1'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC1_1_M2'), TRUE, FALSE);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_cnt;
END;
$$ LANGUAGE plpgsql;

---------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_testcases_of_t1(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt      integer;
        n integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_testcases_of_t1(par_tc_id);

        CASE par_tc_id
            WHEN 1 THEN
                n:= 4608;
                PERFORM new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_A0', FALSE)), 'TC1_1_A0_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_A1', FALSE)), 'TC1_1_A1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_A2', FALSE)), 'TC1_1_A2_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_D1', FALSE)), 'TC1_1_D1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_D2', FALSE)), 'TC1_1_D2_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_E1', FALSE)), 'TC1_1_E1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_F1', FALSE)), 'TC1_1_F1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_F2', FALSE)), 'TC1_1_F2_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_I1', FALSE)), 'TC1_1_I1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_I2', FALSE)), 'TC1_1_I2_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_K1', FALSE)), 'TC1_1_K1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_L1', FALSE)), 'TC1_1_L1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_L2', FALSE)), 'TC1_1_L2_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_M1', FALSE)), 'TC1_1_M1_CFG')
                      , new_config(FALSE, make_confentitykey_byid(new_confentity('TC1_1_M2', FALSE)), 'TC1_1_M2_CFG');

                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_A0')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'a0__a1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_A1')
                                      , mk_cpvalue_s('TC1_1_A1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_A1')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'a1__e1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_E1')
                                      , mk_cpvalue_s('TC1_1_E1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_A2')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'a2__e1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_E1')
                                      , mk_cpvalue_s('TC1_1_E1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_D1')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'd1__e1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_E1')
                                      , mk_cpvalue_s('TC1_1_E1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_D2')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'd2__e1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_E1')
                                      , mk_cpvalue_s('TC1_1_E1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_E1')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'e1__f1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_F1')
                                      , mk_cpvalue_s('TC1_1_F1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                    , mk_cparameter_uni(
                                        'e1__f2', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_F2')
                                      , mk_cpvalue_s('TC1_1_F2_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_F1')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'f1__i1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_I1')
                                      , mk_cpvalue_s('TC1_1_I1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_F2')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'f2__i2', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_I2')
                                      , mk_cpvalue_s('TC1_1_I2_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_I1')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'i1__k1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_K1')
                                      , mk_cpvalue_s('TC1_1_K1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );

                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_I2')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'i2__m2', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_M2')
                                      , mk_cpvalue_s('TC1_1_M2_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_K1')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'k1__l1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_L1')
                                      , mk_cpvalue_s('TC1_1_L1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                    , mk_cparameter_uni(
                                        'k1__l2', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_L2')
                                      , mk_cpvalue_s('TC1_1_L2_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                    , mk_cparameter_uni(
                                        'k1__m2', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_M2')
                                      , mk_cpvalue_s('TC1_1_M2_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_L1')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'l1__m1', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_M1')
                                      , mk_cpvalue_s('TC1_1_M1_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );
                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_1_L2')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'l2__m2', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_1_M2')
                                      , mk_cpvalue_s('TC1_1_M2_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                );

                -----------------------------------------------------
                PERFORM new_config(
                            FALSE
                          , make_confentitykey_byid(
                              new_confentity_w_params(
                                        t_cv.super_ce_name
                                      , array_cat(
                                          CASE (t_cv.param_dflt_lnk_persistance OR t_cv.lnk_persistance)
                                              WHEN TRUE THEN
                                                  ARRAY[
                                                      mk_cparameter_uni(
                                                        LOWER(t_cv.super_ce_name) || '__' || LOWER(t_cv.sub_ce_name) || '_r1'
                                                      , 'subconfig'
                                                      , ARRAY[] :: t_confparam_constraint[]
                                                      , TRUE
                                                      , 'par_d'
                                                      , sub_ce_id
                                                      , mk_cpvalue_s(
                                                                CASE t_cv.refed_param_has_value
                                                                    WHEN TRUE THEN t_cv.sub_ce_name || '__CFG_0'
                                                                    ELSE NULL :: varchar
                                                                END
                                                              , NULL :: varchar
                                                              , 'no_lnk'
                                                              )
                                                      )
                                                  ]
                                              ELSE ARRAY[] :: t_cparameter_uni[]
                                          END
                                        , ARRAY[  mk_cparameter_uni(
                                                        LOWER(t_cv.super_ce_name) || '__' || LOWER(t_cv.sub_ce_name)
                                                      , 'subconfig'
                                                      , ARRAY[] :: t_confparam_constraint[]
                                                      , t_cv.final_null_allowed
                                                      , t_cv.use_dflt
                                                      , sub_ce_id
                                                      , CASE (t_cv.param_dflt_value_persistance OR t_cv.param_dflt_lnk_persistance)
                                                            WHEN FALSE THEN NULL :: t_cpvalue_uni
                                                            ELSE mk_cpvalue_s(
                                                                        CASE t_cv.param_dflt_value_persistance
                                                                            WHEN FALSE THEN NULL :: varchar
                                                                            ELSE t_cv.sub_ce_name || '__CFG_0'
                                                                        END
                                                                      , CASE t_cv.param_dflt_lnk_persistance
                                                                            WHEN FALSE THEN NULL :: varchar
                                                                            ELSE LOWER(t_cv.super_ce_name) || '__' || LOWER(t_cv.sub_ce_name) || '_r1'
                                                                        END
                                                                      , t_cv.param_lnk_usage
                                                                      )
                                                        END
                                                      )
                                               ]
                                        )
                            ) )
                      , t_cv.super_ce_name || '__CFG_0'
                      , CASE (t_cv.value_lnk_usage IS NULL)
                            WHEN TRUE THEN ARRAY[] :: t_paramvals__short[]
                            ELSE ARRAY[
                                   ROW( LOWER(t_cv.super_ce_name) || '__' || LOWER(t_cv.sub_ce_name)
                                      , mk_cpvalue_s(
                                                CASE t_cv.value_persistance
                                                    WHEN FALSE THEN NULL :: varchar
                                                    ELSE t_cv.sub_ce_name || '__CFG_0'
                                                END
                                              , CASE t_cv.lnk_persistance
                                                    WHEN FALSE THEN NULL :: varchar
                                                    ELSE LOWER(t_cv.super_ce_name) || '__' || LOWER(t_cv.sub_ce_name) || '_r1'
                                                END
                                              , t_cv.value_lnk_usage
                                              )
                                      )
                                 ] :: t_paramvals__short[]
                        END
                      )
                FROM ( SELECT t_cv_.*
                            , new_config(TRUE, make_confentitykey_byid(t_cv_.sub_ce_id), sub_ce_name || '__CFG_0') AS new_config__r
                       FROM  ( SELECT t_cv__.*
                                    , CASE idx__
                                          WHEN 1 THEN new_confentity(t_cv__.sub_ce_1, TRUE)
                                          WHEN 2 THEN new_confentity(t_cv__.sub_ce_2, TRUE)
                                      END AS sub_ce_id
                                    , CASE idx__
                                          WHEN 1 THEN t_cv__.sub_ce_1
                                          WHEN 2 THEN t_cv__.sub_ce_2
                                      END AS sub_ce_name
                                    , CASE idx__
                                          WHEN 1 THEN t_cv__.super_ce_1
                                          WHEN 2 THEN t_cv__.super_ce_2
                                      END AS super_ce_name
                               FROM test1__cparameters_values AS t_cv__
                                  , (SELECT 1 union SELECT 2) AS idx__t(idx__)
                               WHERE t_cv__.testcase_id = par_tc_id
                             ) AS t_cv_
                     ) AS t_cv;

                -----------------------------------------------------

                PERFORM set_confentity_default(make_configkey_bystr2(t_cv.sub_ce_1, t_cv.sub_ce_1 || '__CFG_0'), FALSE)
                      , set_confentity_default(make_configkey_bystr2(t_cv.sub_ce_2, t_cv.sub_ce_2 || '__CFG_0'), FALSE)
                FROM test1__cparameters_values AS t_cv
                WHERE subconfentity_dflt_persists;

                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC1_' || t_cv.testcase_id || '_A' || t_cv.side_idx)
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'a' || t_cv.side_idx || '__b' || t_cv.id, 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_' || t_cv.testcase_id || '_B' || t_cv.id)
                                      , mk_cpvalue_s('TC1_' || t_cv.testcase_id || '_B' || t_cv.id || '__CFG_0', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC1_' || t_cv.testcase_id || '_F' || t_cv.side_idx)
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'f' || t_cv.side_idx || '__g' || t_cv.id, 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_' || t_cv.testcase_id || '_G' || t_cv.id)
                                      , mk_cpvalue_s('TC1_' || t_cv.testcase_id || '_G' || t_cv.id || '__CFG_0', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC1_' || t_cv.testcase_id || '_C' || t_cv.id)
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'c' || t_cv.id || '__d' || t_cv.side_idx, 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_' || t_cv.testcase_id || '_D' || t_cv.side_idx)
                                      , mk_cpvalue_s('TC1_' || t_cv.testcase_id || '_D' || t_cv.side_idx || '_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC1_' || t_cv.testcase_id || '_H' || t_cv.id)
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'h' || t_cv.id || '__i' || t_cv.side_idx, 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', get_confentity_id('TC1_' || t_cv.testcase_id || '_I' || t_cv.side_idx)
                                      , mk_cpvalue_s('TC1_' || t_cv.testcase_id || '_I' || t_cv.side_idx || '_CFG', NULL :: varchar, 'no_lnk')
                                      )
                                  ]
                                , FALSE
                                )
                FROM ( SELECT t_cv_.*, CASE WHEN t_cv_.id <= (n/2) THEN 1 ELSE 2 END AS side_idx
                       FROM test1__cparameters_values AS t_cv_
                     ) t_cv
                WHERE t_cv.testcase_id = par_tc_id;
        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- type 2---------------------------------------------------------------------
------------------------------------------------------------------------------

CREATE TABLE test2__confentities (
        testcase_id        integer NOT NULL CHECK (testcase_id > 100 AND testcase_id < 200)
      , ce_name_prefix     varchar NOT NULL
      , walk_start         boolean NOT NULL

      , PRIMARY KEY(testcase_id, ce_name_prefix)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE TABLE test2__rels (
        testcase_id integer NOT NULL CHECK (testcase_id > 100 AND testcase_id < 200)
      , super_ce    varchar NOT NULL
      , sub_ce      varchar NOT NULL

      , PRIMARY KEY(testcase_id, super_ce, sub_ce)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test2__confentities TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test2__rels         TO user_<<$app_name$>>_data_admin;

-------------------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_testcases_of_t2(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC2_' || UPPER(t_ce.ce_name_prefix) || '_' || t_ce.testcase_id), TRUE, FALSE)
        FROM test2__confentities AS t_ce
        WHERE t_ce.testcase_id = par_tc_id;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

-------------------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_testcases_of_t2(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt      integer;
        subce_w_dflt  sch_<<$app_name$>>.t_config_key;
        subce_wO_dflt sch_<<$app_name$>>.t_config_key;

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_testcases_of_t2(par_tc_id);

        PERFORM new_config(
                        FALSE
                      , make_confentitykey_byid(
                                new_confentity('TC2_' || UPPER(t_ce.ce_name_prefix) || '_' || t_ce.testcase_id, FALSE)
                        )
                      , 'TC2_' || UPPER(t_ce.ce_name_prefix) || '_' || t_ce.testcase_id || '_CFG1'
                )
        FROM test2__confentities AS t_ce
        WHERE t_ce.testcase_id = par_tc_id;

        CASE par_tc_id
            WHEN 105 THEN
                PERFORM set_confentity_default(
                            make_configkey_bystr2(
                                'TC2_' || UPPER(t_ce.ce_name_prefix) || '_' || t_ce.testcase_id
                              , 'TC2_' || UPPER(t_ce.ce_name_prefix) || '_' || t_ce.testcase_id || '_CFG1'
                              )
                          , FALSE
                          )
                FROM test2__confentities AS t_ce
                WHERE t_ce.testcase_id = par_tc_id;

                PERFORM add_confparams(
                                make_confentitykey_bystr('TC2_' || UPPER(t_r.super_ce) || '_' || t_r.testcase_id)
                              , ARRAY[
                                    mk_cparameter_uni(
                                                LOWER(t_r.super_ce) || '_' || LOWER(t_r.sub_ce)
                                              , 'subconfig'
                                              , ARRAY[] :: t_confparam_constraint[]
                                              , FALSE
                                              , 'sce_d'
                                              , get_confentity_id('TC2_' || UPPER(t_r.sub_ce) || '_' || t_r.testcase_id)
                                              , mk_cpvalue_null()
                                              )
                                ] :: t_cparameter_uni[]
                              , TRUE
                        )
                FROM test2__rels AS t_r
                WHERE t_r.testcase_id = par_tc_id;

            ELSE
                PERFORM add_confparams(
                                make_confentitykey_bystr('TC2_' || UPPER(t_r.super_ce) || '_' || t_r.testcase_id)
                              , ARRAY[
                                    mk_cparameter_uni(
                                                LOWER(t_r.super_ce) || '_' || LOWER(t_r.sub_ce)
                                              , 'subconfig'
                                              , ARRAY[] :: t_confparam_constraint[]
                                              , FALSE
                                              , 'par_d'
                                              , get_confentity_id('TC2_' || UPPER(t_r.sub_ce) || '_' || t_r.testcase_id)
                                              , mk_cpvalue_s(
                                                        'TC2_' || UPPER(t_r.sub_ce) || '_' || t_r.testcase_id || '_CFG1'
                                                      , NULL :: varchar
                                                      , 'no_lnk'
                                                      )
                                              )
                                ] :: t_cparameter_uni[]
                              , TRUE
                        )
                FROM test2__rels AS t_r
                WHERE t_r.testcase_id = par_tc_id;
        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_cnt;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- type 3 --------------------------------------------------------------------
------------------------------------------------------------------------------

CREATE TABLE test3__cparameters_values (
        testcase_id        integer NOT NULL CHECK (testcase_id > 200 AND testcase_id < 300)
      , super_ce           varchar NOT NULL
      , sub_ce             varchar NOT NULL
      , id                 integer NOT NULL
      , id_f               integer NOT NULL

      , final_null_allowed boolean NOT NULL
      , use_dflt           t_confparam_default_usage NOT NULL
      , subconfentity_dflt_persists   boolean NOT NULL
      , param_lnk_usage               t_subconfig_value_linking_read_rule NOT NULL
      , param_dflt_value_persistance  boolean NOT NULL
      , param_dflt_lnk_persistance    boolean NOT NULL
      , value_lnk_usage	   t_subconfig_value_linking_read_rule NOT NULL
      , value_persistance  boolean NOT NULL
      , lnk_persistance	   boolean     NULL
      , value_level_value_source      t_cpvalue_final_source NOT NULL
      , param_level_value_source      t_cpvalue_final_source NOT NULL
      , confentity_level_value_source t_cpvalue_final_source NOT NULL
      , final_value_source            t_cpvalue_final_source NOT NULL
      , final_value_persists          boolean NOT NULL
      , error                         boolean NOT NULL
      , PRIMARY KEY(testcase_id, id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test3__cparameters_values TO user_<<$app_name$>>_data_admin;

-------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_testcases_of_t3(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC3_201_super'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC3_201_sub'), TRUE, FALSE);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_cnt;
END;
$$ LANGUAGE plpgsql;

---------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_testcases_of_t3(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt      integer;
        super_id      integer;
        sub_id        integer;
        r             RECORD;
        last_par      integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_testcases_of_t3(par_tc_id);

        CASE par_tc_id
            WHEN 201 THEN
                SELECT new_confentity('TC3_201_super', FALSE)
                     , new_confentity('TC3_201_sub'  , FALSE)
                INTO super_id, sub_id;

                PERFORM new_config(FALSE, make_confentitykey_byid(super_id), 'TC3_201_super_CFG')
                      , new_config(FALSE, make_confentitykey_byid(sub_id  ), 'TC3_201_sub_CFG');

                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC3_201_super')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'par_link_chain_terminat', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , TRUE, 'par_d', sub_id
                                      , mk_cpvalue_s(
                                                'TC3_201_sub_CFG'
                                              , NULL :: varchar
                                              , 'no_lnk'
                                              )
                                      )
                                  ]
                                , FALSE
                                );

                FOR r IN SELECT *
                         FROM test3__cparameters_values AS t_cv
                         WHERE t_cv.testcase_id = par_tc_id
                         ORDER BY t_cv.id ASC
                LOOP last_par:= r.id;
                     PERFORM add_confparams(
                                  make_confentitykey_byid(super_id)
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'par_' || r.id, 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , r.final_null_allowed, r.use_dflt, sub_id
                                      , mk_cpvalue_s(
                                                CASE r.param_dflt_value_persistance
                                                    WHEN FALSE THEN NULL :: varchar
                                                    ELSE 'TC3_201_sub_CFG'
                                                END
                                              , CASE r.param_dflt_lnk_persistance
                                                    WHEN FALSE THEN NULL :: varchar
                                                    ELSE CASE WHEN r.id > 0 THEN 'par_' || (r.id - 1)
                                                              ELSE 'par_link_chain_terminat'
                                                         END
                                                END
                                              , r.param_lnk_usage
                                              )
                                      )
                                  ]
                                , FALSE
                                );
                     IF r.lnk_persistance IS NOT NULL THEN
                          PERFORM set_confparam_values_set(
                                        make_configkey_bystr(super_id, 'TC3_201_super_CFG')
                                      , ARRAY[
                                           ROW( 'par_' || r.id
                                              , mk_cpvalue_s(
                                                        CASE r.value_persistance
                                                            WHEN FALSE THEN NULL :: varchar
                                                            ELSE 'TC3_201_sub_CFG'
                                                        END
                                                      , CASE r.lnk_persistance
                                                            WHEN FALSE THEN NULL :: varchar
                                                            ELSE CASE WHEN r.id > 0 THEN 'par_' || (r.id - 1)
                                                                      ELSE 'par_link_chain_terminat'
                                                                 END
                                                        END
                                                      , r.value_lnk_usage
                                                      )
                                              )
                                        ] :: t_paramvals__short[]
                                      , 10
                                      );
                     END IF;
                END LOOP;

                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC3_201_super')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'par_first_lnk', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , TRUE, 'par_d', sub_id
                                      , mk_cpvalue_s(
                                                NULL :: varchar
                                              , 'par_' || last_par
                                              , 'alw_onl_lnk'
                                              )
                                      )
                                  ]
                                , FALSE
                                );
        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- type 4 --------------------------------------------------------------------
------------------------------------------------------------------------------

CREATE TABLE test4__cparameters_values (
        testcase_id        integer NOT NULL CHECK (testcase_id > 300 AND testcase_id < 400)
      , id                 integer NOT NULL

      , final_null_allowed boolean NOT NULL
      , use_dflt           t_confparam_default_usage NOT NULL
      , param_dflt_value_persistance
                           boolean NOT NULL
      , value_persistance  boolean NOT NULL

      , param_cnstr_1      t_confparam_constraint NULL
      , param_cnstr_2      t_confparam_constraint NULL

      , value_level_value_source      t_cpvalue_final_source NOT NULL
      , param_level_value_source      t_cpvalue_final_source NOT NULL
      , final_value_source            t_cpvalue_final_source NOT NULL
      , final_value_persists          boolean NOT NULL
      , error                         boolean NOT NULL

      , PRIMARY KEY(testcase_id, id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test4__cparameters_values TO user_<<$app_name$>>_data_admin;

-------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_testcases_of_t4(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC4_301'), TRUE, FALSE);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_cnt;
END;
$$ LANGUAGE plpgsql;

---------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_testcases_of_t4(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt      integer;
        super_id      integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_testcases_of_t4(par_tc_id);

        CASE par_tc_id
            WHEN 301 THEN
                SELECT new_confentity('TC4_301', FALSE) INTO super_id;
                PERFORM new_config(FALSE, make_confentitykey_byid(super_id), 'TC4_301_CFG');

                PERFORM add_confparams(
                                  make_confentitykey_byid(super_id)
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'par_' || t_cv.id, 'leaf'
                                      , (  CASE (t_cv.param_cnstr_1 IS NULL) OR ((t_cv.param_cnstr_1).constraint_function IS NULL)
                                               WHEN TRUE THEN ARRAY[] :: t_confparam_constraint[]
                                               ELSE ARRAY[t_cv.param_cnstr_1]
                                           END
                                        || CASE (t_cv.param_cnstr_2 IS NULL) OR ((t_cv.param_cnstr_2).constraint_function IS NULL)
                                               WHEN TRUE THEN ARRAY[] :: t_confparam_constraint[]
                                               ELSE ARRAY[t_cv.param_cnstr_2]
                                           END
                                        )
                                      , t_cv.final_null_allowed, t_cv.use_dflt, NULL :: integer
                                      , mk_cpvalue_l(CASE t_cv.param_dflt_value_persistance
                                                         WHEN FALSE THEN NULL :: varchar
                                                         ELSE '"default value"'
                                                     END
                                                    )
                                      )
                                  ]
                                , FALSE
                                )
                FROM test4__cparameters_values AS t_cv
                WHERE t_cv.testcase_id = par_tc_id;

                PERFORM set_confparam_values_set(
                                make_configkey_bystr(super_id, 'TC4_301_CFG')
                              , ARRAY[
                                   ROW( 'par_' || t_cv.id
                                      , mk_cpvalue_l(CASE t_cv.value_persistance
                                                         WHEN FALSE THEN NULL :: varchar
                                                         ELSE '"specified value"'
                                                     END
                                                    )
                                      )
                                ] :: t_paramvals__short[]
                              , 10
                              )
                FROM test4__cparameters_values AS t_cv
                WHERE t_cv.testcase_id = par_tc_id;

        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- type 5 --------------------------------------------------------------------
------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_testcases_of_t5(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_A_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_B_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_C_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_D_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_E_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_F_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_G_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_H_401'), TRUE, FALSE);
        PERFORM delete_confentity(TRUE, make_confentitykey_bystr('TC5_I_401'), TRUE, FALSE);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_cnt;
END;
$$ LANGUAGE plpgsql;

---------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_testcases_of_t5(par_tc_id integer) RETURNS integer AS $$
DECLARE rows_cnt      integer;
        super_id      integer;
        sub_id        integer;
        r             RECORD;
        last_par      integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_testcases_of_t5(par_tc_id);

        CASE par_tc_id
            WHEN 401 THEN
                PERFORM new_confentity('TC5_A_401', FALSE)
                      , new_confentity('TC5_B_401', FALSE)
                      , new_confentity('TC5_C_401', FALSE)
                      , new_confentity('TC5_D_401', FALSE)
                      , new_confentity('TC5_E_401', FALSE)
                      , new_confentity('TC5_F_401', FALSE)
                      , new_confentity('TC5_G_401', FALSE)
                      , new_confentity('TC5_H_401', FALSE)
                      , new_confentity('TC5_I_401', FALSE)
                      ;

                PERFORM new_config(FALSE, make_confentitykey_bystr('TC5_A_401'), 'TC5_A_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_A_401'), 'TC5_A_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_B_401'), 'TC5_B_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_B_401'), 'TC5_B_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_C_401'), 'TC5_C_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_C_401'), 'TC5_C_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_D_401'), 'TC5_D_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_D_401'), 'TC5_D_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_E_401'), 'TC5_E_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_E_401'), 'TC5_E_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_F_401'), 'TC5_F_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_F_401'), 'TC5_F_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_G_401'), 'TC5_G_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_G_401'), 'TC5_G_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_H_401'), 'TC5_H_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_H_401'), 'TC5_H_401_CFG_incor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_I_401'), 'TC5_I_401_CFG_cor')
                      , new_config(FALSE, make_confentitykey_bystr('TC5_I_401'), 'TC5_I_401_CFG_incor')
                      ;

                PERFORM set_confentity_default(make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_incor'), FALSE)
                      , set_confentity_default(make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_incor'), FALSE)
                      ;

                PERFORM add_confparams(
                                  make_confentitykey_bystr('TC5_A_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'a_e', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_E_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'a_f', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_F_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'a_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'a_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_B_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'b_a', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_A_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'b_h', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_H_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'b_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'b_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_C_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'c_a', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_A_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'c_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'c_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_D_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'd_b', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_B_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'd_c', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_C_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'd_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'd_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_E_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'e_g', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_G_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'e_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'e_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_F_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'f_g', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_G_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'f_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'f_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_G_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'g_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'g_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_H_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'h_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'h_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      , add_confparams(
                                  make_confentitykey_bystr('TC5_I_401')
                                , ARRAY[
                                      mk_cparameter_uni(
                                        'i_f', 'subconfig'
                                      , ARRAY[] :: t_confparam_constraint[]
                                      , FALSE, 'sce_d', get_confentity_id('TC5_F_401')
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'i_1', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'no_d', NULL :: integer
                                      , mk_cpvalue_null()
                                      )
                                    , mk_cparameter_uni(
                                        'i_2', 'leaf'
                                      , ARRAY[mk_confparam_constraint('1=1'), mk_confparam_constraint('$1=''correct value''')] :: t_confparam_constraint[]
                                      , FALSE, 'par_d', NULL :: integer
                                      , mk_cpvalue_l('incorrect value')
                                      )
                                  ]
                                , FALSE
                                )
                      ;

                PERFORM set_confparam_values_set(
                                make_configkey_bystr2('TC5_A_401', 'TC5_A_401_CFG_cor')
                              , ARRAY[ ROW( 'a_e', mk_cpvalue_s('TC5_E_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'a_f', mk_cpvalue_s('TC5_F_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'a_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'a_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_B_401', 'TC5_B_401_CFG_cor')
                              , ARRAY[ ROW( 'b_a', mk_cpvalue_s('TC5_A_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'b_h', mk_cpvalue_s('TC5_H_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'b_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'b_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_C_401', 'TC5_C_401_CFG_cor')
                              , ARRAY[ ROW( 'c_a', mk_cpvalue_s('TC5_A_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'c_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'c_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_D_401', 'TC5_D_401_CFG_cor')
                              , ARRAY[ ROW( 'd_b', mk_cpvalue_s('TC5_B_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'd_c', mk_cpvalue_s('TC5_C_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'd_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'd_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_E_401', 'TC5_E_401_CFG_cor')
                              , ARRAY[ ROW( 'e_g', mk_cpvalue_s('TC5_G_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'e_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'e_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_F_401', 'TC5_F_401_CFG_cor')
                              , ARRAY[ ROW( 'f_g', mk_cpvalue_s('TC5_G_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'f_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'f_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_G_401', 'TC5_G_401_CFG_cor')
                              , ARRAY[ ROW( 'g_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'g_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_H_401', 'TC5_H_401_CFG_cor')
                              , ARRAY[ ROW( 'h_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'h_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      , set_confparam_values_set(
                                make_configkey_bystr2('TC5_I_401', 'TC5_I_401_CFG_cor')
                              , ARRAY[ ROW( 'i_f', mk_cpvalue_s('TC5_F_401_CFG_incor', NULL :: varchar, 'no_lnk'))
                                     , ROW( 'i_1', mk_cpvalue_l('correct value'))
                                     , ROW( 'i_2', mk_cpvalue_l('correct value'))
                                     ] :: t_paramvals__short[]
                              , 1
                              )
                      ;
                UPDATE configurations AS c SET completeness_as_regulator = 'SET INCOMPLETE'
                WHERE (confentity_code_id = get_confentity_id('TC5_A_401') AND configuration_id = 'TC5_A_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_B_401') AND configuration_id = 'TC5_B_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_C_401') AND configuration_id = 'TC5_C_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_D_401') AND configuration_id = 'TC5_D_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_E_401') AND configuration_id = 'TC5_E_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_F_401') AND configuration_id = 'TC5_F_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_G_401') AND configuration_id = 'TC5_G_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_H_401') AND configuration_id = 'TC5_H_401_CFG_cor')
                   OR (confentity_code_id = get_confentity_id('TC5_I_401') AND configuration_id = 'TC5_I_401_CFG_cor');
        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- general -------------------------------------------------------------------
------------------------------------------------------------------------------

CREATE TABLE pkg_test_cases__ (testcase_id integer PRIMARY KEY, testcase_type integer);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE pkg_test_cases__ TO user_<<$app_name$>>_data_admin;

--------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_testcases(par_tc_id integer) RETURNS integer AS $$
DECLARE
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        CASE
            WHEN par_tc_id >   0 AND par_tc_id < 100 THEN
                PERFORM pkg_<<$app_name$>>__delete_testcases_of_t1(par_tc_id);
            WHEN par_tc_id > 100 AND par_tc_id < 200 THEN
                PERFORM pkg_<<$app_name$>>__delete_testcases_of_t2(par_tc_id);
            WHEN par_tc_id > 200 AND par_tc_id < 300 THEN
                PERFORM pkg_<<$app_name$>>__delete_testcases_of_t3(par_tc_id);
            WHEN par_tc_id > 300 AND par_tc_id < 400 THEN
                PERFORM pkg_<<$app_name$>>__delete_testcases_of_t4(par_tc_id);
            WHEN par_tc_id > 400 AND par_tc_id < 500 THEN
                PERFORM pkg_<<$app_name$>>__delete_testcases_of_t5(par_tc_id);
            ELSE RAISE EXCEPTION 'Test case #% not classified.', par_tc_id;
        END CASE;

        RAISE NOTICE 'Test case #% deleted.', par_tc_id;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

----------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_testcases(par_tc_id integer) RETURNS integer AS $$
DECLARE
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_testcases(par_tc_id);

        CASE
            WHEN par_tc_id >   0 AND par_tc_id < 100 THEN
                PERFORM pkg_<<$app_name$>>__create_testcases_of_t1(par_tc_id);
            WHEN par_tc_id > 100 AND par_tc_id < 200 THEN
                PERFORM pkg_<<$app_name$>>__create_testcases_of_t2(par_tc_id);
            WHEN par_tc_id > 200 AND par_tc_id < 300 THEN
                PERFORM pkg_<<$app_name$>>__create_testcases_of_t3(par_tc_id);
            WHEN par_tc_id > 300 AND par_tc_id < 400 THEN
                PERFORM pkg_<<$app_name$>>__create_testcases_of_t4(par_tc_id);
            WHEN par_tc_id > 400 AND par_tc_id < 500 THEN
                PERFORM pkg_<<$app_name$>>__create_testcases_of_t5(par_tc_id);
            ELSE RAISE EXCEPTION 'Test case #% not classified.', par_tc_id;
        END CASE;

        RAISE NOTICE 'Test case #% created.', par_tc_id;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

--------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__delete_all_testcases() RETURNS integer AS $$
DECLARE
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_testcases(atc.testcase_id)
        FROM pkg_test_cases__ AS atc;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

----------------------------

CREATE OR REPLACE FUNCTION pkg_<<$app_name$>>__create_all_testcases() RETURNS integer AS $$
DECLARE
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        PERFORM pkg_<<$app_name$>>__delete_all_testcases();

        PERFORM pkg_<<$app_name$>>__create_testcases(atc.testcase_id)
        FROM pkg_test_cases__ AS atc;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

------------------------------------------------------------------------------
-- data ----------------------------------------------------------------------
------------------------------------------------------------------------------

\i mini_testcases.init.sql

SELECT set_confparam_values_set(
                make_configkey_bystr2('Configuration management system setup', 'CMSS config #1')
              , ARRAY[ ROW( 'completeness check routines', mk_cpvalue_l('DISABLED'))
                     ] :: t_paramvals__short[]
              , 1
              );
SELECT set_confparam_values_set(
                make_configkey_bystr2('Configuration management system setup', 'CMSS config #1')
              , ARRAY[ ROW( 'notice config items creation/deletion', mk_cpvalue_l('DISABLED'))
                     ] :: t_paramvals__short[]
              , 1
              );


SELECT pkg_<<$app_name$>>__create_dummies();

SELECT pkg_<<$app_name$>>__create_all_testcases();

SELECT set_confparam_values_set(
                make_configkey_bystr2('Configuration management system setup', 'CMSS config #1')
              , ARRAY[ ROW( 'completeness check routines', mk_cpvalue_l('ENABLED'))
                     ] :: t_paramvals__short[]
              , 1
              );

SELECT set_confparam_values_set(
                make_configkey_bystr2('Configuration management system setup', 'CMSS config #1')
              , ARRAY[ ROW( 'notice config items creation/deletion', mk_cpvalue_l('DISABLED'))
                     ] :: t_paramvals__short[]
              , 1
              );


