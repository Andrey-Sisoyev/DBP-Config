-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> completeness.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_thorough_report_warning_mode AS ENUM ('WHEN LOSING COMPLETENESS', 'ALWAYS', 'NEVER');

COMMENT ON TYPE t_thorough_report_warning_mode IS
'The parameter says whether to output completeness check report as a WARNING or not. Report is never outputed for light checks.
Possible values:
** "ALWAYS" - when completeness check is performed, always output a WARNING with report about check results
** "WHEN LOSING COMPLETENESS" - this concerns cases, when config was complete, but becomes incomplete in the result of completeness check; also fo case, when config is not found
** "NEVER"
Notice: used by the "config_completeness" function.
';
---------------

CREATE OR REPLACE FUNCTION completeness_interpretation(par_completeness t_config_completeness_check_result) RETURNS boolean AS $$
DECLARE r boolean;
BEGIN
        CASE par_completeness
            WHEN 'th_chk_V' THEN r:= TRUE;
            WHEN 'th_chk_X' THEN r:= FALSE;
            WHEN 'li_chk_V' THEN r:= TRUE;
            WHEN 'li_chk_X' THEN r:= FALSE;
            WHEN 'nf_X' THEN r:= FALSE;
            WHEN 'cy_X' THEN r:= FALSE;
            WHEN 'le_V' THEN r:= TRUE;
            ELSE RAISE EXCEPTION 'An error occurred in function "completeness_interpretation" for argument "%"! Unsupported argument.', par_completeness;
        END CASE;
        RETURN r;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

---------------

CREATE OR REPLACE FUNCTION show_completeness_check_result(par_completeness t_config_completeness_check_result) RETURNS varchar AS $$
DECLARE r varchar;
BEGIN   CASE par_completeness
            WHEN 'th_chk_V' THEN r:= 'thorough check successful';
            WHEN 'th_chk_X' THEN r:= 'thorough check failed';
            WHEN 'li_chk_V' THEN r:= 'light check successful';
            WHEN 'li_chk_X' THEN r:= 'light check failed';
            WHEN 'nf_X' THEN r:= 'config not found - fail';
            WHEN 'cy_X' THEN r:= 'cycles not supported - failure';
            WHEN 'le_V' THEN r:= 'skipped - N/A to leaf';
            ELSE RAISE EXCEPTION 'An error occurred in function "show_completeness_check_result" for argument "%"! Unsupported argument.', par_completeness;
        END CASE;
        RETURN r;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

---------------------------------------------------

CREATE TYPE t_completeness_check_row AS (
        confentity_code_id integer
      , config_id          varchar
      , param_value        t_cparameter_value_uni

      , cc_null_cnstr_passed_ok    boolean
      , cc_cnstr_array_failure_idx integer
      , cc_subconfig_is_complete   t_config_completeness_check_result
      );

COMMENT ON TYPE t_completeness_check_row IS
'Fields "cc_subconfig_is_complete", "cc_null_cnstr_passed_ok" and "cc_cnstr_array_failure_idx" stores check results.
If result-field = NULL, then apropriate check was never performed.

Field "cc_null_cnstr_passed_ok" values:
** NULL means "no check performed"

Field "cc_cnstr_array_failure_idx" values:
** NULL means "no check performed"
** -1 means "all user-defined constraints are respected"
**  0 means "check skipped due to violation of NOT NULL constraint"
**  X (some positive number) means index of constraint in the ".param_value.param_base.constraints_array", that is violated.
Notice #2: if NOT NULL constraint imposed on current field is not checked (NULL), then subconfig check won''t ever skip and return 0.

Field "cc_subconfig_is_complete" values:
** NULL means "no check performed"
Notice #1: *light* completeness check simply reads "configurations.complete_isit" field of subconfig
           , while *thorough* check involves performance of full-scale procedure of checking subparameters on NOT NULLs, user defined constraints and (to some extent) recursively *thorough* check of subsubconfigs.
Notice #2: if NOT NULL constraint or user-defined constraint imposed on current field are not checked (NULLs), then subconfig check won''t ever skip and return -1.
';

CREATE OR REPLACE FUNCTION mk_completeness_precheck_row(
        par_confentity_code_id integer
      , par_config_id          varchar
      , par_param_value        t_cparameter_value_uni
      , par_cc_null_cnstr_passed_ok    boolean
      , par_cc_cnstr_array_failure_idx integer
      , par_cc_subconfig_is_complete   t_config_completeness_check_result
      ) RETURNS t_completeness_check_row AS $$
        SELECT ROW ($1,$2,$3,$4,$5,$6) :: sch_<<$app_name$>>.t_completeness_check_row;
$$ LANGUAGE SQL IMMUTABLE;

-----------------

CREATE OR REPLACE FUNCTION cc_null_check(par_cc_row t_completeness_check_row) RETURNS t_completeness_check_row AS $$
DECLARE
        r sch_<<$app_name$>>.t_completeness_check_row;
BEGIN
        r:= par_cc_row;
        r.cc_null_cnstr_passed_ok:= (r.param_value).final_value IS NOT NULL OR ((r.param_value).param_base).allow_null_final_value;
        RETURN r;
END;
$$ LANGUAGE plpgsql;

----------------------------

CREATE OR REPLACE FUNCTION cc_cnstr_arr_check(par_cc_row t_completeness_check_row) RETURNS t_completeness_check_row
LANGUAGE plpgsql
AS $$
DECLARE
        r sch_<<$app_name$>>.t_completeness_check_row;
        i integer;
        l integer;
        ok boolean;
        chk boolean;
        q varchar;
BEGIN
        r:= par_cc_row;
        i:= 0;
        l:= coalesce(array_length(((r.param_value).param_base).constraints_array, 1), 0);
        ok:= TRUE;
        IF r.cc_null_cnstr_passed_ok IS DISTINCT FROM FALSE THEN
                WHILE i < l AND ok LOOP
                        i:= i + 1;
                        q:= 'SELECT ' || ((((r.param_value).param_base).constraints_array)[i]).constraint_function;
                        EXECUTE q
                        INTO chk
                        USING (r.param_value).final_value
                            , r.config_id;
                        ok:= ok AND (chk IS NOT DISTINCT FROM TRUE);
                END LOOP;

                IF i = l AND ok THEN
                        r.cc_cnstr_array_failure_idx:= -1;
                ELSE
                        r.cc_cnstr_array_failure_idx:= i;
                END IF;
        ELSE
                r.cc_cnstr_array_failure_idx:= 0;
        END IF;

        RETURN r;
END;
$$;

COMMENT ON FUNCTION cc_cnstr_arr_check(par_cc_row t_completeness_check_row) IS
'This fuction checks if value+config respects constraints defined by user in the ".param_value.param_base.constraints_array".
The check of constraints will be skipped, if apriori value of "cc_null_cnstr_passed_ok" IS NOT DISTINCT FROM FALSE.
';
----------------------------

CREATE OR REPLACE FUNCTION cc_subcfg_compl_check(
                par_cc_row                  t_completeness_check_row
              , par_thorough_mode           integer
              , par_thorough_report_warning t_thorough_report_warning_mode
              ) RETURNS t_completeness_check_row
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        r              sch_<<$app_name$>>.t_completeness_check_row;
        ck             sch_<<$app_name$>>.t_config_key;
        chk            sch_<<$app_name$>>.t_config_completeness_check_result;
BEGIN
        r:= par_cc_row;

        IF ((par_cc_row.param_value).param_base).type = 'leaf' THEN
                r.cc_subconfig_is_complete:= 'le_V';
        ELSE
                ck:= make_configkey_bystr(r.confentity_code_id, r.config_id);
                r.cc_subconfig_is_complete:= config_is_complete(ck, par_thorough_mode, par_thorough_report_warning);
        END IF;

        RETURN r;
END;
$$;

COMMENT ON FUNCTION cc_subcfg_compl_check(
                par_cc_row                  t_completeness_check_row
              , par_thorough_mode           integer
              , par_thorough_report_warning t_thorough_report_warning_mode
              ) IS
'This function checks, if value is of type "subconfig", then if the subconfig is complete.
For value of type "leaf" check is always successful.
For more info about "par_thorough_mode" read comment to "config_completeness" function.
';

----------------------------

CREATE OR REPLACE FUNCTION get_paramvalues_cc(par_config_key t_config_key) RETURNS t_completeness_check_row[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE g  sch_<<$app_name$>>.t_config_key;
        r  sch_<<$app_name$>>.t_completeness_check_row[];
BEGIN
        g:= optimize_configkey(par_config_key, FALSE);

        r:= ARRAY(
                SELECT mk_completeness_precheck_row(
                                code_id_of_confentitykey(g.confentity_key)
                              , g.config_id
                              , ROW(cps.*) :: t_cparameter_value_uni
                              , NULL :: boolean
                              , NULL :: integer
                              , NULL :: t_config_completeness_check_result
                              )
                FROM unnest(get_paramvalues(TRUE, g)) AS cps -- t_cparameter_value_uni
                ORDER BY (cps.param_base).type, (cps.param_base).param_id
        );

        RETURN r;
END;
$$;

----------------------------

CREATE OR REPLACE FUNCTION seek_paramvalues_cc_by_subcfg_ctr(par_config_tree_row t_configs_tree_rel, par_pvcc_set t_completeness_check_row[]) RETURNS integer AS $$
DECLARE
        i integer;
        l integer;
BEGIN
        i:= 0;
        l:= coalesce(array_length(par_pvcc_set, 1), 0);
        WHILE l > i LOOP
                i:= i + 1;
                IF par_config_tree_row.super_param_id IS NOT DISTINCT FROM (((par_pvcc_set[i]).param_value).param_base).param_id THEN
                    RETURN i;
                END IF;
        END LOOP;

        RETURN -1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION seek_paramvalues_cc_by_subcfg_ctr(par_config_tree_row t_configs_tree_rel, par_pvcc_set t_completeness_check_row[]) IS '
Returns -1 if parameter not found.
The function is a result of bad style coding (but it does what it is required to).
';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_paramvalues_cc(
          par_cc_rows t_completeness_check_row[]
        , par_perform_cnstr_checks integer
        , par_thorough_report_warning t_thorough_report_warning_mode
        ) RETURNS t_completeness_check_row[]
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g  sch_<<$app_name$>>.t_config_key;
        r  sch_<<$app_name$>>.t_completeness_check_row;
        ar sch_<<$app_name$>>.t_completeness_check_row[];
        mode1 integer;
        mode2 integer;
        mode3 integer;
        i integer;
        l integer;
BEGIN
        mode1:=     par_perform_cnstr_checks / 100;
        mode2:= mod(par_perform_cnstr_checks , 100) / 10;
        mode3:= mod(par_perform_cnstr_checks ,        10);

        IF par_perform_cnstr_checks IS NULL OR (mode1 NOT IN (0,1)) OR (mode2 NOT IN (0,1)) OR (mode3 NOT IN (0,1,2,3,4)) THEN
                RAISE EXCEPTION 'An error occurred in function "check_paramvalues_cc"! Wrong mode specified in "par_perform_cnstr_checks" parameter: %. Read comments to the function for more info on supported modes.', par_perform_cnstr_checks;
        END IF;

        i:= 0;
        l:= array_length(par_cc_rows, 1);
        ar:= par_cc_rows;

        WHILE i < l LOOP
                i:= i + 1;

                r:= ar[i];
                IF mode1 > 0 THEN
                        r:= cc_null_check(r);
                END IF;

                IF mode2 > 0 THEN
                        r:= cc_cnstr_arr_check(r);
                END IF;

                IF mode3 > 0 THEN
                        r:= cc_subcfg_compl_check(r, mode3 - 1, par_thorough_report_warning);
                END IF;

                ar[i]:= r;
        END LOOP;

        RETURN ar;
END;
$$;

COMMENT ON FUNCTION check_paramvalues_cc(
                          par_cc_rows t_completeness_check_row[]
                        , par_perform_cnstr_checks integer
                        , par_thorough_report_warning t_thorough_report_warning_mode
                        ) IS
'Parameter "par_perform_cnstr_checks" may have values:
0xx - no check #1
1xx - perform only not null checks (for confparameters, that has "allow_null_final_value"=FALSE)
x0x - no check #2
x1x - perform user-defined constraints checks (configurations_parameters.constraints_array)
xx0 - no check #3
xx1 - for parameters of type "subconfig" perform completeness light check (read "configurations.complete_isit")
xx2 - for parameters of type "subconfig" perform completeness full  check of 1 level below, but deeper checks - using light check
xx3 - for parameters of type "subconfig" perform completeness full  check (recursively, terminating suconfigs tree processing by first incomplete suconfig occurence)
xx4 - for parameters of type "subconfig" perform completeness full  check (recursively, terminating suconfigs tree processing only when all tree elements are processed)
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cc_isit(par_cc_rows t_completeness_check_row[]) RETURNS boolean AS $$
DECLARE
        r boolean;
        i integer;
        l integer;
BEGIN
        r:= TRUE;
        i:= 0;
        l:= array_length(par_cc_rows, 1);

        WHILE r AND i < l LOOP
                i:= i + 1;

                r:= r AND ((par_cc_rows[i]).cc_null_cnstr_passed_ok     IS NOT DISTINCT FROM TRUE)
                      AND ((par_cc_rows[i]).cc_cnstr_array_failure_idx  IS NOT DISTINCT FROM -1)
                      AND ((((par_cc_rows[i]).param_value).param_base).type = 'leaf'
                          OR (completeness_interpretation((par_cc_rows[i]).cc_subconfig_is_complete)
                                                                        IS NOT DISTINCT FROM TRUE)
                          );
        END LOOP;
        r:= r AND i = l;
        RETURN r;
END;
$$ LANGUAGE plpgsql;

-------------------------

CREATE TYPE t_completeness_check_file AS (
        cc_rows_set          t_completeness_check_row[]
      , nn_cnstr_viol_count  integer
      , cc_cnstr_viol_count  integer
      , subcfg_incompl_count integer
      , errors_report        varchar
      , fully_checked_isit   boolean
      , is_complete          boolean
      );

-------------------------

CREATE OR REPLACE FUNCTION form_cc_report(par_cfgkey t_config_key, par_cc_rows t_completeness_check_row[]) RETURNS t_completeness_check_file
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        g  sch_<<$app_name$>>.t_config_key;
        r  sch_<<$app_name$>>.t_completeness_check_row[];
        mode1 integer;
        mode2 integer;
        v varchar;
        p_id varchar;
        cnstr_idx varchar;
        i integer;
        l integer;
        leafs_cnt   integer:= 0;
        subcfgs_cnt integer:= 0;
        this_complete boolean;
        f sch_<<$app_name$>>.t_completeness_check_file;
BEGIN
        g:= optimize_configkey(par_cfgkey, FALSE);

        f.cc_rows_set := par_cc_rows;
        f.nn_cnstr_viol_count  := 0;
        f.cc_cnstr_viol_count  := 0;
        f.subcfg_incompl_count := 0;
        f.fully_checked_isit := TRUE;
        f.is_complete := TRUE;
        l:= COALESCE(array_length(par_cc_rows, 1), 0);
        f.errors_report := E'\n------------------------<---';
        f.errors_report := f.errors_report || E'\nREPORT START';
        f.errors_report := f.errors_report || E'\nCompleteness report for config ' || show_configkey(g) || ':';

        i:= 0;
        WHILE i < l LOOP
                i:= i + 1;

                IF (par_cc_rows[i]).cc_null_cnstr_passed_ok IS NULL THEN
                        f.fully_checked_isit := FALSE;
                        p_id:= COALESCE('"' || (((par_cc_rows[i]).param_value).param_base).param_id || '"', '<NULL>');
                        f.errors_report := f.errors_report || E'\n** NOT NULL constraint not checked for parameter: ' || p_id || '.';
                ELSIF NOT (par_cc_rows[i]).cc_null_cnstr_passed_ok THEN
                        f.is_complete := FALSE;
                        f.nn_cnstr_viol_count:= f.nn_cnstr_viol_count + 1;
                        p_id:= COALESCE('"' || (((par_cc_rows[i]).param_value).param_base).param_id || '"', '<NULL>');
                        f.errors_report := f.errors_report || E'\n** NOT NULL constraint violation for parameter: ' || p_id || '.';
                END IF;

                IF (par_cc_rows[i]).cc_cnstr_array_failure_idx IS NULL THEN
                        f.fully_checked_isit := FALSE;
                        p_id:= COALESCE('"' || (((par_cc_rows[i]).param_value).param_base).param_id || '"', '<NULL>');
                        f.errors_report := f.errors_report || E'\n** user-defined constraint not checked for parameter: ' || p_id || '.';
                ELSIF (par_cc_rows[i]).cc_cnstr_array_failure_idx > 0 THEN
                        f.is_complete := FALSE;
                        f.cc_cnstr_viol_count:= f.cc_cnstr_viol_count + 1;
                        p_id:= COALESCE('"' || (((par_cc_rows[i]).param_value).param_base).param_id || '"', '<NULL>');
                        cnstr_idx:= COALESCE((par_cc_rows[i]).cc_cnstr_array_failure_idx :: varchar, '<NULL>');
                        f.errors_report := f.errors_report || E'\n** user-defined constraint #' || cnstr_idx || ' violation for parameter: ' || p_id || '.';
                END IF;

                IF (par_cc_rows[i]).cc_subconfig_is_complete IS NULL THEN
                    IF (((par_cc_rows[i]).param_value).param_base).type = 'subconfig' THEN
                        f.fully_checked_isit := FALSE;
                        p_id:= COALESCE('"' || (((par_cc_rows[i]).param_value).param_base).param_id || '"', '<NULL>');
                        f.errors_report := f.errors_report || E'\n** subconfig completeness not checked in parameter: ' || p_id || '.';
                    END IF;
                ELSE
                        this_complete:= completeness_interpretation((par_cc_rows[i]).cc_subconfig_is_complete);
                        f.is_complete:= f.is_complete AND this_complete;
                        IF NOT this_complete THEN
                                f.subcfg_incompl_count:= f.subcfg_incompl_count + 1;
                        END IF;
                        p_id:= COALESCE('"' || (((par_cc_rows[i]).param_value).param_base).param_id || '"', '<NULL>');

                        f.errors_report := f.errors_report || E'\n** subconfig completeness: ' || COALESCE(this_complete :: varchar, '<NULL>') || ' ' || COALESCE('(' || show_completeness_check_result((par_cc_rows[i]).cc_subconfig_is_complete) || ')', '') || ' in parameter: ' || p_id || '.';
                END IF;

                IF    (((par_cc_rows[i]).param_value).param_base).type = 'leaf' THEN
                        leafs_cnt  := leafs_cnt   + 1;
                ELSIF (((par_cc_rows[i]).param_value).param_base).type = 'subconfig' THEN
                        subcfgs_cnt:= subcfgs_cnt + 1;
                END IF;
        END LOOP;

        f.is_complete := f.is_complete AND f.fully_checked_isit;
        IF l > 0 THEN
                f.errors_report := f.errors_report || E'\n\n';
                f.errors_report := f.errors_report || E'Total errors counts:';
                f.errors_report := f.errors_report || E'\n ** NOT NULL violations: ' || COALESCE(f.nn_cnstr_viol_count :: varchar, '<NULL>');
                f.errors_report := f.errors_report || E'\n ** user-defined constraints violations: ' || COALESCE(f.cc_cnstr_viol_count :: varchar, '<NULL>');
                f.errors_report := f.errors_report || E'\n ** subconfigs incompletions: ' || COALESCE(f.subcfg_incompl_count :: varchar, '<NULL>');
                f.errors_report := f.errors_report || E'\nAll parameters (' || leafs_cnt || ' leafs, ' || subcfgs_cnt || ' subconfigs, ' || l || ' total) fully checked: ' || COALESCE(f.fully_checked_isit :: varchar, '<NULL>');
        ELSE
                f.errors_report := f.errors_report || E'\nCompleteness check omitted: configurable entity has no parameters.';
        END IF;
        f.errors_report := f.errors_report || E'\nConfig complete: ' || COALESCE(f.is_complete :: varchar, '<NULL>');
        f.errors_report := f.errors_report || E'\nREPORT END';
        f.errors_report := f.errors_report || E'\n------------------------>---';

        RETURN f;
END;
$$;

COMMENT ON FUNCTION form_cc_report(par_cfgkey t_config_key, par_cc_rows t_completeness_check_row[]) IS
'It is assumed, that given in "par_cc_rows" array contains all rows belonging to one same config.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION config_completeness(
                  par_config_tree_row         t_configs_tree_rel
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                ) RETURNS t_config_completeness_check_result
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE
        cur_ck     sch_<<$app_name$>>.t_config_key;
        sub_ck     sch_<<$app_name$>>.t_config_key;
        cur_ct_row sch_<<$app_name$>>.t_configs_tree_rel;
        p          sch_<<$app_name$>>.t_completeness_check_row;
        ps         sch_<<$app_name$>>.t_completeness_check_row[];
        f          sch_<<$app_name$>>.t_completeness_check_file;
        sub_cfgs   sch_<<$app_name$>>.t_configs_tree_rel[];
        super_cfgs sch_<<$app_name$>>.t_configs_tree_rel[];
        g          sch_<<$app_name$>>.t_configs_tree_rel;
        old_cpl    sch_<<$app_name$>>.t_config_completeness_check_result;
        r          sch_<<$app_name$>>.t_config_completeness_check_result;
        sub_r      sch_<<$app_name$>>.t_config_completeness_check_result;
        sub_th_chk_mode integer;
        rows_cnt integer;
        complete boolean;
        cpl_li_x_isit boolean;
        cpl_li_v_isit boolean;
        umode1 integer;
        umode2 integer;
        umode3 integer;
        i integer;
        j integer;
        l integer;
BEGIN
        umode1:=     par_update_mode / 100;
        umode2:= mod(par_update_mode , 100) / 10;
        umode3:= mod(par_update_mode ,        10);

        IF (par_thorough_check IS NULL) OR (par_thorough_check NOT IN (0,1,2,3)) THEN
                RAISE EXCEPTION 'An error occurred in function "config_completeness"! Wrong mode specified in "par_thorough_check" parameter: %.', par_thorough_check;
        END IF;

        IF (par_update_mode IS NULL) OR (umode1 NOT IN (0,1)) OR (umode2 NOT IN (0,1)) OR (umode3 NOT IN (0,1)) THEN
                RAISE EXCEPTION 'An error occurred in function "config_completeness"! Wrong mode specified in "par_thorough_check" parameter: %.', par_thorough_check;
        END IF;

        IF par_thorough_report_warning IS NULL THEN
                RAISE EXCEPTION 'An error occurred in function "config_completeness"! Parameter "par_thorough_report_warning" is not allowed to be NULL.';
        END IF;

        IF par_config_tree_row.sub_ce_id IS NULL OR par_config_tree_row.sub_cfg_id IS NULL THEN
                RAISE EXCEPTION 'An error occurred in function "config_completeness"! Parameter "par_config_tree_row" sub- part is not allowed to be NULL!';
        END IF;

        ------------------
        r:= NULL :: t_config_completeness_check_result;

        IF par_config_tree_row.cycle_detected AND par_thorough_check > 1 THEN
                RAISE WARNING 'Cycle is detected in subconfigs (path: %). Completeness check for configuration referential cycles are not supported in this version - it is assumed to be INCOMPLETE. In order to use this version of configuration control system properly, please, get rid of referential cycles in your configs graph.', show_cfgtreerow_path(par_config_tree_row);
                r:= 'cy_X';
                -- bad style
                IF umode2 = 1 THEN
                        UPDATE configurations
                        SET complete_isit = r
                        WHERE complete_isit <> r
                          AND configuration_id   = par_config_tree_row.sub_cfg_id
                          AND confentity_code_id = par_config_tree_row.sub_ce_id;
                END IF;

                RETURN r;
        END IF;

        cur_ck:= make_configkey_bystr(
                          par_config_tree_row.sub_ce_id
                        , par_config_tree_row.sub_cfg_id
        );
        cur_ct_row:= par_config_tree_row;
        cur_ct_row.super_ce_id := NULL :: integer;
        cur_ct_row.super_cfg_id:= NULL :: varchar;
        SELECT c.complete_isit
        INTO old_cpl
        FROM configurations AS c
        WHERE c.configuration_id   = cur_ct_row.sub_cfg_id
          AND c.confentity_code_id = cur_ct_row.sub_ce_id;

        GET DIAGNOSTICS rows_cnt = ROW_COUNT;

        IF (rows_cnt != 1) THEN
                r:= 'nf_X';
                complete:= FALSE;
                IF (   par_thorough_report_warning = 'ALWAYS'
                   OR (par_thorough_report_warning = 'WHEN LOSING COMPLETENESS' AND completeness_interpretation(old_cpl))
                   )
                THEN
                        f.errors_report := E'\n------------------------<---';
                        f.errors_report := f.errors_report || E'\nREPORT START';
                        f.errors_report := f.errors_report || E'\nCompleteness report for config ' || show_configkey(cur_ck) || ': ';
                        f.errors_report := f.errors_report || E'\nConfig not found.';
                        f.errors_report := f.errors_report || E'\nREPORT END.';
                        f.errors_report := f.errors_report || E'\n------------------------>---';
                        RAISE WARNING '%', f.errors_report;

                        RETURN r;
                END IF;
        END IF;

        IF r IS NULL THEN
            IF    par_thorough_check = 0 THEN
                r:= old_cpl;
                complete:= completeness_interpretation(r);
            ELSIF par_thorough_check > 0 THEN
                ps:= get_paramvalues_cc(cur_ck);

                IF par_thorough_check = 1 THEN
                        sub_th_chk_mode:= 0;
                ELSE    sub_th_chk_mode:= par_thorough_check; -- 2, 3
                END IF;
                sub_cfgs:= sub_cfgs_of(cur_ct_row, cfg_tree_rel_main_types_set(FALSE));
                l:= array_length(sub_cfgs, 1);
                i:= 0;
                sub_r:= NULL :: t_config_completeness_check_result;
                WHILE (i < l) LOOP
                        i:= i + 1;
                        sub_r:= config_completeness(sub_cfgs[i], sub_th_chk_mode, par_thorough_report_warning, umode3 * 11); -- if umode3 = 1, then update current subconfig and all it's subs, else if umode3 = 0, update nothing

                        sub_ck:= make_configkey_bystr(
                                          (sub_cfgs[i]).sub_ce_id
                                        , (sub_cfgs[i]).sub_cfg_id
                        );
                        j:= seek_paramvalues_cc_by_subcfg_ctr(sub_cfgs[i], ps);
                        p:= ps[j];
                        p.cc_subconfig_is_complete:= sub_r;
                        ps[j]:= p;

                        IF (completeness_interpretation(sub_r) IS DISTINCT FROM TRUE) THEN
                            -- IF r IS NULL OR sub_r = 'cy_X' THEN
                            --     IF sub_r = 'cy_X' THEN
                            --             r:= 'cy_X';
                            --     ELSE    r:= 'th_chk_X';
                            --     END IF;
                            -- END IF;
                            r:= 'th_chk_X';

                            IF par_thorough_check < 3 THEN
                                IF (  (par_thorough_report_warning = 'ALWAYS')
                                   OR (par_thorough_report_warning = 'WHEN LOSING COMPLETENESS' AND completeness_interpretation(old_cpl))
                                   )
                                THEN
                                        f.errors_report := E'\n------------------------<---';
                                        f.errors_report := f.errors_report || E'\nREPORT START';
                                        f.errors_report := f.errors_report || E'\nCompleteness report for config ' || show_configkey(cur_ck) || ': ';
                                        f.errors_report := f.errors_report || E'\nConfig incomplete, due to subconfig incompleteness (' || COALESCE('"' || sub_r || '"', '<NULL>') || ') in parameter ' || COALESCE('"' || (((ps[j]).param_value).param_base).param_id || '"', '<NULL>') || ' (subconfig: ' || show_configkey(sub_ck) || ').';
                                        f.errors_report := f.errors_report || E'\nREPORT END.';
                                        f.errors_report := f.errors_report || E'\n------------------------>---';
                                        RAISE WARNING '%', f.errors_report;
                                END IF;

                                -- bad style
                                IF umode2 = 1 THEN
                                        UPDATE configurations
                                        SET complete_isit = r
                                        WHERE complete_isit <> r
                                          AND configuration_id   = cur_ct_row.sub_cfg_id
                                          AND confentity_code_id = cur_ct_row.sub_ce_id;
                                END IF;

                                RETURN r;
                            END IF;
                        END IF;
                END LOOP;

                IF r IS NULL THEN
                        ps:= check_paramvalues_cc( -- subconfigs needs not to be checked
                                ps
                              , 110   -- not null and user-defined constraints checks; don't check subconfigs
                              , par_thorough_report_warning
                        );

                        complete:= cc_isit(ps);

                        IF (  (par_thorough_report_warning = 'ALWAYS')
                           OR (par_thorough_report_warning = 'WHEN LOSING COMPLETENESS' AND completeness_interpretation(old_cpl) AND NOT complete)
                           )
                        THEN
                                f:= form_cc_report(cur_ck, ps);
                                RAISE WARNING '%', f.errors_report;
                                complete:= f.is_complete;
                        END IF;
                ELSE
                        complete:= completeness_interpretation(r);
                END IF;
            END IF;
        END IF;

        IF r IS NULL THEN
                IF complete IS NULL THEN
                        r:= 'nf_X';
                        complete:= FALSE;
                ELSIF complete THEN
                        IF par_thorough_check = 0 THEN
                                r:= 'li_chk_V';
                        ELSE    r:= 'th_chk_V';
                        END IF;
                ELSE
                        IF par_thorough_check = 0 THEN
                                r:= 'li_chk_X';
                        ELSE    r:= 'th_chk_X';
                        END IF;
                END IF;
        END IF;

        IF umode2 = 1 THEN
                cpl_li_x_isit:= r = 'li_chk_X';
                cpl_li_v_isit:= r = 'li_chk_V';

                UPDATE configurations
                SET complete_isit = r
                WHERE complete_isit <> r
                  AND CASE cpl_li_x_isit
                          WHEN TRUE THEN complete_isit <> 'th_chk_X'
                          ELSE CASE cpl_li_v_isit
                                   WHEN TRUE THEN complete_isit <> 'th_chk_V'
                                   ELSE TRUE
                               END
                      END
                  AND configuration_id   = cur_ct_row.sub_cfg_id
                  AND confentity_code_id = cur_ct_row.sub_ce_id;
        END IF;

        IF umode1 = 1 AND complete THEN
                super_cfgs:= super_cfgs_of(cur_ct_row, cfg_tree_rel_main_types_set(FALSE));

                l:= array_length(super_cfgs, 1);
                i:= 0;
                WHILE (i < l) LOOP
                        i:= i + 1;
                        g:= super_cfgs[i];
                        g.sub_cfg_id:= g.super_cfg_id;
                        g.sub_ce_id := g.super_ce_id;
                        g.super_cfg_id:= NULL :: varchar;
                        g.super_ce_id := NULL :: integer;
                        PERFORM config_completeness(
                                  g
                                , 1
                                , par_thorough_report_warning
                                , 110
                                );
                END LOOP;
        END IF;

        RETURN r;
END;
$$;

COMMENT ON FUNCTION config_completeness(
                  par_config_tree_row         t_configs_tree_rel
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                ) IS
'It''s recommended to use the function version without last ("par_update_buffer") parameter, since it (the parameter) is for internal use.

Parameter "par_config_tree_row": the sub- part of it is assumed to be identifying targrt (current) configuration, while super- part will be totally ignored.

Parameter "par_thorough_check" is allowed to have 3 values:
0 - perform light completeness check (use function "read_completeness(par_config_key)")
1 - thorough check current config, but light check any subconfig
2 - thorough check current config and all subconfigs, terminating *suconfigs* tree processing by first incomplete suconfig occurence
3 - thorough check current config and all subconfigs, terminating *suconfigs* tree processing only when all tree elements are processed
Parameter "par_thorough_report_warning" is relevant only when "par_thorough_check" is > 0

Parameter "par_update_mode" values
0xx - do not update superconfigs
1xx -        update superconfigs (recursively)
x0x - do not update current config
x1x -        update current config
xx0 - do not update subconfigs
xx1 -        update subconfigs (recursively, for every superbranch: while recursive current config is complete)

Notice: in further version it would be wise to make this recursive procedure monadic, so that it won''t recalculate many times same subconfig, when it''s reachable by many different paths.
Currently, due to this problem, a lot of functional potential of this procedure isn''t used by package itself. Function "analyze_cfgs_tree" is used instead.
';

-------------

CREATE OR REPLACE FUNCTION config_completeness(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                ) RETURNS t_config_completeness_check_result
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE SQL
AS $$
        SELECT config_completeness(
                mk_configs_tree_rel(
                        NULL :: integer
                      , NULL :: varchar
                      , NULL :: varchar
                      , code_id_of_confentitykey(x.confentity_key)
                      , x.config_id
                      , 'init' :: t_cfg_tree_rel_type
                      , ARRAY[] :: t_config_key[]
                      , 0
                      , FALSE
                      , NULL :: t_config_completeness_check_result
                      , NULL :: t_config_completeness_check_result
                      )
                , $2
                , $3
                , $4
                )
        FROM unnest(ARRAY(SELECT optimize_configkey($1, FALSE) AS a)) AS x;
$$;

COMMENT ON FUNCTION config_completeness(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                ) IS
'
Simplifying wrapper around "config_completeness" function. Simplification concerns 1st parameter.
But for more info about parameters see commnts on on the wrapped function.
';

--------------------------------------------------------

CREATE OR REPLACE FUNCTION config_is_complete(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                ) RETURNS t_config_completeness_check_result
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE SQL
AS $$
        SELECT config_completeness(
                mk_configs_tree_rel(
                        NULL :: integer
                      , NULL :: varchar
                      , NULL :: varchar
                      , code_id_of_confentitykey(x.confentity_key)
                      , x.config_id
                      , 'init' :: t_cfg_tree_rel_type

                      , ARRAY[] :: t_config_key[]
                      , 0
                      , FALSE
                      , NULL :: t_config_completeness_check_result
                      , NULL :: t_config_completeness_check_result
                      )
                , $2
                , $3
                , 0
                )
        FROM unnest(ARRAY(SELECT optimize_configkey($1, FALSE) AS a)) AS x
$$;

COMMENT ON FUNCTION config_is_complete(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                ) IS
'
Simplifying wrapper around "config_completeness" function. Update functionality disabled.
But for more info about parameters see commnts on on the wrapped function.
';

-----------------------------

CREATE OR REPLACE FUNCTION try_to_complete_config(par_config_key t_config_key) RETURNS t_config_completeness_check_result
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE SQL
AS $$
        SELECT config_completeness(optimize_configkey($1, FALSE), 2, 'ALWAYS', 10)
$$;

COMMENT ON FUNCTION try_to_complete_config(par_config_key t_config_key) IS
'Simplifying wrapper:
        SELECT config_completeness(optimize_configkey($1, FALSE), 2, ''ALWAYS'', 10)
** 2 - thorough check current config and all subconfigs, terminating suconfigs tree processing by first incomplete suconfig occurence
** ''ALWAYS'' - whether to output completeness check report as a WARNING or not
** 10 - update current config
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION uncomplete_cfg(par_config_key t_config_key) RETURNS integer
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $$
DECLARE g sch_<<$app_name$>>.t_config_key;
        cnt integer;
BEGIN
        g:= optimize_configkey($1, FALSE);

        UPDATE configurations AS c
        SET complete_isit = 'li_chk_X'
        WHERE complete_isit <> 'li_chk_X'
          AND c.confentity_code_id = code_id_of_confentitykey(g.confentity_key)
          AND c.configuration_id = g.config_id;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- GRANTS

-- Reference functions:
GRANT EXECUTE ON FUNCTION completeness_interpretation(par_completeness t_config_completeness_check_result)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_completeness_check_result(par_completeness t_config_completeness_check_result)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION mk_completeness_precheck_row(
        par_confentity_code_id integer
      , par_config_id          varchar
      , par_param_value        t_cparameter_value_uni
      , par_cc_null_cnstr_passed_ok    boolean
      , par_cc_cnstr_array_failure_idx integer
      , par_cc_subconfig_is_complete   t_config_completeness_check_result
      )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION form_cc_report(par_cfgkey t_config_key, par_cc_rows t_completeness_check_row[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


-- Analytic functions:
GRANT EXECUTE ON FUNCTION cc_null_check(par_cc_row t_completeness_check_row)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION cc_cnstr_arr_check(par_cc_row t_completeness_check_row)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION seek_paramvalues_cc_by_subcfg_ctr(par_config_tree_row t_configs_tree_rel, par_pvcc_set t_completeness_check_row[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION cc_isit(par_cc_rows t_completeness_check_row[])TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION check_paramvalues_cc(
          par_cc_rows t_completeness_check_row[]
        , par_perform_cnstr_checks integer
        , par_thorough_report_warning t_thorough_report_warning_mode
        )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


-- Lookup functions:
GRANT EXECUTE ON FUNCTION cc_subcfg_compl_check(
                par_cc_row                  t_completeness_check_row
              , par_thorough_mode           integer
              , par_thorough_report_warning t_thorough_report_warning_mode
              )TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_paramvalues_cc(par_config_key t_config_key)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


-- Administration functions:
GRANT EXECUTE ON FUNCTION config_completeness(
                  par_config_tree_row         t_configs_tree_rel
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION config_completeness(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                , par_update_mode             integer
                ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION config_is_complete(
                  par_config_key              t_config_key
                , par_thorough_check          integer
                , par_thorough_report_warning t_thorough_report_warning_mode
                ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION try_to_complete_config(par_config_key t_config_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION uncomplete_cfg(par_config_key t_config_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> completeness.init.sql [END]