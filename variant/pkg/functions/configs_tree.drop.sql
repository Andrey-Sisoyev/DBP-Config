-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Reference functions:
DROP FUNCTION IF EXISTS finvalsrc2cfgtreerel(par_finvalsrc t_cpvalue_final_source);
DROP FUNCTION IF EXISTS finvalsrcEQcfgtreerel(par_finvalsrc t_cpvalue_final_source, par_cfgtreerel t_cfg_tree_rel_type);
DROP FUNCTION IF EXISTS cfg_tree_rel_main_types_set(par_with_lnks boolean);
DROP FUNCTION IF EXISTS mk_configs_tree_rel(
        par_super_ce_id    integer
      , par_super_cfg_id   varchar
      , par_super_param_id varchar
      , par_sub_ce_id      integer
      , par_sub_cfg_id     varchar
      , par_cfg_tree_rel_type
                           t_cfg_tree_rel_type
      , par_path           t_config_key[]
      , par_depth          integer
      , par_cycle_detected boolean
      , par_super_complete t_config_completeness_check_result
      , par_sub_complete   t_config_completeness_check_result
      );
DROP FUNCTION IF EXISTS show_cfgtreerow_path(par_configs_tree t_configs_tree_rel);


-- Analytic functions:
DROP FUNCTION IF EXISTS cfg_idx_in_list(par_configkey t_config_key, par_config_list t_config_key[]);
DROP FUNCTION IF EXISTS cfg_tree_2_cfgs(par_cfg_tree t_configs_tree_rel[]);
DROP FUNCTION IF EXISTS analyze_cfgs_tree(par_config_tree t_configs_tree_rel[], par_exclude_cfg t_config_key, par_asc_depth boolean);

-- Lookup functions:
DROP FUNCTION IF EXISTS super_cfgs_of(par_config_key t_config_key, par_value_source_types t_cfg_tree_rel_type[]);
DROP FUNCTION IF EXISTS sub_cfgs_of(par_config_key t_config_key, par_value_source_types t_cfg_tree_rel_type[]);
DROP FUNCTION IF EXISTS super_cfgs_of(par_config_tree_entry t_configs_tree_rel, par_value_source_types t_cfg_tree_rel_type[]);
DROP FUNCTION IF EXISTS sub_cfgs_of(par_config_tree_entry t_configs_tree_rel, par_value_source_types t_cfg_tree_rel_type[]);
DROP FUNCTION IF EXISTS subconfigparams_lnks_extraction(par_cfgs_tree t_configs_tree_rel[], par_value_source_types t_cfg_tree_rel_type[]);
DROP FUNCTION IF EXISTS related_super_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              );
DROP FUNCTION IF EXISTS related_sub_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              );
DROP FUNCTION IF EXISTS related_cfgs_ofcfg(
        par_config_key               t_config_key
      , par_mode                     integer
      , par_populate_subconfig_links boolean
      );
DROP FUNCTION IF EXISTS configs_that_use_subconfig(
        par_config_key t_config_key
      , par_recursive boolean
      , par_populate_subconfig_links boolean
      );
DROP FUNCTION IF EXISTS configs_that_rely_on_confentity_default(
        par_confentity_code_id integer
      , par_recursive boolean
      , par_populate_subconfig_links boolean
      );
DROP FUNCTION IF EXISTS configs_that_use_subconfentity(
        par_subconfentity_code_id integer
      , par_recursive boolean
      , par_populate_subconfig_links boolean
      );
DROP FUNCTION IF EXISTS configs_related_with_confentity(
        par_confentity_id integer
      , par_recursive     boolean
      , par_populate_subconfig_links boolean
      );

-- Administration functions:
-- none

------------------------
-- Types

DROP TYPE IF EXISTS t_analyzed_cfgs_set;
DROP TYPE IF EXISTS t_config_keys_list;
DROP TYPE IF EXISTS t_configs_tree_rel_cycles_filtered;
DROP TYPE IF EXISTS t_configs_tree_rel;
DROP TYPE IF EXISTS t_cfg_tree_rel_type;
