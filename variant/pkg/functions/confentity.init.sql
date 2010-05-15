-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_confentity_key AS (confentity_codekeyl t_code_key_by_lng);

COMMENT ON TYPE t_confentity_key IS
'Wrapper around "t_code_key_by_lng" type.
';
--------------

CREATE OR REPLACE FUNCTION make_confentitykey(par_confentity_key t_code_key_by_lng) RETURNS t_confentity_key AS $$
        SELECT ROW($1) :: sch_<<$app_name$>>.t_confentity_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_confentitykey_null() RETURNS t_confentity_key AS $$
        SELECT ROW(make_codekeyl_null()) :: sch_<<$app_name$>>.t_confentity_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_confentitykey_bystr(par_confentity_str varchar) RETURNS t_confentity_key AS $$
        SELECT ROW(make_codekeyl_bystr($1)) :: sch_<<$app_name$>>.t_confentity_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_confentitykey_byid(par_confentity_id integer) RETURNS t_confentity_key AS $$
        SELECT ROW(make_codekeyl_byid($1)) :: sch_<<$app_name$>>.t_confentity_key;
$$ LANGUAGE SQL;

--------------

CREATE OR REPLACE FUNCTION code_id_of_confentitykey(par_confentity_key t_confentity_key) RETURNS integer AS $$
        SELECT ((($1).confentity_codekeyl).code_key).code_id;
$$ LANGUAGE SQL;

--------------

CREATE OR REPLACE FUNCTION confentity_is_null(par_confentity_key t_confentity_key) RETURNS boolean AS $$
        SELECT CASE WHEN $1 IS NULL THEN TRUE
                    WHEN sch_<<$app_name$>>.codekeyl_type(($1).confentity_codekeyl) = 'undef' THEN TRUE
                    ELSE FALSE
               END;
$$ LANGUAGE SQL;

--------------

CREATE OR REPLACE FUNCTION confentity_has_lng(par_confentity_key t_confentity_key) RETURNS boolean AS $$
        SELECT CASE WHEN sch_<<$app_name$>>.confentity_is_null($1) THEN FALSE
                    ELSE sch_<<$app_name$>>.codekey_type((($1).confentity_codekeyl).key_lng) != 'undef'
               END;
$$ LANGUAGE SQL;

--------------

CREATE OR REPLACE FUNCTION show_confentitykey(par_confentitykey t_confentity_key) RETURNS varchar AS $$
        SELECT '{t_confentity_key | '
            || ( CASE WHEN sch_<<$app_name$>>.confentity_is_null($1) THEN 'NULL'
                      ELSE (  CASE WHEN ($1).confentity_codekeyl IS NULL THEN ''
                                   ELSE 'confentity_codekeyl: ' || sch_<<$app_name$>>.show_codekeyl(($1).confentity_codekeyl) || ';'
                              END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL;

--------------

CREATE OR REPLACE FUNCTION optimized_confentitykey_isit(par_confentitykey t_confentity_key, par_opt_lng boolean) RETURNS boolean AS $$
        SELECT CASE WHEN sch_<<$app_name$>>.confentity_is_null($1) THEN FALSE
                    ELSE sch_<<$app_name$>>.optimized_codekeyl_isit(($1).confentity_codekeyl, 1 + 4 * ($2 :: integer))
               END;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION optimized_confentitykey_isit(par_confentitykey t_confentity_key, par_opt_lng boolean) IS
'If "par_opt_lng" is set to TRUE, then language key is checked to be optimized too. Else, is may be sufficient to have explicitly determined confentity code ID.
';

CREATE OR REPLACE FUNCTION optimized_confentitykey_isit(par_confentitykey t_confentity_key) RETURNS boolean AS $$
        SELECT sch_<<$app_name$>>.optimized_confentitykey_isit($1, sch_<<$app_name$>>.confentity_has_lng($1));
$$ LANGUAGE SQL;

COMMENT ON FUNCTION optimized_confentitykey_isit(par_confentitykey t_confentity_key) IS
'Wrapper around "optimized_confentitykey_isit(par_confentitykey t_confentity_key, par_opt_lng boolean)"
, with "par_opt_lng" argument set to equal "confentity_has_lng(par_confentitykey)".
';

--------------

-- problem cant know, if key was found for "par_ifexists = TRUE"
CREATE OR REPLACE FUNCTION optimize_confentitykey(par_ifexists boolean, par_confentitykey t_confentity_key) RETURNS t_confentity_key AS $$
DECLARE
        g sch_<<$app_name$>>.t_addressed_code_key_by_lng;
        n sch_<<$app_name$>>.t_code_key_by_lng;
        r sch_<<$app_name$>>.t_confentity_key;

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();
        -- raise notice '---------------->>>>>>>>>>>0> %', par_confentitykey;
        g:= optimize_acodekeyl(
                par_ifexists
              , generalize_codekeyl_wcf(
                        make_codekey_byid((get_nonplaincode_by_str('Configurable entities')).code_id) -- using integer ID here abstracts codifier from language
                      , par_confentitykey.confentity_codekeyl
                      )
              , 3 -- determination preference: code and language
              , 1 -- determination imperative: code
              );
        n:= make_codekeyl(g.key_lng, g.code_key);
        r:= make_confentitykey(n);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

---------------

CREATE OR REPLACE FUNCTION get_confentity_default(par_confentity_key t_confentity_key) RETURNS varchar AS $$
        SELECT default_configuration_id
        FROM sch_<<$app_name$>>.configurable_entities
        WHERE confentity_code_id = code_id_of_confentitykey(sch_<<$app_name$>>.optimize_confentitykey(FALSE, $1));
$$ LANGUAGE SQL;

---------------

CREATE OR REPLACE FUNCTION get_confentity_id(par_confentity_name varchar) RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(TRUE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Configurable entities', $1));
$$ LANGUAGE SQL;

---------------

CREATE OR REPLACE FUNCTION get_confentity_id(par_confentity_key t_confentity_key) RETURNS integer AS $$
DECLARE
        r integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        r:= NULL;
        CASE codekeyl_type($1.confentity_codekeyl)
            WHEN 'undef' THEN
            WHEN 'c_id'  THEN            r:= code_id_of_confentitykey($1);
            WHEN 'c_nm (-l,-cf)'    THEN r:= code_id_of(TRUE, generalize_codekeyl_wcf(make_codekey_bystr('Configurable entities'), ($1).confentity_codekeyl));
            WHEN 'c_nm (+l_id,-cf)' THEN r:= code_id_of(TRUE, generalize_codekeyl_wcf(make_codekey_bystr('Configurable entities'), ($1).confentity_codekeyl));
            WHEN 'c_nm (+l_nm,-cf)' THEN r:= code_id_of(TRUE, generalize_codekeyl_wcf(make_codekey_bystr('Configurable entities'), ($1).confentity_codekeyl));
            ELSE RAISE EXCEPTION 'Unsupported confentity key type: "%".', codekeyl_type($1.confentity_codekeyl);
        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_confentity_names(
          par_confentity_key t_confentity_key
        , par_names          name_construction_input[]
        ) RETURNS integer AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;

        rows_count_accum integer;
        rows_count_add   integer;

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        g:= optimize_confentitykey(FALSE, par_confentity_key);

        rows_count_accum:= 0;
        rows_count_add:= 0;

        SELECT add_code_lng_names(
                  TRUE -- if exists
                , generalize_codekeyl_wcf(make_codekey_bystr('Configurable entities'), g.confentity_codekeyl) -- target code
                , VARIADIC par_names
                )
        INTO rows_count_add;

        rows_count_accum:= rows_count_accum + rows_count_add;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_count_accum;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION add_confentity_names(
          par_confentity_key t_confentity_key
        , par_names      name_construction_input[]
        ) IS
'Returns count of rows modified.
';

------------------------

CREATE OR REPLACE FUNCTION new_confentity(
          par_name           varchar
        , par_ifdoesnt_exist boolean
        ) RETURNS integer AS $$
DECLARE
        r integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        r:= get_confentity_id(make_confentitykey_bystr(par_name));
        IF r IS NULL THEN
                r:= (add_subcodes_under_codifier(
                          make_codekeyl_bystr('Configurable entities')
                        , NULL :: varchar -- no default code
                        , VARIADIC ARRAY[ROW(par_name, 'plain code')] :: code_construction_input[]
                    )   )[1];
                INSERT INTO configurable_entities(confentity_code_id) VALUES (r);
        ELSIF NOT par_ifdoesnt_exist THEN
                RAISE EXCEPTION 'Configurable entity "%" already exists!', par_name;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_confentity(par_name varchar, par_ifdoesnt_exist boolean) IS
'Returns confentity ID.
If "par_ifdoesnt_exist"=FALSE and confentity already exists, an exception is rised.';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_confentity(
          par_name           varchar
        , par_ifdoesnt_exist boolean
        , par_lng_names      name_construction_input[]
        ) RETURNS integer AS $$
DECLARE
        target_confentity_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        target_confentity_id:= new_confentity(par_name, par_ifdoesnt_exist);

        PERFORM add_confentity_names(
                  make_confentitykey_byid(target_confentity_id)
                , ARRAY( SELECT mk_name_construction_input(
                                  a.lng
                                , a.name
                                , CASE WHEN codekeyl_type(a.entity) = 'undef'THEN
                                           make_codekeyl_bystr('configurable entity')
                                       ELSE a.entity
                                  END
                                , a.description
                                )
                         FROM unnest(par_lng_names) as a
                       )
                );

        PERFORM leave_schema_namespace(namespace_info);
        RETURN target_confentity_id;
END;
$$ LANGUAGE plpgsql;

------------------------------

CREATE TYPE t_confentity_param_wdelstats__short AS (ce_id integer, param_id varchar, deled integer);
CREATE TYPE t_cfg_wdelstats__short AS (cfg_id varchar, deled integer);

CREATE OR REPLACE FUNCTION delete_confentity(
                  par_ifexists                           boolean
                , par_confentity_key                     t_confentity_key

                , par_cascade_deinstan_referrers_params  boolean
                , par_cascade_del_configs                boolean
                , par_warn_with_list_of_referrers_params boolean
                , par_warn_with_list_of_configs          boolean
                , par_dont_modify_anything               boolean

                , par_cascade_setnull_ce_dflt            boolean
                , par_cascade_setnull_param_dflt         boolean
                , par_cascade_setnull_param_val          boolean
                , par_warn_with_list_of_ce_dflt_users    boolean
                , par_warn_with_list_of_param_dflt_users boolean
                , par_warn_with_list_of_param_val_users  boolean
                , par_dont_modify_any_config             boolean

                , par_cascade_setnull_subcfgrefernces    boolean
                , par_warn_with_list_of_subcfgrefernces  boolean
                , par_dont_modify_any_referrer_param     boolean
                ) RETURNS integer AS $$
DECLARE
        g sch_<<$app_name$>>.t_confentity_key;

        rows_count_accum integer;
        rows_count_add   integer;

        target_ce_id     integer;

        ref_params_act   varchar;
        cfgs_act         varchar;
        act_sum          varchar;

        ref_params_lst   sch_<<$app_name$>>.t_confentity_param_wdelstats__short[];
        cfgs_lst         sch_<<$app_name$>>.t_cfg_wdelstats__short[];

        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        g:= optimize_confentitykey(par_ifexists, par_confentity_key);
        IF par_ifexists THEN
            IF NOT optimized_confentitykey_isit(g) THEN
                RETURN 0;
            END IF;
        END IF;
        target_ce_id := code_id_of_confentitykey(g);

        rows_count_accum:= 0;
        rows_count_add  := 0;

        -----------------------

        -- deal with SUPERCONFIG PARAMETERS that use target as subconfentity
        ref_params_lst:= ARRAY(
                SELECT ROW( cp_s.confentity_code_id
                          , cp_s.parameter_id
                          , deinstaniate_confparam(
                                  make_confentityparamkey_bystr(
                                        cp_s.confentity_code_id
                                      , cp_s.parameter_id
                                      )
                                , par_cascade_setnull_subcfgrefernces
                                , par_warn_with_list_of_subcfgrefernces
                                , par_dont_modify_any_referrer_param OR par_dont_modify_anything OR NOT par_cascade_deinstan_referrers_params
                                )
                          ) :: t_confentity_param_wdelstats__short
                FROM configurations_parameters__subconfigs AS cp_s
                WHERE cp_s.subconfentity_code_id = target_ce_id
        );

        SELECT SUM(x.deled)
        FROM unnest(ref_params_lst) AS x -- t_confentity_param_wdelstats__short
        INTO rows_count_add;

        rows_count_accum:= rows_count_accum + rows_count_add;

        IF    par_cascade_deinstan_referrers_params
          AND par_warn_with_list_of_referrers_params
          AND NOT (  par_dont_modify_any_referrer_param
                  OR par_dont_modify_anything
                  )
        THEN    ref_params_act:= ' (superconfig parameter DEINSTANIATED)';
        ELSE    ref_params_act:= '';
        END IF;

        IF par_warn_with_list_of_referrers_params THEN
                ref_params_act:= 'Superconfigs parameters, that use target as subconfentity' || ref_params_act || ': ' || (ref_params_lst :: varchar) || '.';
        END IF;

        -- deal with CONFIGS of target confentity
        cfgs_lst:= ARRAY(
                SELECT ROW( c.configuration_id
                          , delete_config(
                                make_configkey(
                                        g
                                      , c.configuration_id
                                      , FALSE
                                      )
                              , par_cascade_setnull_ce_dflt
                              , par_cascade_setnull_param_dflt
                              , par_cascade_setnull_param_val
                              , par_warn_with_list_of_ce_dflt_users
                              , par_warn_with_list_of_param_dflt_users
                              , par_warn_with_list_of_param_val_users
                              , par_dont_modify_anything OR par_dont_modify_any_config OR NOT par_cascade_del_configs
                              )
                          ) :: t_cfg_wdelstats__short
                FROM configurations AS c
                WHERE c.confentity_code_id = target_ce_id
        );

        SELECT SUM(x.deled)
        FROM unnest(ref_params_lst) AS x -- t_cfg_wdelstats__short
        INTO rows_count_add;

        rows_count_accum:= rows_count_accum + rows_count_add;

        IF    par_cascade_del_configs
          AND par_warn_with_list_of_configs
          AND NOT (  par_dont_modify_any_config
                  OR par_dont_modify_anything
                  )
        THEN    cfgs_act:= ' (configs DELETED)';
        ELSE    cfgs_act:= '';
        END IF;

        IF par_warn_with_list_of_configs THEN
                cfgs_act:= 'Configs of target confentity' || cfgs_act || ': ' || (cfgs_lst :: varchar) || '.';
        END IF;

        ------------------------

        act_sum:= '';

        IF par_warn_with_list_of_referrers_params THEN act_sum:= act_sum || E'\n ** ' || ref_params_act;  END IF;
        IF par_warn_with_list_of_configs          THEN act_sum:= act_sum || E'\n ** ' || cfgs_act; END IF;
        IF act_sum != '' THEN
                act_sum:= 'Following items depend on target of configurable entity deletion:' || act_sum;
                RAISE WARNING '%', act_sum;
        END IF;

        -----------------------
        IF NOT par_dont_modify_anything THEN
                DELETE FROM configurable_entities WHERE confentity_code_id = target_ce_id;

                GET DIAGNOSTICS rows_count_add = ROW_COUNT;
                rows_count_accum:= rows_count_accum + rows_count_add;

                SELECT remove_code(
                                FALSE
                              , make_acodekeyl_byid(target_ce_id)
                              , TRUE -- par_remove_code boolean
                              , TRUE -- par_cascade_remove_subcodes
                              , TRUE -- par_if_cascade__only_ones_not_reachable_from_elsewhere
                              )
                INTO rows_count_add;

                rows_count_accum:= rows_count_accum + rows_count_add;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN rows_count_accum;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION delete_confentity(
                  par_ifexists                           boolean
                , par_confentity_key                     t_confentity_key
                , par_cascade_deinstan_referrers_params  boolean
                , par_cascade_del_configs                boolean
                , par_warn_with_list_of_referrers_params boolean
                , par_warn_with_list_of_configs          boolean
                , par_dont_modify_anything               boolean

                , par_cascade_setnull_ce_dflt            boolean
                , par_cascade_setnull_param_dflt         boolean
                , par_cascade_setnull_param_val          boolean
                , par_warn_with_list_of_ce_dflt_users    boolean
                , par_warn_with_list_of_param_dflt_users boolean
                , par_warn_with_list_of_param_val_users  boolean
                , par_dont_modify_any_config             boolean

                , par_cascade_setnull_subcfgrefernces    boolean
                , par_warn_with_list_of_subcfgrefernces  boolean
                , par_dont_modify_any_referrer_param     boolean
                ) IS
'Returns count of rows deleted (from all tables).
This function is really parameter-rich. The trick here, is that function relies on "delete_config" and "deinstaniate_confparam" - most part of "delete_confentity" parameters are just to be passed to them.
Parameters passed to "delete_config":
** par_cascade_setnull_ce_dflt            boolean
** par_cascade_setnull_param_dflt         boolean
** par_cascade_setnull_param_val          boolean
** par_warn_with_list_of_ce_dflt_users    boolean
** par_warn_with_list_of_param_dflt_users boolean
** par_warn_with_list_of_param_val_users  boolean
** par_dont_modify_any_config             boolean

Parameters passed to "deinstaniate_confparam":
** par_cascade_setnull_subcfgrefernces    boolean
** par_warn_with_list_of_subcfgrefernces  boolean
** par_dont_modify_any_referrer_param     boolean

If "par_cascade_dinstan_referrers_params" is FALSE, then following parameters are considered to be also FALSE:
** par_cascade_setnull_subcfgrefernces    boolean

If "par_cascade_del_configs" is FALSE, then following parameters are considered to be also FALSE:
** par_cascade_setnull_ce_dflt            boolean
** par_cascade_setnull_param_dflt         boolean
** par_cascade_setnull_param_val          boolean

Similar rules do NOT apply to "par_warn_with_list_of_referrers_params" and "par_warn_with_list_of_configs".
Parameter "par_dont_modify_anything", if TRUE then function won''t perform any UPDATE or DELETE action.
';

-----------------------------

CREATE OR REPLACE FUNCTION delete_confentity(
                  par_if_exists            boolean
                , par_confentity_key       t_confentity_key
                , par_cascade              boolean
                , par_dont_modify_anything boolean
                ) RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.delete_confentity(
                  $1
                , $2

                , $3   -- par_cascade_deinstan_referrers_params  boolean
                , $3   -- par_cascade_del_configs                boolean
                , TRUE -- par_warn_with_list_of_referrers_params boolean
                , TRUE -- par_warn_with_list_of_configs          boolean
                , $4

                , $3   -- par_cascade_setnull_ce_dflt            boolean
                , $3   -- par_cascade_setnull_param_dflt         boolean
                , $3   -- par_cascade_setnull_param_val          boolean
                , TRUE -- par_warn_with_list_of_ce_dflt_users    boolean
                , TRUE -- par_warn_with_list_of_param_dflt_users boolean
                , TRUE -- par_warn_with_list_of_param_val_users  boolean
                , $4

                , $3   -- par_cascade_setnull_subcfgrefernces    boolean
                , TRUE -- par_warn_with_list_of_subcfgrefernces  boolean
                , $4
                )
$$ LANGUAGE SQL;

COMMENT ON FUNCTION delete_confentity(
                  par_if_exists            boolean
                , par_confentity_key       t_confentity_key
                , par_cascade              boolean
                , par_dont_modify_anything boolean
                ) IS
'Simplifying wrapper around parameter abundant version of "delete_confentity".
This version will remove (if "par_dont_modify_anything" not TRUE) target confentity and all dependant items:
1. Deinstaniate parameters (of superconfigs) that use target as a subconfentity. All parameters values deleted by CASCADE.
1.1. Under same superconfentities set to NULL all references on deinstaniated parameters.
2. Delete all configurations under target confentity.
2.1. Set NULL target confetity default.
2.2. Set NULL to all references to target configuration superconfigs from parameters defaults.
2.3. Set NULL to all references to target configuration superconfigs from parameters values.
The report on all dependant items will be outputed with a set of WARNINGs.
';

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- GRANTS

-- Reference functions:
GRANT EXECUTE ON FUNCTION make_confentitykey(par_confentity_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_confentitykey_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_confentitykey_bystr(par_confentity_str varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_confentitykey_byid(par_confentity_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_confentitykey(par_confentity_key t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION confentity_is_null(par_confentity_key t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION confentity_has_lng(par_confentity_key t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_confentitykey(par_confentitykey t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_confentitykey_isit(par_confentitykey t_confentity_key, par_opt_lng boolean)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_confentitykey_isit(par_confentitykey t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Lookup functions:
GRANT EXECUTE ON FUNCTION optimize_confentitykey(par_ifexists boolean, par_confentitykey t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_confentity_default(par_confentity_key t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_confentity_id(par_confentity_name varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_confentity_id(par_confentity_key t_confentity_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Administration functions:
GRANT EXECUTE ON FUNCTION add_confentity_names(par_confentity_key t_confentity_key, par_names name_construction_input[]) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_confentity(par_name varchar, par_ifdoesnt_exist boolean) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_confentity(
          par_name           varchar
        , par_ifdoesnt_exist boolean
        , par_lng_names      name_construction_input[]
        ) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION delete_confentity(
                  par_ifexists                           boolean
                , par_confentity_key                     t_confentity_key
                , par_cascade_deinstan_referrers_params  boolean
                , par_cascade_del_configs                boolean
                , par_warn_with_list_of_referrers_params boolean
                , par_warn_with_list_of_configs          boolean
                , par_dont_modify_anything               boolean

                , par_cascade_setnull_ce_dflt            boolean
                , par_cascade_setnull_param_dflt         boolean
                , par_cascade_setnull_param_val          boolean
                , par_warn_with_list_of_ce_dflt_users    boolean
                , par_warn_with_list_of_param_dflt_users boolean
                , par_warn_with_list_of_param_val_users  boolean
                , par_dont_modify_any_config             boolean

                , par_cascade_setnull_subcfgrefernces    boolean
                , par_warn_with_list_of_subcfgrefernces  boolean
                , par_dont_modify_any_referrer_param     boolean
                ) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION delete_confentity(
                  par_if_exists            boolean
                , par_confentity_key       t_confentity_key
                , par_cascade              boolean
                , par_dont_modify_anything boolean
                ) TO user_<<$app_name$>>_data_admin;
