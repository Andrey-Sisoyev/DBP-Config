-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- TYPE t_confentity_key AS (confentity_codekeyl t_code_key_by_lng);
-- TYPE t_confentity_param_wdelstats__short AS (ce_id integer, param_id varchar, deled integer);
-- TYPE t_cfg_wdelstats__short AS (cfg_id varchar, deled integer);

-- Reference functions:
SELECT show_confentitykey(make_confentitykey(make_codekeyl_bystr('Dummy_1_CE')));
SELECT show_confentitykey(make_confentitykey_null());
SELECT show_confentitykey(make_confentitykey_bystr('Dummy_1_CE'));
SELECT show_confentitykey(make_confentitykey_byid(789));

SELECT code_id_of_confentitykey(make_confentitykey_byid(789));
SELECT code_id_of_confentitykey(make_confentitykey_bystr('Dummy_1_CE'));

SELECT confentity_is_null(make_confentitykey_null());
SELECT confentity_is_null(make_confentitykey_byid(789));
SELECT confentity_is_null(make_confentitykey(make_codekeyl_null()));

SELECT confentity_has_lng(make_confentitykey_byid(789));
SELECT confentity_has_lng(make_confentitykey_bystr('Dummy_1_CE'));
SELECT confentity_has_lng(make_confentitykey(make_codekeyl(make_codekey(1, 'Dummy_1_CE'), make_codekey(1, 'Dummy_1_CE'))));
SELECT confentity_has_lng(make_confentitykey(make_codekeyl(make_codekey_null(), make_codekey(1, 'Dummy_1_CE'))));
SELECT confentity_has_lng(make_confentitykey_null());

SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, 'Dummy_1_CE'), make_codekey(1, 'Dummy_1_CE'))), TRUE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'Dummy_1_CE'), make_codekey(1, 'Dummy_1_CE'))), TRUE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, 'Dummy_1_CE'), make_codekey(NULL :: integer, 'Dummy_1_CE'))), TRUE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, NULL :: varchar), make_codekey(1, NULL :: varchar))), TRUE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey_null(), make_codekey(1, NULL :: varchar))), TRUE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, NULL :: varchar), make_codekey_null())), TRUE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey_null(), make_codekey_null())), TRUE);
SELECT optimized_confentitykey_isit(make_confentitykey_null(), TRUE);

SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, 'Dummy_1_CE'), make_codekey(1, 'Dummy_1_CE'))), FALSE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(NULL :: integer, 'Dummy_1_CE'), make_codekey(1, 'Dummy_1_CE'))), FALSE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, 'Dummy_1_CE'), make_codekey(NULL :: integer, 'Dummy_1_CE'))), FALSE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, NULL :: varchar), make_codekey(1, NULL :: varchar))), FALSE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey_null(), make_codekey(1, NULL :: varchar))), FALSE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey(1, NULL :: varchar), make_codekey_null())), FALSE);
SELECT optimized_confentitykey_isit(make_confentitykey(make_codekeyl(make_codekey_null(), make_codekey_null())), FALSE);
SELECT optimized_confentitykey_isit(make_confentitykey_null(), TRUE);


-- Lookup functions:
\echo >>>>>> not found error
SELECT show_confentitykey(optimize_confentitykey(FALSE, make_confentitykey_null()));
SELECT show_confentitykey(
         optimize_confentitykey(
           FALSE
         , make_confentitykey(
             make_codekeyl(
               make_codekey(NULL :: integer, 'rus')
             , make_codekey(NULL :: integer, 'Болванка_1_КС')
       ) ) ) );
SELECT show_confentitykey(optimize_confentitykey(FALSE, make_confentitykey(make_codekeyl(make_codekey_null(), make_codekey(NULL :: integer, 'Dummy_1_CE')))));

SELECT get_confentity_default(make_confentitykey_bystr('Dummy_1_CE'));
SELECT get_confentity_default(make_confentitykey_bystr('Dummy_2_CE'));
\echo >>>>>> not found error
SELECT get_confentity_default(make_confentitykey_bystr('Dummy_3_CE'));
