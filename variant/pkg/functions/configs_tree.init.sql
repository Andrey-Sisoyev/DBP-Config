-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> config_tree.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_cfg_tree_rel_type AS ENUM ('init', 'sce_user', 'ce_user', 'pv_user', 'p_val', 'p_dflt_val', 'p_lnk_val', 'p_lnk_dflt', 'ce_dflt');

COMMENT ON TYPE t_cfg_tree_rel_type IS
'Relation types in configs tree:
** init       - root relation, all other relations in a tree are populated from this one
** sce_user   - configs that use subconfentity
** ce_user    - configs that belong to confentity
** pv_user    - config  that use parameter value
** p_val      - superconfig parameter         value points on subconfig
** p_dflt_val - superconfig parameter default value points on subconfig
** p_lnk_val  - superconfig parameter         value, that references other superconfig parameter         value, both of them pointing on the same subconfig
** p_lnk_dflt - superconfig parameter default value, that references other superconfig parameter default value, both of them pointing on the same subconfig
** ce_dflt    - superconfig parameter has no value, nor default value specifies, but only subconfentity is known; subconfentity has default config

This type intersects with "t_cpvalue_final_source" - read it''s comments for the information about how resulting value is determined.
The distinction between two types is such, that "t_cfg_tree_rel_type" is about relations between configurations, but "t_cpvalue_final_source" is about determination of final value of parameter.
The relation between two types is expressed by the "finvalsrc2cfgtreerel" function.
';

-----------------------------

CREATE OR REPLACE FUNCTION cfg_tree_rel_main_types_set(par_with_lnks boolean) RETURNS t_cfg_tree_rel_type[] AS $$
        SELECT CASE $1 IS NOT DISTINCT FROM TRUE
                   WHEN TRUE THEN ARRAY['p_val' :: t_cfg_tree_rel_type, 'p_dflt_val', 'ce_dflt', 'p_lnk_val', 'p_lnk_dflt']
                   ELSE           ARRAY['p_val' :: t_cfg_tree_rel_type, 'p_dflt_val', 'ce_dflt']
               END;
$$ LANGUAGE SQL IMMUTABLE;

-----------------------------

CREATE OR REPLACE FUNCTION finvalsrc2cfgtreerel(par_finvalsrc t_cpvalue_final_source) RETURNS t_cfg_tree_rel_type AS $$
SELECT  CASE $1
            WHEN 'ce_dflt'    THEN 'ce_dflt'
            WHEN 'cp_dflt'    THEN 'p_dflt_val'
            WHEN 'cpv'        THEN 'p_val'
            WHEN 'cp_dflt_il' THEN 'p_lnk_dflt'
            WHEN 'cpv_il'     THEN 'p_lnk_val'
            WHEN 'null'       THEN NULL :: t_cfg_tree_rel_type
        END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION finvalsrcEQcfgtreerel(par_finvalsrc t_cpvalue_final_source, par_cfgtreerel t_cfg_tree_rel_type) RETURNS boolean AS $$
DECLARE r boolean;
BEGIN   IF par_finvalsrc IS NULL THEN r:= par_cfgtreerel IS NULL;
        ELSE
            CASE par_finvalsrc
                WHEN 'null' THEN r:= par_cfgtreerel IS NULL;
                ELSE r:= sch_<<$app_name$>>.finvalsrc2cfgtreerel(par_finvalsrc) IS NOT DISTINCT FROM par_cfgtreerel;
            END CASE;
        END IF;
        RETURN r;
END; $$ LANGUAGE plpgsql IMMUTABLE;

----------------------------

CREATE TYPE t_configs_tree_rel AS (
        super_ce_id    integer
      , super_cfg_id   varchar
      , super_param_id varchar
      , sub_ce_id      integer
      , sub_cfg_id     varchar
      , cfg_tree_rel_type
                       t_cfg_tree_rel_type
      , path           t_config_key[]
      , depth          integer  -- DFD(path)
      , cycle_detected boolean  -- DFD(path)
      , super_complete t_config_completeness_check_result
      , sub_complete   t_config_completeness_check_result
);

COMMENT ON TYPE t_configs_tree_rel IS
'
Field "depth" value:
** superconfig    - negative depth
** current config - zero     depth
** subconfig      - positive depth
Relation is between current and sub: zero
            between sub and subsub: 1
            between super and current: -1

Field "*_complete" value: if NULL, the not checked.
';

CREATE OR REPLACE FUNCTION mk_configs_tree_rel(
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
      ) RETURNS t_configs_tree_rel AS $$
      SELECT ROW( $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11 ) :: sch_<<$app_name$>>.t_configs_tree_rel;
$$ LANGUAGE SQL IMMUTABLE;

-----------------------

CREATE OR REPLACE FUNCTION cfg_idx_in_list(par_configkey t_config_key, par_config_list t_config_key[]) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE i integer; l integer; target_ce_id integer; target_cfg_id varchar; target_lnged_isit boolean; continue_ boolean;
        target_cfg_lng integer;
BEGIN   target_ce_id := sch_<<$app_name$>>.code_id_of_confentitykey(par_configkey.confentity_key);
        target_cfg_id:= par_configkey.config_id;
        target_lnged_isit:= par_configkey.cfgid_is_lnged;
        target_cfg_lng:= ((par_configkey.config_lng).code_key).code_id;

        SELECT s INTO i
        FROM generate_series(array_lower(par_config_list, 1),array_upper(par_config_list, 1)) AS s
        WHERE code_id_of_confentitykey((par_config_list[s]).confentity_key) IS NOT DISTINCT FROM target_ce_id
          AND ((par_config_list[s]).config_id      IS NOT DISTINCT FROM target_cfg_id)
          AND ((par_config_list[s]).cfgid_is_lnged IS NOT DISTINCT FROM target_lnged_isit)
          AND ((((par_config_list[s]).config_lng).code_key).code_id IS NOT DISTINCT FROM target_cfg_lng)
        LIMIT 1;

        RETURN i;
END;
$$;

COMMENT ON FUNCTION cfg_idx_in_list(par_configkey t_config_key, par_config_list t_config_key[]) IS '
Returns index of configkey (1st param) in given array (2nd param), or NULL, if not found.
All config-keys are assummed to have *optimized* confentity-keys - the search checks "confentity_code_id", - function won''t work properly for arguments containing nonoptimized confentity-keys.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION show_cfgtreerow_path(par_configs_tree t_configs_tree_rel) RETURNS varchar
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        i integer;
        l integer;
        r varchar;
BEGIN
        r:= '{';
        i:= 0;
        l:= array_length(par_configs_tree.path, 1);
        WHILE i < l LOOP
                i:= i + 1;
                r:= r
                 || '('
                 || sch_<<$app_name$>>.code_id_of_confentitykey(((par_configs_tree.path)[i]).confentity_key)
                 || ',"'
                 || ((par_configs_tree.path)[i]).config_id
                 || '")';
                IF i < l THEN
                        r:= r || '->';
                END IF;
        END LOOP;
        r:= r || '}';

        RETURN r;
END;
$$;

COMMENT ON FUNCTION show_cfgtreerow_path(par_configs_tree t_configs_tree_rel) IS '
Parameter "par_configs_tree" value is assummed to be an array of *optimized* config-keys. If any one is not or if array contains "NULL :: t_config_key", then the result of function will be NULL.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION super_cfgs_of(
                                par_config_tree_entry  t_configs_tree_rel
                              , par_value_source_types t_cfg_tree_rel_type[]
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g              sch_<<$app_name$>>.t_config_key;
        cur_layer_cfgs sch_<<$app_name$>>.t_configs_tree_rel[];
        il_itera_cfgs  sch_<<$app_name$>>.t_configs_tree_rel[];
        il_sesp_cfgs   sch_<<$app_name$>>.t_configs_tree_rel[];
        il_accum_cfgs  sch_<<$app_name$>>.t_configs_tree_rel[];
        cfgs_rope      sch_<<$app_name$>>.t_config_key[];
        l               integer;
        target_ce_id    integer;
        target_cfg_id   varchar;
        target_complete t_config_completeness_check_result;
BEGIN
    target_ce_id   := par_config_tree_entry.sub_ce_id;
    target_cfg_id  := par_config_tree_entry.sub_cfg_id;
    target_complete:= par_config_tree_entry.sub_complete;
    IF target_ce_id IS NULL OR target_cfg_id IS NULL THEN
        target_ce_id   := par_config_tree_entry.super_ce_id;
        target_cfg_id  := par_config_tree_entry.super_cfg_id;
        target_complete:= par_config_tree_entry.super_complete;
    END IF;

    IF target_ce_id IS NULL OR target_cfg_id IS NULL THEN
        RAISE EXCEPTION 'No config to start search from in the parameter: %.', par_config_tree_entry;
    END IF;

    g:= make_configkey(make_confentitykey_byid(target_ce_id), target_cfg_id, FALSE, make_codekeyl_null());
    cfgs_rope:= ARRAY[g] || par_config_tree_entry.path;

    cur_layer_cfgs:= ARRAY[] :: t_configs_tree_rel[]; -- := ARRAY[par_config_tree_entry]

    -- by value
    IF 'p_val' IN (SELECT * FROM unnest(par_value_source_types) AS z) THEN
        cur_layer_cfgs:= cur_layer_cfgs || ARRAY(
                SELECT mk_configs_tree_rel(
                                cpv_s.confentity_code_id
                              , cpv_s.configuration_id
                              , cpv_s.parameter_id
                              , target_ce_id
                              , target_cfg_id
                              , 'p_val' :: t_cfg_tree_rel_type
                              , cfgs_rope
                              , par_config_tree_entry.depth - 1
                              , cfg_idx_in_list(make_configkey(make_confentitykey_byid(cpv_s.confentity_code_id), cpv_s.configuration_id, FALSE, make_codekeyl_null()), cfgs_rope) IS NOT NULL
                              , cpv_s.complete_isit
                              , target_complete
                              )
                FROM (((configurations AS c
                           INNER JOIN
                        configurations_parameters AS cp_
                           USING (confentity_code_id)
                       ) AS cp_
                          INNER JOIN
                       configurations_parameters__subconfigs AS cp_s_
                          USING (confentity_code_id, parameter_id)
                      ) AS cp_s
                         INNER JOIN
                      configurations_parameters_values__subconfigs AS cpv_s_
                          USING (confentity_code_id, parameter_id, subconfentity_code_id, configuration_id)
                     ) AS cpv_s
                WHERE cpv_s.subconfentity_code_id = target_ce_id
                  AND cpv_s.subconfiguration_id IS NOT DISTINCT FROM target_cfg_id
                  AND cpv_s.subconfiguration_link_usage != 'alw_onl_lnk'
        );
    END IF;

    -- by parameter default
    IF 'p_dflt_val' IN (SELECT * FROM unnest(par_value_source_types) AS z) THEN
        cur_layer_cfgs:= cur_layer_cfgs || ARRAY(
                SELECT mk_configs_tree_rel(
                                cpv_s.confentity_code_id
                              , cpv_s.configuration_id
                              , cpv_s.parameter_id
                              , target_ce_id
                              , target_cfg_id
                              , 'p_dflt_val' :: t_cfg_tree_rel_type
                              , cfgs_rope
                              , par_config_tree_entry.depth - 1
                              , cfg_idx_in_list(make_configkey(make_confentitykey_byid(cpv_s.confentity_code_id), cpv_s.configuration_id, FALSE, make_codekeyl_null()), cfgs_rope) IS NOT NULL
                              , cpv_s.complete_isit
                              , target_complete
                              )
                FROM (((configurations AS c
                           INNER JOIN
                        configurations_parameters AS cp_
                           USING (confentity_code_id)
                       ) AS cp
                          INNER JOIN
                       configurations_parameters__subconfigs AS cp_s_
                          USING (confentity_code_id, parameter_id, parameter_type)
                      ) AS cp_s
                         LEFT OUTER JOIN
                      configurations_parameters_values__subconfigs AS cpv_s_
                          USING (confentity_code_id, parameter_id, configuration_id, subconfentity_code_id)
                     ) AS cpv_s
                WHERE CASE (    cpv_s.subconfentity_code_id      = target_ce_id
                           AND cpv_s.overload_default_subconfig = target_cfg_id
                           AND cpv_s.use_default_instead_of_null IN ('par_d', 'par_d_sce_d')
                           AND cpv_s.overload_default_link_usage != 'alw_onl_lnk'
                           )
                         WHEN FALSE THEN FALSE
                         ELSE CASE cpv_s.subconfiguration_link_usage IS NULL
                                  WHEN TRUE THEN TRUE
                                  ELSE CASE cpv_s.subconfiguration_link_usage
                                           WHEN 'no_lnk'        THEN
                                               cpv_s.subconfiguration_id   IS NULL
                                           WHEN 'alw_onl_lnk'   THEN
                                               (  cpv_s.subconfiguration_link IS NULL
                                               OR cparameter_finval_persists(
                                                    determine_finvalue_by_cop(
                                                        TRUE
                                                      , make_configparamkey(
                                                                        make_configkey(make_confentitykey_byid(cpv_s.confentity_code_id), cpv_s.configuration_id, FALSE, make_codekeyl_null())
                                                                      , cpv_s.parameter_id
                                                                      , FALSE
                                                                      )
                                                      )
                                                  , 'cp_dflt'
                                                  )
                                               ) -- this complexity occurs to be necessary, because we can't know, if final value of referenced parameter is NULL
                                           WHEN 'whn_vnull_lnk' THEN
                                               (   cpv_s.subconfiguration_id   IS NULL
                                               AND (  cpv_s.subconfiguration_link IS NULL
                                                   OR cparameter_finval_persists(
                                                        determine_finvalue_by_cop(
                                                            TRUE
                                                          , make_configparamkey(
                                                                            make_configkey(make_confentitykey_byid(cpv_s.confentity_code_id), cpv_s.configuration_id, FALSE, make_codekeyl_null())
                                                                          , cpv_s.parameter_id
                                                                          , FALSE
                                                                          )
                                                          )
                                                      , 'cp_dflt'
                                                      )
                                                   )
                                               )
                                       END
                              END
                      END
        );
    END IF;

    -- by confentity default
    IF 'ce_dflt' IN (SELECT * FROM unnest(par_value_source_types) AS z) THEN
        IF is_confentity_default(g) THEN
                cur_layer_cfgs:= cur_layer_cfgs || ARRAY(
                        SELECT mk_configs_tree_rel(
                                        cpv_s.confentity_code_id
                                      , cpv_s.configuration_id
                                      , cpv_s.parameter_id
                                      , target_ce_id
                                      , target_cfg_id
                                      , 'ce_dflt' :: t_cfg_tree_rel_type
                                      , cfgs_rope
                                      , par_config_tree_entry.depth - 1
                                      , cfg_idx_in_list(make_configkey(make_confentitykey_byid(cpv_s.confentity_code_id), cpv_s.configuration_id, FALSE, make_codekeyl_null()), cfgs_rope) IS NOT NULL
                                      , cpv_s.complete_isit
                                      , target_complete
                                      )
                        FROM (((configurations AS c
                                   INNER JOIN
                                configurations_parameters AS cp_
                                   USING (confentity_code_id)
                               ) AS cp
                                  INNER JOIN -- not "left outer", because subconfentity_code_id is needed
                               configurations_parameters__subconfigs AS cp_s_
                                  USING (confentity_code_id, parameter_id, parameter_type)
                              ) AS cp_s
                                 LEFT OUTER JOIN
                              configurations_parameters_values__subconfigs AS cpv_s_
                                  USING (confentity_code_id, parameter_id, configuration_id, subconfentity_code_id)
                             ) AS cpv_s
                        WHERE CASE (   cpv_s.subconfentity_code_id = target_ce_id
                                   AND cpv_s.use_default_instead_of_null IN ('sce_d', 'par_d_sce_d')
                                   )
                                  WHEN FALSE THEN FALSE
                                  ELSE
                                      CASE ( CASE cpv_s.subconfiguration_link_usage IS NULL
                                                 WHEN TRUE THEN 0
                                                 ELSE CASE cpv_s.subconfiguration_link_usage
                                                          WHEN 'no_lnk'        THEN
                                                              ((cpv_s.subconfiguration_id   IS NOT NULL) :: integer)
                                                          WHEN 'alw_onl_lnk'   THEN
                                                              ((cpv_s.subconfiguration_link IS NOT NULL) :: integer * 10)

                                                          WHEN 'whn_vnull_lnk' THEN
                                                              ((cpv_s.subconfiguration_id   IS NOT NULL) :: integer) +
                                                              ((cpv_s.subconfiguration_link IS NOT NULL) :: integer * 10)
                                                      END
                                             END
                                           )
                                          WHEN  1 THEN FALSE
                                          WHEN 11 THEN FALSE
                                          WHEN 10 THEN
                                              cparameter_finval_persists(
                                                determine_finvalue_by_cop(
                                                    TRUE
                                                  , make_configparamkey(
                                                                    make_configkey(make_confentitykey_byid(cpv_s.confentity_code_id), cpv_s.configuration_id, FALSE, make_codekeyl_null())
                                                                  , cpv_s.parameter_id
                                                                  , FALSE
                                                                  )
                                                  )
                                              , 'ce_dflt'
                                              )
                                          WHEN  0 THEN
                                              CASE ( CASE cpv_s.overload_default_link_usage
                                                         WHEN 'no_lnk'        THEN
                                                             ((cpv_s.overload_default_subconfig IS NOT NULL) :: integer)
                                                         WHEN 'alw_onl_lnk'   THEN
                                                             ((cpv_s.overload_default_link      IS NOT NULL) :: integer * 10)
                                                         WHEN 'whn_vnull_lnk' THEN
                                                             ((cpv_s.overload_default_subconfig IS NOT NULL) :: integer) +
                                                             ((cpv_s.overload_default_link      IS NOT NULL) :: integer * 10)
                                                     END
                                                   )
                                                  WHEN  1 THEN FALSE
                                                  WHEN 11 THEN FALSE
                                                  WHEN 10 THEN
                                                      cparameter_finval_persists(
                                                        determine_finvalue_by_cop(
                                                            TRUE
                                                          , make_configparamkey(
                                                                            make_configkey(make_confentitykey_byid(cpv_s.confentity_code_id), cpv_s.configuration_id, FALSE, make_codekeyl_null())
                                                                          , cpv_s.parameter_id
                                                                          , FALSE
                                                                          )
                                                          )
                                                      , 'ce_dflt'
                                                      )
                                                  WHEN  0 THEN TRUE
                                              END
                                      END
                              END
                );
        END IF;
    END IF;

    cur_layer_cfgs:= cur_layer_cfgs || subconfigparams_lnks_extraction(
                                                cur_layer_cfgs
                                              , par_value_source_types
                                              );
    RETURN cur_layer_cfgs;
END;
$$;

COMMENT ON FUNCTION super_cfgs_of(
                        par_config_tree_entry  t_configs_tree_rel
                      , par_value_source_types t_cfg_tree_rel_type[]
                      ) IS '
Field "par_value_source_types" regulates, whot types of subconfig relations to extract.
Takes "sub" part from given "par_config_tree_entry" and populates subconfigs. If "sub" part is NULL, takes "super" part - if it''s also NULL, an exception is rised.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sub_cfgs_of(
                                par_config_tree_entry  t_configs_tree_rel
                              , par_value_source_types t_cfg_tree_rel_type[]
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g               sch_<<$app_name$>>.t_config_key;
        ps              sch_<<$app_name$>>.t_cparameter_value_uni[];
        p               sch_<<$app_name$>>.t_cparameter_value_uni;
        cur_layer_cfgs  sch_<<$app_name$>>.t_configs_tree_rel[];
        cfgs_rope       sch_<<$app_name$>>.t_config_key[];
        ct_rel_type     sch_<<$app_name$>>.t_cfg_tree_rel_type;
        l               integer;
        i               integer;
        target_ce_id    integer;
        target_cfg_id   varchar;
        target_complete sch_<<$app_name$>>.t_config_completeness_check_result;
        sub_ce_id       integer;
        sub_cfg_id      varchar;
        sub_complete    sch_<<$app_name$>>.t_config_completeness_check_result;
BEGIN
        target_ce_id   := par_config_tree_entry.super_ce_id;
        target_cfg_id  := par_config_tree_entry.super_cfg_id;
        target_complete:= par_config_tree_entry.super_complete;
        IF target_ce_id IS NULL OR target_cfg_id IS NULL THEN
                target_ce_id   := par_config_tree_entry.sub_ce_id;
                target_cfg_id  := par_config_tree_entry.sub_cfg_id;
                target_complete:= par_config_tree_entry.sub_complete;
        END IF;
        IF target_ce_id IS NULL OR target_cfg_id IS NULL THEN
                RAISE EXCEPTION 'No config to start search from in the parameter: %.', par_config_tree_entry;
        END IF;

        g:= make_configkey(make_confentitykey_byid(target_ce_id), target_cfg_id, FALSE, make_codekeyl_null());
        cfgs_rope:= par_config_tree_entry.path || ARRAY[g];

        cur_layer_cfgs:= ARRAY[] :: t_configs_tree_rel[]; -- := ARRAY[par_config_tree_entry]

        ps:= get_paramvalues(TRUE, g);
        l:= array_length(ps, 1);
        i:= 0;
        WHILE i < l LOOP
            i:= i + 1;
            p:= ps[i];
            IF p.final_value IS NOT NULL AND (p.param_base).type = 'subconfig' THEN
                ct_rel_type:= finvalsrc2cfgtreerel(p.final_value_src);
                IF ct_rel_type IN (SELECT * FROM unnest(par_value_source_types) AS z) THEN
                    sub_ce_id     := (p.param_base).subconfentity_code_id;
                    sub_cfg_id    := p.final_value;
                    sub_complete  := read_completeness(make_configkey_bystr(sub_ce_id, sub_cfg_id));
                    cur_layer_cfgs:= cur_layer_cfgs ||
                        mk_configs_tree_rel(
                                target_ce_id
                              , target_cfg_id
                              , (p.param_base).param_id
                              , sub_ce_id
                              , sub_cfg_id
                              , ct_rel_type
                              , cfgs_rope
                              , par_config_tree_entry.depth + 1
                              , cfg_idx_in_list(make_configkey(make_confentitykey_byid(sub_ce_id), sub_cfg_id, FALSE, make_codekeyl_null()), cfgs_rope) IS NOT NULL
                              , target_complete
                              , sub_complete
                              );
                END IF;
            END IF;
        END LOOP;

        RETURN cur_layer_cfgs;
END;
$$;

COMMENT ON FUNCTION sub_cfgs_of(
                        par_config_tree_entry  t_configs_tree_rel
                      , par_value_source_types t_cfg_tree_rel_type[]
                      ) IS '
Field "par_value_source_types" regulates, what types of superconfig relations to extract.
Takes "super" part from given "par_config_tree_entry" and populates subconfigs. If "super" part is NULL, takes "sub" part - if it''s also NULL, an exception is rised.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION super_cfgs_of(
                                par_config_key         t_config_key
                              , par_value_source_types t_cfg_tree_rel_type[]
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_config_key;
        r sch_<<$app_name$>>.t_configs_tree_rel[];
BEGIN
        g:= optimize_configkey(par_config_key, FALSE);

        r:= super_cfgs_of(
              mk_configs_tree_rel(
                code_id_of_confentitykey(g.confentity_key)
              , g.config_id
              , NULL :: varchar
              , NULL :: integer
              , NULL :: varchar
              , 'init' :: t_cfg_tree_rel_type
              , ARRAY[] :: t_config_key[]
              , 1 -- wa
              , FALSE
              , read_completeness(g)
              , NULL :: t_config_completeness_check_result
              )
            , par_value_source_types
            );

        RETURN r;
END;
$$;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sub_cfgs_of(
                                par_config_key         t_config_key
                              , par_value_source_types t_cfg_tree_rel_type[]
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g sch_<<$app_name$>>.t_config_key;
        r sch_<<$app_name$>>.t_configs_tree_rel[];
        cpl sch_<<$app_name$>>.t_config_completeness_check_result;
BEGIN
        g:= optimize_configkey(par_config_key, FALSE);
        cpl:= read_completeness(g);
        r:= sub_cfgs_of(
              mk_configs_tree_rel(
                NULL :: integer
              , NULL :: varchar
              , NULL :: varchar
              , code_id_of_confentitykey(g.confentity_key)
              , g.config_id
              , 'init' :: t_cfg_tree_rel_type
              , ARRAY[] :: t_config_key[]
              , 0
              , FALSE
              , cpl
              , cpl
              )
            , par_value_source_types
            );

        RETURN r;
END;
$$;

--------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION subconfigparams_lnks_extraction(
                par_cfgs_tree          t_configs_tree_rel[]
              , par_value_source_types t_cfg_tree_rel_type[]
              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        il_itera_cfgs  sch_<<$app_name$>>.t_configs_tree_rel[];
        il_sesp_cfgs   sch_<<$app_name$>>.t_configs_tree_rel[];
        il_accum_cfgs  sch_<<$app_name$>>.t_configs_tree_rel[];
        l              integer;
BEGIN
        IF 'p_lnk_val' IN (SELECT * FROM unnest(par_value_source_types) AS z) OR 'p_lnk_dflt' IN (SELECT * FROM unnest(par_value_source_types) AS z) THEN
            il_itera_cfgs:= ARRAY[] :: t_configs_tree_rel[];
            il_accum_cfgs:= ARRAY[] :: t_configs_tree_rel[];
            il_sesp_cfgs:= par_cfgs_tree;
            l:= array_length(il_sesp_cfgs, 1);
            WHILE l > 0 LOOP
                -- by value, that is link to other parameter
                IF 'p_lnk_val' IN (SELECT * FROM unnest(par_value_source_types) AS z) THEN
                        il_itera_cfgs:= ARRAY(
                                SELECT mk_configs_tree_rel(
                                                ct.super_ce_id
                                              , ct.super_cfg_id
                                              , cpv_s.parameter_id -- <<
                                              , ct.sub_ce_id
                                              , ct.sub_cfg_id
                                              , 'p_lnk_val' :: t_cfg_tree_rel_type -- <<
                                              , ct.path
                                              , ct.depth
                                              , ct.cycle_detected
                                              , ct.super_complete
                                              , ct.sub_complete
                                              )
                                FROM unnest(il_sesp_cfgs) AS ct
                                   , configurations_parameters_values__subconfigs AS cpv_s
                                WHERE cpv_s.configuration_id      = ct.super_cfg_id
                                  AND cpv_s.confentity_code_id    = ct.super_ce_id
                                  AND cpv_s.subconfentity_code_id = ct.sub_ce_id
                                  AND cpv_s.subconfiguration_link = ct.super_param_id
                                  AND (   cpv_s.subconfiguration_link_usage IS NOT DISTINCT FROM 'alw_onl_lnk'
                                      OR (cpv_s.subconfiguration_link_usage IS NOT DISTINCT FROM 'whn_vnull_lnk' AND cpv_s.subconfiguration_id IS NULL)
                                      )
                        );
                END IF;

                -- by parameter default, that is link to other parameter
                IF 'p_lnk_dflt' IN (SELECT * FROM unnest(par_value_source_types) AS z) THEN
                        il_itera_cfgs:= il_itera_cfgs || ARRAY(
                                SELECT mk_configs_tree_rel(
                                                ct.super_ce_id
                                              , ct.super_cfg_id
                                              , cpv_s.parameter_id -- <<
                                              , ct.sub_ce_id
                                              , ct.sub_cfg_id
                                              , 'p_lnk_dflt' :: t_cfg_tree_rel_type -- <<
                                              , ct.path
                                              , ct.depth
                                              , ct.cycle_detected
                                              , ct.super_complete
                                              , ct.sub_complete
                                              )
                                FROM unnest(il_sesp_cfgs) AS ct
                                   , ((configurations AS c
                                         INNER JOIN
                                       configurations_parameters__subconfigs AS cp_s_
                                         USING (confentity_code_id)
                                      ) AS cp_s
                                        LEFT OUTER JOIN
                                      configurations_parameters_values__subconfigs AS cpv_s_
                                        USING (confentity_code_id, parameter_id, configuration_id, subconfentity_code_id)
                                     ) AS cpv_s
                                WHERE CASE (   cpv_s.configuration_id      = ct.super_cfg_id
                                           AND cpv_s.confentity_code_id    = ct.super_ce_id
                                           AND cpv_s.overload_default_link = ct.super_param_id
                                           AND cpv_s.subconfentity_code_id = ct.sub_ce_id
                                           AND (   cpv_s.overload_default_link_usage IS NOT DISTINCT FROM 'alw_onl_lnk'
                                               OR (cpv_s.overload_default_link_usage IS NOT DISTINCT FROM 'whn_vnull_lnk' AND cpv_s.overload_default_subconfig IS NULL)
                                               )
                                           ) -- here the case is complex, since we don't know, if "cpv_s_.subconfiguration_link" refers to any parameter that has NULL final value
                                          WHEN FALSE THEN FALSE
                                          ELSE ( SELECT (x.r1).final_value_src = 'cp_dflt_il' AND (x.r1).final_value IS NOT NULL
                                                 FROM (SELECT determine_finvalue_by_cop(
                                                                TRUE
                                                              , make_configparamkey(
                                                                                make_configkey(make_confentitykey_byid(ct.super_ce_id), ct.super_cfg_id, FALSE, make_codekeyl_null())
                                                                              , cpv_s.parameter_id
                                                                              , FALSE
                                                                              )
                                                              ) AS r1
                                                      ) AS x
                                               )
                                      END

                        );
                END IF;

                il_itera_cfgs:= ARRAY(
                        SELECT ROW(ct.*) :: t_configs_tree_rel
                        FROM unnest(il_itera_cfgs) AS ct
                        WHERE ROW(ct.super_ce_id, ct.super_cfg_id, ct.super_param_id, ct.cfg_tree_rel_type) NOT IN
                                ( SELECT cts_a.super_ce_id, cts_a.super_cfg_id, cts_a.super_param_id, cts_a.cfg_tree_rel_type
                                  FROM unnest(il_accum_cfgs) AS cts_a
                                )

                );
                il_accum_cfgs:= il_accum_cfgs || il_itera_cfgs;

                l:= array_length(il_itera_cfgs, 1);
                il_sesp_cfgs:= il_itera_cfgs;
            END LOOP;
        END IF;

        RETURN il_accum_cfgs;
END;
$$;

COMMENT ON FUNCTION subconfigparams_lnks_extraction(
                par_cfgs_tree          t_configs_tree_rel[]
              , par_value_source_types t_cfg_tree_rel_type[]
              ) IS '
Extract from the given configs tree nodes relations of type "p_lnk_val", "p_lnk_dflt" (see TYPE "t_cfg_tree_rel_type").
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION related_sub_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        start_cfg_tr  sch_<<$app_name$>>.t_configs_tree_rel;
        add_cfg_trs   sch_<<$app_name$>>.t_configs_tree_rel[];
        work_set      sch_<<$app_name$>>.t_configs_tree_rel[];
        new_work_set  sch_<<$app_name$>>.t_configs_tree_rel[];
        sub_results   sch_<<$app_name$>>.t_configs_tree_rel[];
        u             sch_<<$app_name$>>.t_configs_tree_rel;
        v             sch_<<$app_name$>>.t_configs_tree_rel;
        ws_size   integer;
        rez_size  integer;
        rez_size_add integer;
        was_cycle boolean;
        i  integer;
        j  integer;
        k  integer;
        l  integer;
        m  integer;
        n  integer;
        idx integer;
        rec RECORD;

        len_1 integer;
        idx_1 integer;
        rez_len integer;
        add_ct sch_<<$app_name$>>.t_configs_tree_rel;
        ex_ct sch_<<$app_name$>>.t_configs_tree_rel;
        cfg t_config_key;

        depth_changed_for     sch_<<$app_name$>>.t_configs_tree_rel[];
        depth_changed_for_new sch_<<$app_name$>>.t_configs_tree_rel[];
BEGIN
        start_cfg_tr:= par_cfg_tr;

        sub_results:= par_accum;
        was_cycle:= TRUE;
        -- dig subs first
        IF    par_recusive IS DISTINCT FROM TRUE THEN
                sub_results:= sub_results || sub_cfgs_of(start_cfg_tr, par_value_source_types);
        ELSE
                u:= start_cfg_tr;
                IF u.sub_ce_id IS NULL OR u.sub_cfg_id IS NULL THEN
                    u:= mk_configs_tree_rel(
                                NULL :: integer
                              , NULL :: varchar
                              , NULL :: varchar
                              , u.super_ce_id
                              , u.super_cfg_id
                              , NULL :: t_cfg_tree_rel_type
                              , u.path
                              , u.depth
                              , u.cycle_detected
                              , NULL :: t_config_completeness_check_result
                              , u.super_complete
                              );
                END IF;
                work_set:= ARRAY[u] :: t_configs_tree_rel[];

                ws_size:= 1;
                rez_size:= 0;
                WHILE ws_size > 0 LOOP
                        i:= 0;
                        add_cfg_trs := ARRAY[] :: t_configs_tree_rel[];
                        WHILE ws_size > i LOOP
                            i:= i + 1;
                            u:= work_set[i];
                            IF u.cycle_detected IS DISTINCT FROM TRUE THEN
                                    u:= mk_configs_tree_rel(
                                            u.sub_ce_id
                                          , u.sub_cfg_id
                                          , NULL :: varchar
                                          , NULL :: integer
                                          , NULL :: varchar
                                          , NULL :: t_cfg_tree_rel_type
                                          , u.path
                                          , u.depth
                                          , u.cycle_detected
                                          , u.sub_complete
                                          , NULL :: t_config_completeness_check_result
                                          );
                                    add_cfg_trs:= array_cat(add_cfg_trs, sub_cfgs_of(u, par_value_source_types));
                            END IF;
                        END LOOP;

                        add_cfg_trs:= ARRAY(
                               SELECT DISTINCT ON(x_.cycle_detected, x_.super_ce_id, x_.super_cfg_id, x_.sub_ce_id, x_.sub_cfg_id) -- removed x_.super_param_id
                                      ROW(x_.*) :: t_configs_tree_rel
                               FROM unnest(add_cfg_trs) AS x_ -- t_configs_tree_rel
                               ORDER BY x_.cycle_detected ASC, x_.super_ce_id, x_.super_cfg_id, x_.sub_ce_id, x_.sub_cfg_id, x_.depth DESC -- removed x_.super_param_id
                        );

                        work_set:= ARRAY[] :: t_configs_tree_rel[];
                        rez_size_add:= 0;
                        len_1:= coalesce(array_length(add_cfg_trs, 1), 0);
                        idx_1:= 0;

                        WHILE idx_1 < len_1 LOOP
                            idx_1 := idx_1 + 1;
                            add_ct:= add_cfg_trs[idx_1];

                            SELECT y.*
                            INTO ex_ct
                            FROM unnest(sub_results) AS y
                            WHERE y.cycle_detected = add_ct.cycle_detected
                              AND y.super_ce_id    = add_ct.super_ce_id
                              AND y.super_cfg_id   = add_ct.super_cfg_id
                              AND y.sub_ce_id      = add_ct.sub_ce_id
                              AND y.sub_cfg_id     = add_ct.sub_cfg_id;

                            IF ex_ct.depth IS NULL THEN
                                IF NOT add_ct.cycle_detected THEN
                                    work_set:= work_set   || add_ct;
                                END IF;
                                sub_results:= sub_results || add_ct;
                                rez_size_add:= rez_size_add + 1;
                            ELSIF add_ct.depth > ex_ct.depth THEN
                                i:= 0;
                                l:= array_length(sub_results, 1);
                                m:= 0;
                                WHILE i < l LOOP
                                    i:= i + 1;
                                    u:= sub_results[i];
                                    IF    u.sub_ce_id      = add_ct.sub_ce_id
                                      AND u.super_ce_id    = add_ct.super_ce_id
                                      AND u.sub_cfg_id     = add_ct.sub_cfg_id
                                      AND u.super_cfg_id   = add_ct.super_cfg_id
                                      AND u.cycle_detected = add_ct.cycle_detected
                                    THEN
                                        IF add_ct.depth > u.depth THEN
                                            u.path             := add_ct.path;
                                            u.depth            := add_ct.depth;
                                            u.super_param_id   := add_ct.super_param_id;
                                            u.cfg_tree_rel_type:= add_ct.cfg_tree_rel_type;
                                            u.cycle_detected   := add_ct.cycle_detected;
                                            m:= m + 1;
                                            sub_results[i]:= u;
                                            n:= i - rez_size;
                                            IF n > 0 THEN work_set[n]:= u; END IF;
                                        END IF;
                                    END IF;
                                END LOOP;

                                IF m > 0 THEN depth_changed_for:= ARRAY[add_ct]; k:= 1;
                                ELSE          depth_changed_for:= ARRAY[] :: t_configs_tree_rel[]; k:= 0;
                                END IF;

                                WHILE k > 0 LOOP
                                    depth_changed_for_new:= ARRAY[] :: t_configs_tree_rel[];
                                    i:= 0;
                                    rez_len:= rez_size + rez_size_add;
                                    l:= rez_len + len_1 - idx_1;
                                    WHILE i < l LOOP
                                        i:= i + 1;
                                        IF i <= rez_len THEN
                                             u:= sub_results[i];
                                        ELSE u:= add_cfg_trs[i - rez_len + idx_1];
                                        END IF;
                                        j:= 0;
                                        WHILE k > j LOOP
                                            j:= j + 1;
                                            v:= depth_changed_for[j];
                                            IF    v.sub_ce_id  = u.super_ce_id
                                              AND v.sub_cfg_id = u.super_cfg_id
                                              AND (v.depth + 1 > u.depth)
                                            THEN
                                                cfg:= make_configkey(make_confentitykey_byid(u.sub_ce_id), u.sub_cfg_id, FALSE, make_codekeyl_null());
                                                idx:= cfg_idx_in_list(cfg, v.path);
                                                IF idx IS NULL OR u.cycle_detected THEN -- no cycle in new formation
                                                    u.path             := v.path || cfg;
                                                    u.depth            := v.depth + 1;
                                                    u.cycle_detected   := NOT (idx IS NULL);
                                                    IF i <= rez_len THEN
                                                        sub_results[i]:= u;
                                                        n:= i - rez_size;
                                                        IF n > 0 THEN work_set[n]:= u; END IF;
                                                    ELSE
                                                        add_cfg_trs[i - rez_len + idx_1]:= u;
                                                    END IF;
                                                    IF NOT u.cycle_detected THEN
                                                        depth_changed_for_new:= depth_changed_for_new || u;
                                                    ELSE
                                                        sub_results:= sub_results || u;
                                                        rez_size_add:= rez_size_add + 1;
                                                        was_cycle:= TRUE;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        END LOOP;
                                    END LOOP;

                                    depth_changed_for:= depth_changed_for_new;
                                    k:= coalesce(array_length(depth_changed_for, 1), 0);
                                END LOOP;
                            END IF;
                        END LOOP;

                        rez_size:= rez_size + rez_size_add;
                        ws_size:= coalesce(array_length(work_set, 1), 0);
                END LOOP;
        END IF;

        IF was_cycle THEN
            sub_results:= ARRAY(
                SELECT DISTINCT ON(x_.cycle_detected, x_.super_ce_id, x_.super_cfg_id, x_.sub_ce_id, x_.sub_cfg_id)
                       ROW(x_.*) :: t_configs_tree_rel
                FROM unnest(sub_results) AS x_
                ORDER BY x_.cycle_detected ASC, x_.super_ce_id, x_.super_cfg_id, x_.sub_ce_id, x_.sub_cfg_id, x_.depth DESC
            );
        END IF;
        RETURN sub_results;
END;
$$;

COMMENT ON FUNCTION related_sub_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              ) IS
'If one same config-tree relation (superconfig, superconfig parameter, subconfig) occurs on different paths of configs relations graph, the populated from it further relations might occur to be identical in everything except for "path", "cycle_detected" and "depth" fields.
The resulting array will contain only one occurrence of each config-tree relation - one with no cycle and having maximal depth.

Uses function "sub_cfgs_of". Parameter "par_value_source_types" is applied to it.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION related_super_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        start_cfg_tr  sch_<<$app_name$>>.t_configs_tree_rel;
        add_cfg_trs   sch_<<$app_name$>>.t_configs_tree_rel[];
        work_set      sch_<<$app_name$>>.t_configs_tree_rel[];
        new_work_set  sch_<<$app_name$>>.t_configs_tree_rel[];
        super_results sch_<<$app_name$>>.t_configs_tree_rel[];
        u             sch_<<$app_name$>>.t_configs_tree_rel;
        v             sch_<<$app_name$>>.t_configs_tree_rel;
        i  integer;
        j  integer;
        k  integer;
        l  integer;
        m  integer;
        idx integer;
        rec RECORD;
BEGIN
        start_cfg_tr:= par_cfg_tr;
        super_results:= par_accum;
        -- dig supers
        start_cfg_tr.depth:= start_cfg_tr.depth + 1; -- small workaround
        IF    par_recusive IS DISTINCT FROM TRUE THEN
                super_results:= super_results || super_cfgs_of(start_cfg_tr, par_value_source_types);
        ELSE
                u:= start_cfg_tr;
                IF u.super_ce_id IS NULL OR u.super_cfg_id IS NULL THEN
                    u:= mk_configs_tree_rel(
                                u.sub_ce_id
                              , u.sub_cfg_id
                              , NULL :: varchar
                              , NULL :: integer
                              , NULL :: varchar
                              , NULL :: t_cfg_tree_rel_type
                              , u.path
                              , u.depth
                              , u.cycle_detected
                              , u.sub_complete
                              , NULL :: t_config_completeness_check_result
                              );
                END IF;
                work_set:= ARRAY[u] :: t_configs_tree_rel[];

                l:= 1;
                WHILE l > 0 LOOP
                        i:= 0;
                        add_cfg_trs := ARRAY[] :: t_configs_tree_rel[];

                        WHILE l > i LOOP
                            i:= i + 1;
                            u:= work_set[i];
                            IF u.cycle_detected IS DISTINCT FROM TRUE THEN
                                u:= mk_configs_tree_rel(
                                        NULL :: integer
                                      , NULL :: varchar
                                      , NULL :: varchar
                                      , u.super_ce_id
                                      , u.super_cfg_id
                                      , NULL :: t_cfg_tree_rel_type
                                      , u.path
                                      , u.depth
                                      , u.cycle_detected
                                      , NULL :: t_config_completeness_check_result
                                      , u.super_complete
                                      );
                                add_cfg_trs  := array_cat(add_cfg_trs, super_cfgs_of(u, par_value_source_types));
                            END IF;
                        END LOOP;

                        work_set:= ARRAY(
                                SELECT DISTINCT ON(x.super_ce_id, x.super_cfg_id, x.sub_ce_id, x.sub_cfg_id) -- removed x.super_param_id
                                       ROW(x.*) :: t_configs_tree_rel
                                FROM unnest(add_cfg_trs) AS x -- t_configs_tree_rel
                                WHERE ROW(x.super_ce_id, x.super_cfg_id, x.sub_ce_id, x.sub_cfg_id) NOT IN -- removed x.super_param_id
                                                ( SELECT y.super_ce_id, y.super_cfg_id, y.sub_ce_id, y.sub_cfg_id -- removed x.super_param_id
                                                  FROM unnest(super_results) AS y
                                                )
                                ORDER BY x.super_ce_id, x.super_cfg_id, x.sub_ce_id, x.sub_cfg_id, x.depth DESC, x.cycle_detected ASC -- removed x.super_param_id
                        );
                        super_results:= ARRAY(
                                SELECT DISTINCT ON(x.super_ce_id, x.super_cfg_id, x.sub_ce_id, x.sub_cfg_id) -- removed x.super_param_id
                                       ROW(x.*) :: t_configs_tree_rel
                                FROM unnest(add_cfg_trs || super_results) AS x -- t_configs_tree_rel
                                ORDER BY x.super_ce_id, x.super_cfg_id, x.sub_ce_id, x.sub_cfg_id, x.depth DESC, x.cycle_detected ASC -- removed x.super_param_id
                        );

                        l:= array_length(work_set, 1);
                END LOOP;
        END IF;

        RETURN super_results;
END;
$$;

COMMENT ON FUNCTION related_super_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              ) IS
'If one same config-tree relation (superconfig, superconfig parameter, subconfig) occurs on different paths of configs relations graph, the populated from it further relations might occur to be identical in everything except for "path", "cycle_detected" and "depth" fields.
The resulting array will contain only one occurrence of each config-tree relation - one with no cycle and having maximal depth.

Uses function "super_cfgs_of". Parameter "par_value_source_types" is applied to it.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION related_cfgs_ofcfg(
                                par_config_key               t_config_key
                              , par_mode                     integer
                              , par_populate_subconfig_links boolean
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE mode1 integer;
        mode2 integer;
        start_cfg    sch_<<$app_name$>>.t_config_key;
        results      sch_<<$app_name$>>.t_configs_tree_rel[];
        rel_types    sch_<<$app_name$>>.t_cfg_tree_rel_type[];
        start_cfg_tr sch_<<$app_name$>>.t_configs_tree_rel;
        cpl          sch_<<$app_name$>>.t_config_completeness_check_result;
BEGIN
        IF par_mode IS NULL THEN
                RAISE EXCEPTION 'Exception in "related_cfgs_ofcfg"! Mode is not allowed to be NULL!';
        ELSE IF par_mode NOT IN (0,1,10,11,20,21,22,12,2) THEN
                RAISE EXCEPTION 'Exception in "related_cfgs_ofcfg"! Mode is not supported: %!', par_mode;
        END IF; END IF;
        results:= ARRAY[] :: sch_<<$app_name$>>.t_configs_tree_rel[];
        IF par_mode = 0 THEN RETURN results; END IF;

        mode1:=     par_mode / 10;  -- super-
        mode2:= mod(par_mode , 10); -- sub-

        start_cfg:= optimize_configkey(par_config_key, FALSE);
        cpl:= read_completeness(start_cfg);
        start_cfg_tr:= mk_configs_tree_rel(
                                code_id_of_confentitykey(start_cfg.confentity_key)
                              , start_cfg.config_id
                              , NULL :: varchar
                              , code_id_of_confentitykey(start_cfg.confentity_key)
                              , start_cfg.config_id
                              , 'init' :: t_cfg_tree_rel_type
                              , ARRAY[] :: t_config_key[]
                              , 0
                              , FALSE
                              , cpl
                              , cpl
                              );
        rel_types:= cfg_tree_rel_main_types_set(par_populate_subconfig_links);

        IF mode1 > 0 THEN results:=            related_super_cfgs_ofcfg(start_cfg_tr, mode1 > 1, rel_types, ARRAY[] :: t_configs_tree_rel[]); END IF;
        IF mode2 > 0 THEN results:= results || related_sub_cfgs_ofcfg  (start_cfg_tr, mode2 > 1, rel_types, ARRAY[] :: t_configs_tree_rel[]); END IF;

        RETURN results;
END;
$$;

COMMENT ON FUNCTION related_cfgs_ofcfg(
                                par_config_key               t_config_key
                              , par_mode                     integer
                              , par_populate_subconfig_links boolean
                              ) IS
'Parameter "par_mode":
0x - don''t search for superconfigs
1x - search for superconfigs 1 layer deep
2x - search for all depth superconfigs
x0 - don''t search for subconfigs
x1 - search for subconfigs 1 layer deep
x2 - search for all depth subconfigs
Notice: for mode 22 function would recursively search in super- direction only other supers (but not subs), but in sub- direction only other subs (but not supers).


Wrapper around "related_sub_cfgs_ofcfg" and "related_super_cfgs_ofcfg" functions.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION configs_that_use_subconfig(
                                par_config_key t_config_key
                              , par_recursive boolean
                              , par_populate_subconfig_links boolean
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE r sch_<<$app_name$>>.t_configs_tree_rel[];
BEGIN   r:= related_cfgs_ofcfg(optimize_configkey(par_config_key), 10 + 10 * (par_recursive :: integer), par_populate_subconfig_links);
        RETURN r;
END;
$$;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION configs_that_rely_on_confentity_default(
                                par_confentity_code_id integer
                              , par_recursive boolean
                              , par_populate_subconfig_links boolean
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        rec RECORD;
        target_cfg_id   varchar := NULL;
        target_complete t_config_completeness_check_result := NULL;
        p sch_<<$app_name$>>.t_configs_tree_rel;
        q sch_<<$app_name$>>.t_configs_tree_rel[];
        r sch_<<$app_name$>>.t_configs_tree_rel[];
        rel_types    sch_<<$app_name$>>.t_cfg_tree_rel_type[];
BEGIN
        SELECT ce.default_configuration_id, c.complete_isit
        INTO target_cfg_id, target_complete
        FROM configurable_entities AS ce
           , configurations AS c
        WHERE ce.confentity_code_id = par_confentity_code_id
          AND ce.confentity_code_id = c.confentity_code_id
          AND ce.default_configuration_id = c.configuration_id;

        IF target_cfg_id IS NULL THEN
                r:= ARRAY[] :: t_configs_tree_rel[];

                RETURN r;
        ELSE
                rel_types:= cfg_tree_rel_main_types_set(par_populate_subconfig_links);
                q:= related_super_cfgs_ofcfg(
                        mk_configs_tree_rel(
                                par_confentity_code_id
                              , target_cfg_id
                              , NULL :: varchar
                              , NULL :: integer
                              , NULL :: varchar
                              , 'init' :: t_cfg_tree_rel_type
                              , ARRAY[make_configkey_bystr(par_confentity_code_id, target_cfg_id)]
                              , 0
                              , FALSE
                              , target_complete
                              , NULL :: t_config_completeness_check_result
                              )
                      , FALSE
                      , ARRAY['ce_dflt'] :: t_cfg_tree_rel_type[]
                      , ARRAY[] :: t_configs_tree_rel[]
                      );

                r:= q;

                IF par_recursive THEN
                        FOR rec IN SELECT ROW(cfg_t.*) :: t_configs_tree_rel AS r1
                                   FROM unnest(q) AS cfg_t
                        LOOP
                            p:= rec.r1;
                            p.depth:= p.depth - 1;
                            r:= related_super_cfgs_ofcfg(p, TRUE, rel_types, r);
                        END LOOP;
                END IF;

                RETURN r;
        END IF;
END;
$$;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION configs_that_use_subconfentity(
                                par_subconfentity_code_id integer
                              , par_recursive boolean
                              , par_populate_subconfig_links boolean
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        rec RECORD;
        p sch_<<$app_name$>>.t_configs_tree_rel;
        q sch_<<$app_name$>>.t_configs_tree_rel[];
        r sch_<<$app_name$>>.t_configs_tree_rel[];
        rel_types    sch_<<$app_name$>>.t_cfg_tree_rel_type[];
BEGIN
        r:= ARRAY(
                SELECT mk_configs_tree_rel(
                                c.confentity_code_id
                              , c.configuration_id
                              , cp_s.parameter_id
                              , par_subconfentity_code_id
                              , NULL :: varchar
                              , 'sce_user' :: t_cfg_tree_rel_type
                              , ARRAY[make_configkey_bystr(par_subconfentity_code_id, NULL :: varchar)] :: t_config_key[]
                              , 0 -- wa
                              , c.confentity_code_id = par_subconfentity_code_id
                              , c.complete_isit
                              , NULL :: t_config_completeness_check_result
                              )
                FROM configurations AS c
                   , configurations_parameters__subconfigs AS cp_s
                WHERE c.confentity_code_id = cp_s.confentity_code_id
                  AND cp_s.subconfentity_code_id = par_subconfentity_code_id
        );

        q:= r;

        rel_types:= cfg_tree_rel_main_types_set(par_populate_subconfig_links);
        IF par_recursive THEN
                FOR rec IN SELECT ROW(cfg_t.*) :: t_configs_tree_rel AS r1
                           FROM unnest(q) AS cfg_t
                LOOP
                    p:= rec.r1;
                    p.depth:= p.depth - 1;
                    r:= related_super_cfgs_ofcfg(p, TRUE, rel_types, r);
                END LOOP;
        END IF;

        RETURN r;
END;
$$;

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION configs_related_with_confentity(
                                par_confentity_id integer
                              , par_recursive     boolean
                              , par_populate_subconfig_links boolean
                              ) RETURNS t_configs_tree_rel[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        target_ce_id integer;
        rec RECORD;
        p sch_<<$app_name$>>.t_configs_tree_rel;
        q sch_<<$app_name$>>.t_configs_tree_rel[];
        r sch_<<$app_name$>>.t_configs_tree_rel[];
        rel_types    sch_<<$app_name$>>.t_cfg_tree_rel_type[];
BEGIN
        q:= ARRAY(
                SELECT mk_configs_tree_rel(
                                par_confentity_id
                              , c.configuration_id
                              , NULL :: varchar
                              , par_confentity_id
                              , c.configuration_id
                              , 'ce_user' :: t_cfg_tree_rel_type
                              , ARRAY[] :: t_config_key[]
                              , 0 -- wa
                              , FALSE
                              , c.complete_isit
                              , c.complete_isit
                              )
                FROM configurations AS c
                WHERE c.confentity_code_id = par_confentity_id
        );

        r:= q;

        rel_types:= cfg_tree_rel_main_types_set(par_populate_subconfig_links);
        IF par_recursive THEN
                FOR rec IN SELECT ROW(cfg_t.*) :: t_configs_tree_rel AS r1
                           FROM unnest(q) AS cfg_t
                LOOP
                    p:= rec.r1;
                    p.depth:= p.depth - 1;
                    r:= related_super_cfgs_ofcfg(p, TRUE, rel_types, r);
                END LOOP;
        END IF;

        RETURN r;
END;
$$;

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cfg_tree_2_cfgs(par_cfg_tree t_configs_tree_rel[], par_val_lng_code_id integer) RETURNS t_config_key[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE r       t_config_key[];
        val_lng t_code_key_by_lng;
BEGIN
        val_lng:= make_codekeyl_byid(par_val_lng_code_id);
        r:= ARRAY( SELECT make_configkey(
                                make_confentitykey_byid(cfg_ts.super_ce_id)
                              , cfg_ts.super_cfg_id
                              , FALSE
                              , val_lng
                              )
                   FROM unnest(par_cfg_tree) as cfg_ts
                   UNION
                   SELECT make_configkey(
                                make_confentitykey_byid(cfg_ts.sub_ce_id)
                              , cfg_ts.sub_cfg_id
                              , FALSE
                              , val_lng
                              )
                   FROM unnest(par_cfg_tree) as cfg_ts
        );

        r:= ARRAY(
                SELECT DISTINCT ON (
                          code_id_of_confentitykey((ROW(mc.*) :: t_config_key).confentity_key)
                        , mc.config_id
                        )
                       ROW(mc.*) :: t_config_key
                FROM unnest(r) AS mc
                ORDER BY code_id_of_confentitykey((ROW(mc.*) :: t_config_key).confentity_key) ASC
                       , mc.config_id ASC
        );

        RETURN r;
END;
$$;

-------------------------------------------------------------------------------

CREATE TYPE t_config_keys_list AS (list t_config_key[]);

CREATE TYPE t_analyzed_cfgs_set AS (
          involved_in_cycles t_config_key[]
        , dep_on_cycles      t_config_key[]
        , sorted_by_depth    t_config_keys_list[]
);

-- bad style programming here
CREATE OR REPLACE FUNCTION analyze_cfgs_tree(par_config_tree t_configs_tree_rel[], par_exclude_cfg t_config_key, par_asc_depth boolean, par_val_lng_id integer) RETURNS t_analyzed_cfgs_set
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        exclud_cfg   sch_<<$app_name$>>.t_config_key;
        sub          sch_<<$app_name$>>.t_config_key;
        cur          sch_<<$app_name$>>.t_config_key;
        super        sch_<<$app_name$>>.t_config_key;
        layer        sch_<<$app_name$>>.t_config_key[];
        used_cfgs    sch_<<$app_name$>>.t_config_key[];
        next_layer   sch_<<$app_name$>>.t_config_key[];
        ct_layer     sch_<<$app_name$>>.t_configs_tree_rel[];
        prev_layer_depth integer;
        cur_ct       sch_<<$app_name$>>.t_configs_tree_rel;
        new_work_set sch_<<$app_name$>>.t_configs_tree_rel[];
        work_set     sch_<<$app_name$>>.t_configs_tree_rel[];
        r            sch_<<$app_name$>>.t_analyzed_cfgs_set;
        extrm_depth integer;
        i integer;
        j integer;
        k integer;
        l integer;
        sub_idx   integer;
        super_idx integer;
        exclud_cfg_ce_id integer;
        exclud_cfg_id varchar;
        exclud_pers boolean;
        first_itera boolean;
        first_layer boolean;
        val_lng t_code_key_by_lng;

BEGIN
        IF par_asc_depth IS NULL THEN
                RAISE EXCEPTION 'Parameter "par_asc_depth" isn''t allowed to be NULL.';
        END IF;

        work_set:= par_config_tree;
        r:= ROW ( ARRAY[] :: t_config_key[]
                , ARRAY[] :: t_config_key[]
                , ARRAY[ ROW(ARRAY[] :: t_config_key[]) :: t_config_keys_list
                       ]
                ) :: t_analyzed_cfgs_set;
        exclud_pers:= FALSE;
        exclud_cfg_ce_id:= 0;
        exclud_cfg_id:= '';
        IF NOT config_is_null(par_exclude_cfg, TRUE) THEN
                exclud_pers:= TRUE;
                exclud_cfg:= optimize_configkey(par_exclude_cfg);
                exclud_cfg_ce_id:= code_id_of_confentitykey(exclud_cfg.confentity_key);
                exclud_cfg_id:= exclud_cfg.config_id;
        END IF;
        val_lng:= make_codekeyl_byid(par_val_lng_id);

        -- separate cycles from workset; handle "par_exclude_cfg" exclusion
        new_work_set:= ARRAY[] :: t_configs_tree_rel[];
        l:= array_length(work_set, 1);
        i:= 0;
        WHILE i < l LOOP
                i:= i + 1;
                cur_ct:= work_set[i];
                -- that's a bitof bad style, but... oh well..
                IF exclud_pers AND exclud_cfg_ce_id = cur_ct.sub_ce_id AND exclud_cfg_id = cur_ct.sub_cfg_id THEN
                        cur_ct.sub_ce_id := NULL;
                        cur_ct.sub_cfg_id:= NULL;
                END IF;
                IF exclud_pers AND exclud_cfg_ce_id = cur_ct.super_ce_id AND exclud_cfg_id = cur_ct.super_cfg_id THEN
                        cur_ct.super_ce_id := NULL;
                        cur_ct.super_cfg_id:= NULL;
                END IF;

                IF cur_ct.cycle_detected THEN
                        super:= make_configkey(make_confentitykey_byid(cur_ct.super_ce_id), cur_ct.super_cfg_id, FALSE, val_lng);
                        sub:=   make_configkey(make_confentitykey_byid(cur_ct.sub_ce_id  ), cur_ct.sub_cfg_id  , FALSE, val_lng);
                        sub_idx:=   cfg_idx_in_list(sub  , r.involved_in_cycles);
                        super_idx:= cfg_idx_in_list(super, r.involved_in_cycles);

                        IF sub_idx IS NULL THEN
                                r.involved_in_cycles:= sub   || r.involved_in_cycles;
                        END IF;

                        IF super_idx IS NULL THEN
                                r.involved_in_cycles:= super || r.involved_in_cycles;
                        END IF;

                        k:= array_length(cur_ct.path, 1);
                        j:= 0;
                        WHILE j < k LOOP
                                j:= j + 1;
                                cur:= (cur_ct.path)[j];
                                IF cfg_idx_in_list(cur, r.involved_in_cycles) IS NULL THEN
                                        r.involved_in_cycles:= cur || r.involved_in_cycles;
                                END IF;
                        END LOOP;
                ELSE
                        new_work_set:= new_work_set || cur_ct;
                END IF;
        END LOOP;
        work_set:= new_work_set;

        -- separate dependents on cycles from workset
        l:= 0;
        k:= array_length(work_set, 1);
        WHILE k != l LOOP
                l:= k;
                i:= 0;
                new_work_set:= ARRAY[] :: t_configs_tree_rel[];
                WHILE i < l LOOP
                        i:= i + 1;
                        cur_ct:= work_set[i];
                        super:= make_configkey(make_confentitykey_byid(cur_ct.super_ce_id), cur_ct.super_cfg_id, FALSE, val_lng);
                        sub:=   make_configkey(make_confentitykey_byid(cur_ct.sub_ce_id  ), cur_ct.sub_cfg_id  , FALSE, val_lng);
                        sub_idx:=   cfg_idx_in_list(sub  , r.involved_in_cycles);
                        super_idx:= cfg_idx_in_list(super, r.involved_in_cycles);
                        IF sub_idx IS NULL THEN
                                IF super_idx IS NOT NULL THEN
                                        cur_ct.super_ce_id := NULL;
                                        cur_ct.super_cfg_id:= NULL;
                                END IF;

                                sub_idx  := cfg_idx_in_list(sub  , r.dep_on_cycles);
                                super_idx:= cfg_idx_in_list(super, r.dep_on_cycles);

                                IF sub_idx IS NULL THEN
                                        IF super_idx IS NOT NULL THEN
                                                cur_ct.super_ce_id := NULL;
                                                cur_ct.super_cfg_id:= NULL;
                                        END IF;

                                        new_work_set:= new_work_set || cur_ct;
                                ELSIF super_idx IS NULL THEN
                                        r.dep_on_cycles:= super || r.dep_on_cycles;
                                END IF;

                        ELSIF super_idx IS NULL THEN
                                r.dep_on_cycles:= super || r.dep_on_cycles;
                        END IF;
                END LOOP;
                work_set:= new_work_set;
                k:= array_length(work_set, 1);
        END LOOP;

        -- sort configs by depth
        l:= array_length(work_set, 1);
        first_itera:= TRUE;
        first_layer:= TRUE;
        next_layer:= ARRAY[] :: t_config_key[];
        used_cfgs := ARRAY[] :: t_config_key[];
        WHILE l > 0 LOOP

                i:= 0;
                IF      first_itera THEN extrm_depth:= work_set[1].depth; first_itera:= FALSE;
                ELSIF par_asc_depth THEN extrm_depth:= prev_layer_depth + 1;
                ELSE                     extrm_depth:= prev_layer_depth - 1; END IF;
                new_work_set:= ARRAY[] :: t_configs_tree_rel[];
                ct_layer    := ARRAY[] :: t_configs_tree_rel[];
                WHILE i < l LOOP
                    i:= i + 1;
                    cur_ct:= work_set[i];
                    IF cur_ct.depth > extrm_depth THEN
                        IF NOT par_asc_depth THEN -- descending
                             new_work_set:= new_work_set || ct_layer; ct_layer:= ARRAY[cur_ct];
                             extrm_depth:= cur_ct.depth;
                        ELSE new_work_set:= new_work_set || cur_ct;
                        END IF;
                    ELSIF cur_ct.depth < extrm_depth THEN
                        IF par_asc_depth THEN -- ascending
                             new_work_set:= new_work_set || ct_layer; ct_layer:= ARRAY[cur_ct];
                             extrm_depth:= cur_ct.depth;
                        ELSE new_work_set:= new_work_set || cur_ct;
                        END IF;
                    ELSE -- cur_ct.depth = extrm_depth
                        ct_layer:= ct_layer || cur_ct;
                    END IF;
                END LOOP;
                prev_layer_depth:= extrm_depth;

                l:= array_length(ct_layer, 1);
                i:= 0;
                layer:= next_layer;
                next_layer:= ARRAY[] :: t_config_key[];
                WHILE i < l LOOP
                    i:= i + 1;
                    cur_ct:= ct_layer[i];
                    IF cur_ct.super_ce_id IS NOT NULL AND cur_ct.super_cfg_id IS NOT NULL THEN
                        super:= make_configkey(make_confentitykey_byid(cur_ct.super_ce_id), cur_ct.super_cfg_id, FALSE, val_lng);
                        IF cfg_idx_in_list(super, used_cfgs) IS NULL THEN
                                used_cfgs:= used_cfgs || super;
                                IF par_asc_depth THEN -- ascending
                                    super_idx:= cfg_idx_in_list(super, layer);
                                    IF super_idx IS NULL THEN
                                        layer:= layer || super;
                                    END IF;
                                ELSE -- descending
                                    super_idx:= cfg_idx_in_list(super, next_layer);
                                    IF super_idx IS NULL THEN
                                        next_layer:= next_layer || super;
                                    END IF;
                                END IF;
                        END IF;
                    END IF;
                    IF cur_ct.sub_ce_id   IS NOT NULL AND cur_ct.sub_cfg_id   IS NOT NULL THEN
                        sub  := make_configkey(make_confentitykey_byid(cur_ct.sub_ce_id  ), cur_ct.sub_cfg_id  , FALSE, val_lng);
                        IF cfg_idx_in_list(sub, used_cfgs) IS NULL THEN
                                used_cfgs:= used_cfgs || sub;
                                IF par_asc_depth THEN -- ascending
                                    sub_idx:= cfg_idx_in_list(sub, next_layer);
                                    IF sub_idx IS NULL THEN
                                        next_layer:= next_layer || sub;
                                    END IF;
                                ELSE -- descending
                                    sub_idx:= cfg_idx_in_list(sub, layer);
                                    IF sub_idx IS NULL THEN
                                        layer:= layer || sub;
                                    END IF;
                                END IF;
                        END IF;
                    END IF;
                END LOOP;

                IF COALESCE(array_length(layer, 1), 0) > 0 THEN
                    IF first_layer THEN
                        first_layer:= FALSE;
                        r.sorted_by_depth:= ARRAY[ROW(layer) :: t_config_keys_list];
                    ELSE
                        r.sorted_by_depth:= r.sorted_by_depth || (ROW(layer) :: t_config_keys_list);
                    END IF;
                END IF;

                work_set:= new_work_set;
                l:= COALESCE(array_length(work_set, 1), 0);
                IF l = 0 THEN l:= COALESCE(array_length(next_layer, 1), 0); END IF;
        END LOOP;

        RETURN r;
END;
$$;

COMMENT ON FUNCTION analyze_cfgs_tree(par_config_tree t_configs_tree_rel[], par_exclude_cfg t_config_key, par_asc_depth boolean, par_val_lng_id integer) IS
'Makes a set of "t_config_key" from a set of "t_configs_tree_rel".
Phases:
1. All configs that participate in cycles are separated from input. The participation is detected by field "cycle_detected", but not "super_complete" or "sub_complete"!
2. All configs that depend on participants in cycles are separated from input (whats left after step 1). A config depends on another, if it is it''s superconfig (of any depth).
3. What''s left from input after steps 1 and 2 is sorted by depth. No duplicates. The topmost duplicate will be kept, but lower ones - discarded.

Performance is poor, if there are big gaps between depths, due to specific ordering algorithm.';


--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- GRANTS

-- Reference functions:
GRANT EXECUTE ON FUNCTION finvalsrc2cfgtreerel(par_finvalsrc t_cpvalue_final_source)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION finvalsrcEQcfgtreerel(par_finvalsrc t_cpvalue_final_source, par_cfgtreerel t_cfg_tree_rel_type)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION cfg_tree_rel_main_types_set(par_with_lnks boolean)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION mk_configs_tree_rel(
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
      )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_cfgtreerow_path(par_configs_tree t_configs_tree_rel)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-- Analytic functions:
GRANT EXECUTE ON FUNCTION cfg_idx_in_list(par_configkey t_config_key, par_config_list t_config_key[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION cfg_tree_2_cfgs(par_cfg_tree t_configs_tree_rel[], par_val_lng_code_id integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION analyze_cfgs_tree(par_config_tree t_configs_tree_rel[], par_exclude_cfg t_config_key, par_asc_depth boolean, par_val_lng_id integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-- Lookup functions:
GRANT EXECUTE ON FUNCTION super_cfgs_of(par_config_key t_config_key, par_value_source_types t_cfg_tree_rel_type[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION sub_cfgs_of(par_config_key t_config_key, par_value_source_types t_cfg_tree_rel_type[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION super_cfgs_of(par_config_tree_entry t_configs_tree_rel, par_value_source_types t_cfg_tree_rel_type[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION sub_cfgs_of(par_config_tree_entry t_configs_tree_rel, par_value_source_types t_cfg_tree_rel_type[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION subconfigparams_lnks_extraction(par_cfgs_tree t_configs_tree_rel[], par_value_source_types t_cfg_tree_rel_type[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION related_super_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION related_sub_cfgs_ofcfg(
                                par_cfg_tr             t_configs_tree_rel
                              , par_recusive           boolean
                              , par_value_source_types t_cfg_tree_rel_type[]
                              , par_accum              t_configs_tree_rel[]
                              ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION related_cfgs_ofcfg(
        par_config_key               t_config_key
      , par_mode                     integer
      , par_populate_subconfig_links boolean
      )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION configs_that_use_subconfig(
        par_config_key t_config_key
      , par_recursive boolean
      , par_populate_subconfig_links boolean
      )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION configs_that_rely_on_confentity_default(
        par_confentity_code_id integer
      , par_recursive boolean
      , par_populate_subconfig_links boolean
      )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION configs_that_use_subconfentity(
        par_subconfentity_code_id integer
      , par_recursive boolean
      , par_populate_subconfig_links boolean
      )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION configs_related_with_confentity(
        par_confentity_id integer
      , par_recursive     boolean
      , par_populate_subconfig_links boolean
      )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-- Administration functions:
-- none

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> config_tree.init.sql [END]