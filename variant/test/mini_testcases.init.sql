-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> testcases.init.sql: testcases metadata

INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (1, 1);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (101, 2);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (102, 2);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (103, 2);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (104, 2);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (105, 2);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (201, 3);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (301, 4);
INSERT INTO pkg_test_cases__ (testcase_id, testcase_type) VALUES (401, 5);


------------------------------------------------
------------------------------------------------
------type 1------------------------------------
------------------------------------------------

\echo NOTICE >>>>> testcases.init.sql: testcases of type 1

INSERT INTO test1__cparameters_values (testcase_id, super_ce_1, sub_ce_1, super_ce_2, sub_ce_2, id, final_null_allowed, use_dflt, subconfentity_dflt_persists, refed_param_has_value, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 1,'TC1_1_B0','TC1_1_C0','TC1_1_G0','TC1_1_H0',0, TRUE,'no_d', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test1__cparameters_values (testcase_id, super_ce_1, sub_ce_1, super_ce_2, sub_ce_2, id, final_null_allowed, use_dflt, subconfentity_dflt_persists, refed_param_has_value, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 1,'TC1_1_B1','TC1_1_C1','TC1_1_G1','TC1_1_H1',1, TRUE,'no_d', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'alw_onl_lnk', TRUE, FALSE,'null','null','null','null', FALSE, FALSE);
INSERT INTO test1__cparameters_values (testcase_id, super_ce_1, sub_ce_1, super_ce_2, sub_ce_2, id, final_null_allowed, use_dflt, subconfentity_dflt_persists, refed_param_has_value, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 1,'TC1_1_B2','TC1_1_C2','TC1_1_G2','TC1_1_H2',2, TRUE,'no_d', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'alw_onl_lnk', FALSE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test1__cparameters_values (testcase_id, super_ce_1, sub_ce_1, super_ce_2, sub_ce_2, id, final_null_allowed, use_dflt, subconfentity_dflt_persists, refed_param_has_value, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 1,'TC1_1_B3','TC1_1_C3','TC1_1_G3','TC1_1_H3',3, TRUE,'no_d', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'alw_onl_lnk', FALSE, FALSE,'null','null','null','null', FALSE, FALSE);
INSERT INTO test1__cparameters_values (testcase_id, super_ce_1, sub_ce_1, super_ce_2, sub_ce_2, id, final_null_allowed, use_dflt, subconfentity_dflt_persists, refed_param_has_value, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 1,'TC1_1_B4','TC1_1_C4','TC1_1_G4','TC1_1_H4',4, TRUE,'no_d', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'whn_vnull_lnk', TRUE, TRUE,'cpv','cpv','cpv','cpv', TRUE, FALSE);
INSERT INTO test1__cparameters_values (testcase_id, super_ce_1, sub_ce_1, super_ce_2, sub_ce_2, id, final_null_allowed, use_dflt, subconfentity_dflt_persists, refed_param_has_value, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 1,'TC1_1_B5','TC1_1_C5','TC1_1_G5','TC1_1_H5',5, TRUE,'no_d', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'whn_vnull_lnk', TRUE, FALSE,'cpv','cpv','cpv','cpv', TRUE, FALSE);

----------------------------------------------------------
----------------------------------------------------------
-- type 2-------------------------------------------------
----------------------------------------------------------

\echo NOTICE >>>>> testcases.init.sql: testcases of type 2

INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'A', TRUE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'B', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'C', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'D', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'E', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'F', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'G', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (101, 'H', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'A', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'B', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'C', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'D', TRUE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'E', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'F', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'G', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'H', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (102, 'I', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (103, 'A', TRUE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (103, 'B', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (103, 'C', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (104, 'A', TRUE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (104, 'B', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (104, 'C', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (104, 'D', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'A', TRUE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'B', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'C', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'D', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'E', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'F', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'G', FALSE);
INSERT INTO test2__confentities (testcase_id, ce_name_prefix, walk_start) VALUES (105, 'H', FALSE);





INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'B', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'C', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'D', 'B');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'D', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'G', 'D');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'E', 'G');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'F', 'G');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'A', 'E');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'A', 'F');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (101, 'B', 'H');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'B', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'C', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'D', 'B');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'E', 'B');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'D', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'F', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'A', 'E');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'I', 'E');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'G', 'E');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'A', 'F');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'E', 'H');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (102, 'F', 'H');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (103, 'B', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (103, 'A', 'B');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (103, 'B', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (104, 'B', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (104, 'C', 'B');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (104, 'A', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (104, 'B', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (104, 'D', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'B', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'C', 'A');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'D', 'B');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'D', 'C');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'E', 'G');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'F', 'G');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'A', 'E');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'A', 'F');
INSERT INTO test2__rels (testcase_id, super_ce, sub_ce) VALUES (105, 'B', 'H');


--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
-- type 3-----------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------

\echo NOTICE >>>>> testcases.init.sql: testcases of type 3

INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',0,0, TRUE,'no_d', TRUE,'alw_onl_lnk', TRUE, TRUE,'alw_onl_lnk', TRUE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',1,2, TRUE,'no_d', TRUE,'alw_onl_lnk', TRUE, TRUE,'alw_onl_lnk', FALSE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',2,6, TRUE,'no_d', TRUE,'alw_onl_lnk', TRUE, TRUE,'whn_vnull_lnk', FALSE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',3,16, TRUE,'no_d', TRUE,'alw_onl_lnk', TRUE, FALSE,'alw_onl_lnk', TRUE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',4,18, TRUE,'no_d', TRUE,'alw_onl_lnk', TRUE, FALSE,'alw_onl_lnk', FALSE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',5,22, TRUE,'no_d', TRUE,'alw_onl_lnk', TRUE, FALSE,'whn_vnull_lnk', FALSE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',6,32, TRUE,'no_d', TRUE,'alw_onl_lnk', FALSE, TRUE,'alw_onl_lnk', TRUE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);
INSERT INTO test3__cparameters_values (testcase_id, super_ce, sub_ce,id,id_f, final_null_allowed, use_dflt, subconfentity_dflt_persists, param_lnk_usage, param_dflt_value_persistance, param_dflt_lnk_persistance, value_lnk_usage, value_persistance, lnk_persistance, value_level_value_source, param_level_value_source, confentity_level_value_source, final_value_source, final_value_persists, error) VALUES( 201,'TC3_201_super','TC3_201_sub',7,34, TRUE,'no_d', TRUE,'alw_onl_lnk', FALSE, TRUE,'alw_onl_lnk', FALSE, TRUE,'cpv_il','cpv_il','cpv_il','cpv_il', TRUE, FALSE);

----------------------------------------------------------
----------------------------------------------------------
-- type 4-------------------------------------------------
----------------------------------------------------------

\echo NOTICE >>>>> testcases.init.sql: testcases of type 4

INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 0, TRUE,'no_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 1, TRUE,'no_d', TRUE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 2, TRUE,'no_d', FALSE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 3, TRUE,'no_d', FALSE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 4, TRUE,'par_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 5, TRUE,'par_d', TRUE, FALSE, mk_confparam_constraint(' $1=''"default value"'' AND 1=1 '), mk_confparam_constraint(' $2=''TC4_301_CFG'' '), 'null','cp_dflt', 'cp_dflt', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 6, TRUE,'par_d', FALSE, TRUE, mk_confparam_constraint(' $1=''"default value"'' AND 1=1 '), mk_confparam_constraint(' $2=''TC4_301_CFG'' '), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 7, TRUE,'par_d', FALSE, FALSE, mk_confparam_constraint(' $1=''"default value"'' AND 1=1 '), mk_confparam_constraint(' $2=''TC4_301_CFG'' '), 'null','null', 'null', FALSE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 8, FALSE,'no_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 9, FALSE,'no_d', TRUE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, TRUE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 10, FALSE,'no_d', FALSE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 11, FALSE,'no_d', FALSE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, TRUE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 12, FALSE,'par_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 13, FALSE,'par_d', TRUE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','cp_dflt', 'cp_dflt', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 14, FALSE,'par_d', FALSE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 15, FALSE,'par_d', FALSE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, TRUE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 16, TRUE,'no_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 17, TRUE,'no_d', TRUE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 18, TRUE,'no_d', FALSE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 19, TRUE,'no_d', FALSE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 20, TRUE,'par_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 21, TRUE,'par_d', TRUE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','cp_dflt', 'cp_dflt', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 22, TRUE,'par_d', FALSE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 23, TRUE,'par_d', FALSE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 24, FALSE,'no_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 25, FALSE,'no_d', TRUE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, TRUE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 26, FALSE,'no_d', FALSE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 27, FALSE,'no_d', FALSE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, TRUE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 28, FALSE,'par_d', TRUE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 29, FALSE,'par_d', TRUE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','cp_dflt', 'cp_dflt', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 30, FALSE,'par_d', FALSE, TRUE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'cpv','cpv', 'cpv', TRUE, FALSE);
INSERT INTO test4__cparameters_values (testcase_id, id, final_null_allowed, use_dflt, param_dflt_value_persistance, value_persistance, param_cnstr_1, param_cnstr_2, value_level_value_source, param_level_value_source, final_value_source, final_value_persists, error) VALUES(301, 31, FALSE,'par_d', FALSE, FALSE, mk_confparam_constraint(NULL :: varchar), mk_confparam_constraint(NULL :: varchar), 'null','null', 'null', FALSE, TRUE);

