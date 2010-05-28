-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- TYPE t_cfg_tree_rel_type AS ENUM ('init', 'sce_user', 'ce_user', 'pv_user', 'p_val', 'p_dflt_val', 'p_lnk_val', 'p_lnk_dflt', 'ce_dflt')
-- TYPE t_config_keys_list AS (list t_config_key[])
-- TYPE t_analyzed_cfgs_set AS (
--           involved_in_cycles t_config_key[]
--         , dep_on_cycles      t_config_key[]
--         , sorted_by_depth    t_config_keys_list[]
-- )
-- TYPE t_configs_tree_row_cycles_filtered AS(
--         no_cycles   t_configs_tree_rel[]
--       , with_cycles t_configs_tree_rel[]
-- )
-- TYPE t_configs_tree_rel AS (
--         super_ce_id    integer
--       , super_cfg_id   varchar
--       , super_param_id varchar
--       , sub_ce_id      integer
--       , sub_cfg_id     varchar
--       , cfg_tree_rel_type
--                        t_cfg_tree_rel_type
--       , path           t_config_key[]
--       , depth          integer  -- DFD(path)
--       , cycle_detected boolean  -- DFD(path)
--       , super_complete t_config_completeness_check_result
--       , sub_complete   t_config_completeness_check_result
-- )


-- Reference functions:
SELECT cfg_tree_rel_main_types_set(TRUE);
SELECT cfg_tree_rel_main_types_set(FALSE);

--------

SELECT mk_configs_tree_rel(
                1
              , 'sdf'
              , 'dsf'
              , 2
              , 'asd'
              , 'ce_user'
              , ARRAY[ make_configkey_bystr(4, 'Dummy_4_CFG')
                     ] :: t_config_key[]
              , 12
              , false
              , 'li_chk_V'
              , 'li_chk_V'
              );

\echo >>>>>> NULL, because parameter value contains nonoptimized config-key
SELECT show_cfgtreerow_path(
          mk_configs_tree_rel(
                1
              , 'sdf'
              , 'dsf'
              , 2
              , 'asd'
              , 'ce_user'
              , ARRAY[ make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
                     , make_configkey_bystr(1, 'Dummy_1_CFG')
                     , make_configkey_bystr(2, 'Dummy_2_CFG')
                     , make_configkey_bystr(4, 'Dummy_4_CFG')
                     ] :: t_config_key[]
              , 12
              , false
              , 'li_chk_V'
              , 'li_chk_V'
              ));

SELECT show_cfgtreerow_path(
          mk_configs_tree_rel(
                1
              , 'sdf'
              , 'dsf'
              , 2
              , 'asd'
              , 'ce_user'
              , ARRAY[ make_configkey_bystr(0, 'Dummy_1_CFG')
                     , make_configkey_bystr(1, 'Dummy_1_CFG')
                     , make_configkey_bystr(2, 'Dummy_2_CFG')
                     , make_configkey_bystr(4, 'Dummy_4_CFG')
                     ] :: t_config_key[]
              , 12
              , false
              , 'li_chk_V'
              , 'li_chk_V'
              ));

-- Analytic functions:
SELECT cfg_idx_in_list(
          make_configkey_bystr(2, 'Dummy_2_CFG')
        , ARRAY[ make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
               , make_configkey_bystr(1, 'Dummy_1_CFG')
               , make_configkey_bystr(2, 'Dummy_2_CFG')
               , make_configkey_bystr(4, 'Dummy_4_CFG')
               ] :: t_config_key[]
        );

SELECT cfg_idx_in_list(
          make_configkey_bystr(2, 'Dummy_2_CFG')
        , ARRAY[ make_configkey_bystr(0, 'Dummy_1_CFG')
               , make_configkey_bystr(1, 'Dummy_1_CFG')
               , make_configkey_bystr(2, 'Dummy_2_CFG')
               , make_configkey_bystr(4, 'Dummy_4_CFG')
               ] :: t_config_key[]
        );

SELECT cfg_idx_in_list(
          make_configkey_bystr(20, 'Dummy_2_CFG')
        , ARRAY[ make_configkey_bystr(0, 'Dummy_1_CFG')
               , make_configkey_bystr(1, 'Dummy_1_CFG')
               , make_configkey_bystr(2, 'Dummy_2_CFG')
               , make_configkey_bystr(4, 'Dummy_4_CFG')
               ] :: t_config_key[]
        );

SELECT cfg_idx_in_list(
          make_configkey_bystr(0, 'Dummy_1_CFG')
        , ARRAY[ make_configkey_bystr(0, 'Dummy_1_CFG')
               ] :: t_config_key[]
        );

SELECT cfg_idx_in_list(
          make_configkey_bystr(1, 'Dummy_1_CFG')
        , ARRAY[ make_configkey_bystr(0, 'Dummy_1_CFG')
               ] :: t_config_key[]
        );

-----------------
SELECT * FROM unnest(sub_cfgs_of(make_configkey_bystr2('TC2_D_102', 'TC2_D_102_CFG1'), cfg_tree_rel_main_types_set(TRUE))) AS a;
SELECT * FROM unnest(sub_cfgs_of(make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1'), cfg_tree_rel_main_types_set(TRUE))) AS a;

-----------------

SELECT cfg_tree_2_cfgs(
                sub_cfgs_of(
                        make_configkey_bystr2('TC2_D_102', 'TC2_D_102_CFG1')
                      , cfg_tree_rel_main_types_set(TRUE)
                      )
              , NULL :: integer
       );
SELECT cfg_tree_2_cfgs(
                sub_cfgs_of(
                        make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
                      , cfg_tree_rel_main_types_set(TRUE)
                      )
              , NULL :: integer
       );

-----------------

SELECT analyze_cfgs_tree(
              sub_cfgs_of(
                        make_configkey_bystr2('TC2_D_102', 'TC2_D_102_CFG1')
                      , cfg_tree_rel_main_types_set(TRUE)
                      )
            , make_configkey_null()
            , TRUE
            , NULL :: integer
       );
SELECT analyze_cfgs_tree(
              sub_cfgs_of(
                        make_configkey_bystr2('TC2_D_102', 'TC2_D_102_CFG1')
                      , cfg_tree_rel_main_types_set(TRUE)
                      )
            , make_configkey_null()
            , FALSE
            , NULL :: integer
       );
SELECT analyze_cfgs_tree(
              sub_cfgs_of(
                        make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
                      , cfg_tree_rel_main_types_set(TRUE)
                      )
            , make_configkey_null()
            , TRUE
            , NULL :: integer
       );
SELECT analyze_cfgs_tree(
              sub_cfgs_of(
                        make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
                      , cfg_tree_rel_main_types_set(TRUE)
                      )
            , make_configkey_null()
            , FALSE
            , NULL :: integer
       );


-- Lookup functions:
SELECT 'subs' AS dir, a.*
FROM unnest(sub_cfgs_of(
                make_configkey_bystr2('TC2_A_101', 'TC2_A_101_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a
UNION
SELECT 'supers' AS dir, a.*
FROM unnest(super_cfgs_of(
                make_configkey_bystr2('TC2_A_101', 'TC2_A_101_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a;


SELECT 'subs' AS dir, a.*
FROM unnest(sub_cfgs_of(
                make_configkey_bystr2('TC2_D_102', 'TC2_D_102_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a
UNION
SELECT 'supers' AS dir, a.*
FROM unnest(super_cfgs_of(
                make_configkey_bystr2('TC2_D_102', 'TC2_D_102_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a;


SELECT 'subs' AS dir, a.*
FROM unnest(sub_cfgs_of(
                make_configkey_bystr2('TC2_A_103', 'TC2_A_103_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a
UNION
SELECT 'supers' AS dir, a.*
FROM unnest(super_cfgs_of(
                make_configkey_bystr2('TC2_A_103', 'TC2_A_103_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a;


SELECT 'subs' AS dir, a.*
FROM unnest(sub_cfgs_of(
                make_configkey_bystr2('TC2_A_104', 'TC2_A_104_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a
UNION
SELECT 'supers' AS dir, a.*
FROM unnest(super_cfgs_of(
                make_configkey_bystr2('TC2_A_104', 'TC2_A_104_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a;


SELECT 'subs' AS dir, a.*
FROM unnest(sub_cfgs_of(
                make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a
UNION
SELECT 'supers' AS dir, a.*
FROM unnest(super_cfgs_of(
                make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
              , cfg_tree_rel_main_types_set(TRUE)
              )) AS a;

------------

SELECT pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__create_dummies();
SELECT set_confparam_value(
                make_configparamkey_bystr3('Dummy_1_CE', 'Dummy_1_CFG', 'dummy_1_param_11')
              , mk_cpvalue_s(NULL :: varchar, 'dummy_1_param_1', 'alw_onl_lnk')
              , 10
              , FALSE
              );
SELECT subconfigparams_lnks_extraction(
             sub_cfgs_of(
                make_configkey_bystr2('Dummy_1_CE', 'Dummy_1_CFG')
              , cfg_tree_rel_main_types_set(FALSE)
              )
           , cfg_tree_rel_main_types_set(TRUE)
           );
SELECT subconfigparams_lnks_extraction(
             super_cfgs_of(
                make_configkey_bystr2('Dummy_2_CE', 'Dummy_2_CFG')
              , cfg_tree_rel_main_types_set(FALSE)
              )
           , cfg_tree_rel_main_types_set(TRUE)
           );

----------------------

SELECT * FROM unnest(related_cfgs_ofcfg(
          make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
        , 0
        , TRUE
        )) AS a(x);

SELECT * FROM unnest(related_cfgs_ofcfg(
          make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
        , 10
        , TRUE
        )) AS a(x);

SELECT * FROM unnest(related_cfgs_ofcfg(
          make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
        , 1
        , TRUE
        )) AS a(x);
SELECT * FROM unnest(related_cfgs_ofcfg(
          make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
        , 20
        , TRUE
        )) AS a(x);
SELECT * FROM unnest(related_cfgs_ofcfg(
          make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
        , 2
        , TRUE
        )) AS a(x);
SELECT * FROM unnest(related_cfgs_ofcfg(
          make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
        , 22
        , TRUE
        )) AS a(x);

SELECT * FROM unnest((analyze_cfgs_tree(
                related_cfgs_ofcfg(
                  make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
                , 22
                , TRUE
                )
              , make_configkey_null()
              , TRUE
              , NULL :: integer
       )).sorted_by_depth);

SELECT * FROM unnest((analyze_cfgs_tree(
                related_cfgs_ofcfg(
                  make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
                , 22
                , TRUE
                )
              , make_configkey_null()
              , FALSE
              , NULL :: integer
       )).sorted_by_depth);

SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(
                related_cfgs_ofcfg(
                  make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
                , 22
                , TRUE
                )
              , make_configkey_null()
              , TRUE
              , NULL :: integer
       ))) AS x;

SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(
                related_cfgs_ofcfg(
                  make_configkey_bystr2('TC2_A_105', 'TC2_A_105_CFG1')
                , 22
                , TRUE
                )
              , make_configkey_null()
              , FALSE
              , NULL :: integer
       ))) AS x;
--------------------------------

SELECT *
FROM unnest(
        configs_that_use_subconfig(
                make_configkey_bystr2('TC2_G_105', 'TC2_G_105_CFG1')
              , FALSE
              , TRUE
              )
     );
SELECT *
FROM unnest(
       configs_that_use_subconfig(
                make_configkey_bystr2('TC2_G_105', 'TC2_G_105_CFG1')
              , TRUE
              , TRUE
              )
     );

--------------

SELECT *
FROM unnest(
       configs_that_rely_on_confentity_default(
                get_confentity_id('TC2_G_105')
              , FALSE
              , TRUE
              )
     );

SELECT *
FROM unnest(
       configs_that_rely_on_confentity_default(
                get_confentity_id('TC2_G_105')
              , TRUE
              , TRUE
              )
       );

--------------

SELECT *
FROM unnest(
       configs_that_use_subconfentity(
                get_confentity_id('TC2_G_105')
              , FALSE
              , TRUE
              )
     );
SELECT *
FROM unnest(
       configs_that_use_subconfentity(
                get_confentity_id('TC2_G_105')
              , TRUE
              , TRUE
              )
     );

--------------

SELECT *
FROM unnest(
       configs_related_with_confentity(
                get_confentity_id('TC2_G_105')
              , FALSE
              , TRUE
              )
     );
SELECT *
FROM unnest(
       configs_related_with_confentity(
                get_confentity_id('TC2_G_105')
              , TRUE
              , TRUE
              )
     );

--------------

SELECT *
FROM unnest(
       configs_related_with_confentity(
                get_confentity_id('Dummy_1_CE')
              , FALSE
              , TRUE
              )
     );
SELECT *
FROM unnest(
       configs_related_with_confentity(
                get_confentity_id('Dummy_1_CE')
              , TRUE
              , TRUE
              )
     );

-- Administration functions:
-- none

\echo NOTICE >>>>>>>>>>>> MEGACHECKS <<<<<<<<<<<<<<

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC1.#1 <<<<<<<<<<<<<<

SELECT *
FROM unnest(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC1_1_E1', 'TC1_1_E1_CFG')
                , 22
                , TRUE
                )
           ) as t
ORDER BY t.depth, t.super_cfg_id, t.sub_cfg_id;

SELECT * FROM unnest((analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC1_1_E1', 'TC1_1_E1_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , TRUE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC1_1_E1', 'TC1_1_E1_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , TRUE
           , NULL :: integer
       ))) AS x;

SELECT * FROM unnest((analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC1_1_E1', 'TC1_1_E1_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , FALSE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC1_1_E1', 'TC1_1_E1_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , FALSE
           , NULL :: integer
       ))) AS x;

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC1.#2 <<<<<<<<<<<<<<
\echo recheck with full test set

SELECT t.*
FROM unnest(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC1_1_E1', 'TC1_1_E1_CFG')
                , 22
                , TRUE
                )
           ) as t
   , test1__cparameters_values as t_cv
WHERE t_cv.super_ce_1 || '_CFG' = t.super_cfg_id
  AND t_cv.sub_ce_1   || '_CFG' = t.sub_cfg_id
  AND t_cv.testcase_id = 1
  AND (t_cv.error OR NOT t_cv.final_value_persists)
ORDER BY t.super_cfg_id, t.sub_cfg_id;

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC3.#1 <<<<<<<<<<<<<<

SELECT * FROM unnest((analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , TRUE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , TRUE
           , NULL :: integer
       ))) AS x;

SELECT * FROM unnest((analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , FALSE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_super', 'TC3_201_super_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , FALSE
           , NULL :: integer
       ))) AS x;

\echo NOTICE >>>>>>>>>>>> MEGACHECK >TC3.#1 <<<<<<<<<<<<<<

SELECT * FROM unnest((analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , TRUE
                )
           , make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
           , FALSE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , TRUE
                )
           , make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
           , FALSE
           , NULL :: integer
       ))) AS x;

SELECT * FROM unnest((analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , FALSE
                )
           , make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
           , FALSE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , FALSE
                )
           , make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
           , FALSE
           , NULL :: integer
       ))) AS x;

SELECT * FROM unnest((analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , TRUE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , TRUE
           , NULL :: integer
       ))) AS x;

SELECT * FROM unnest((analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , FALSE
           , NULL :: integer
       )).sorted_by_depth);
SELECT x.involved_in_cycles, x.dep_on_cycles
FROM unnest(array(SELECT analyze_cfgs_tree(
             related_cfgs_ofcfg(
                  make_configkey_bystr2('TC3_201_sub', 'TC3_201_sub_CFG')
                , 22
                , TRUE
                )
           , make_configkey_null()
           , FALSE
           , NULL :: integer
       ))) AS x;