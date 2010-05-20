-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>>> tests.cleanup.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

SELECT pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_all_testcases();
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_all_testcases();
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_all_testcases();

DROP TABLE pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__test_cases__;
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_testcases(par_tc_id integer);
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_testcases(par_tc_id integer);

DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_testcases_of_t5(par_tc_id integer);
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_testcases_of_t5(par_tc_id integer);

DROP TABLE test4__cparameters_values;
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_testcases_of_t4(par_tc_id integer);
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_testcases_of_t4(par_tc_id integer);

DROP TABLE test3__cparameters_values;
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_testcases_of_t3(par_tc_id integer);
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_testcases_of_t3(par_tc_id integer);

DROP TABLE test2__confentities;
DROP TABLE test2__rels;
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_testcases_of_t2(par_tc_id integer);
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_testcases_of_t2(par_tc_id integer);

DROP TABLE IF EXISTS test1__cparameters_values;
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_testcases_of_t1(par_tc_id integer);
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_testcases_of_t1(par_tc_id integer);

SELECT pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_dummies();
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__delete_dummies();
DROP FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_dummies();

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>>> tests.cleanup.sql [END]
