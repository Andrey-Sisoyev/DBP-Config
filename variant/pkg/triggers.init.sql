-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- now selfreferring configs will be deletable
CREATE OR REPLACE FUNCTION confentity_ondelete() RETURNS trigger
LANGUAGE plpgsql
AS $confentity_ondelete$ -- before delete
BEGIN
        DELETE FROM sch_<<$app_name$>>.configurations_parameters WHERE confentity_code_id = OLD.confentity_code_id;
        RETURN OLD;
END;
$confentity_ondelete$;

CREATE TRIGGER tri_a_confentity_ondelete BEFORE DELETE ON sch_<<$app_name$>>.configurable_entities
    FOR EACH ROW EXECUTE PROCEDURE confentity_ondelete();

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION configsbylngs_autocreate() RETURNS trigger
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $configsbylngs_autocreate$ -- before delete
DECLARE t boolean;
BEGIN
        t:= FALSE;
        CASE TG_OP
            WHEN 'INSERT' THEN t:= TRUE;
            WHEN 'UPDATE' THEN
                t:= (NEW.values_lng_code_id IS DISTINCT FROM OLD.values_lng_code_id)
                 OR (NEW.confentity_code_id IS DISTINCT FROM OLD.confentity_code_id) ;
        END CASE;

        IF t THEN
                IF NOT sch_<<$app_name$>>.read_cfgmngsys_setup__autoadd_lnged_cfgs() THEN RETURN NEW; END IF;

                INSERT INTO configurations_bylngs (
                                confentity_code_id
                              , configuration_id
                              , values_lng_code_id
                              , complete_isit
                              , completeness_as_regulator
                              )
                (SELECT c.confentity_code_id
                      , c.configuration_id
                      , NEW.values_lng_code_id
                      , 'li_chk_X' :: t_config_completeness_check_result
                      , c.completeness_as_regulator
                 FROM configurations AS c
                    , unnest( related_cfgs_ofcfg(
                                 make_configkey_bystr(
                                         NEW.confentity_code_id
                                       , NEW.configuration_id
                                       )
                               , 20 -- supers
                               , FALSE
                            )  ) AS rct
                 WHERE rct.super_ce_id  = c.confentity_code_id
                   AND rct.super_cfg_id = c.configuration_id
                   AND ROW(c.confentity_code_id, c.configuration_id, NEW.values_lng_code_id)
                                 NOT IN (SELECT cr.confentity_code_id, cr.configuration_id, cr.values_lng_code_id
                                         FROM configurations_bylngs AS cr
                                         WHERE c.confentity_code_id  = cr.confentity_code_id
                                           AND c.configuration_id    = cr.configuration_id
                                           AND cr.values_lng_code_id = NEW.values_lng_code_id
                                        )
                UNION
                 SELECT c.confentity_code_id
                      , c.configuration_id
                      , NEW.values_lng_code_id
                      , 'li_chk_X' :: t_config_completeness_check_result
                      , c.completeness_as_regulator
                 FROM configurations AS c
                    , unnest( related_cfgs_ofcfg(
                                 make_configkey_bystr(
                                         NEW.confentity_code_id
                                       , NEW.configuration_id
                                       )
                               , 2 -- subs
                               , FALSE
                            )  ) AS rct
                 WHERE rct.sub_ce_id  = c.confentity_code_id
                   AND rct.sub_cfg_id = c.configuration_id
                   AND ROW(c.confentity_code_id, c.configuration_id, NEW.values_lng_code_id)
                                 NOT IN (SELECT cr.confentity_code_id, cr.configuration_id, cr.values_lng_code_id
                                         FROM configurations_bylngs AS cr
                                         WHERE c.confentity_code_id  = cr.confentity_code_id
                                           AND c.configuration_id    = cr.configuration_id
                                           AND cr.values_lng_code_id = NEW.values_lng_code_id
                                        )
                );
        END IF;

        RETURN NEW;
END;
$configsbylngs_autocreate$;

CREATE TRIGGER tri_configsbylngs_autocreate BEFORE DELETE ON configurations_bylngs
    FOR EACH ROW EXECUTE PROCEDURE configsbylngs_autocreate();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cfgunit_oncredel() RETURNS trigger
LANGUAGE plpgsql
AS $cfgunit_oncredel$ -- ins, del
DECLARE
        entity_name    varchar;
        instance_id    varchar;
        operation_verb varchar;
        the_row RECORD;
BEGIN
           IF TG_OP = 'INSERT' THEN the_row:= NEW; operation_verb:= 'CREATED';
        ELSIF TG_OP = 'DELETE' THEN the_row:= OLD; operation_verb:= 'DELETED';
        ELSE RAISE EXCEPTION 'Error in the "cfgunit_oncredel" TRIGGER function! Unsupported triggerring operation: "%".', TG_OP;
        END IF;

        IF NOT sch_<<$app_name$>>.read_cfgmngsys_setup__output_credel_notices() THEN RETURN the_row; END IF;

        CASE TG_TABLE_NAME
            WHEN 'configurable_entities' THEN
                entity_name:= 'Configurable entity';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || ')';
            WHEN 'configurations' THEN
                entity_name:= 'Configuration';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; cfg_id: "' || the_row.configuration_id || '")';
            WHEN 'configurations_bylngs' THEN
                entity_name:= 'Configuration in language';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; cfg_id: "' || the_row.configuration_id || '"; val_lng_id: ' || the_row.values_lng_code_id || ')';
            WHEN 'configurations_parameters__leafs' THEN
                entity_name:= 'Configuration leaf-parameter';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; param_id: "' || the_row.parameter_id || '")';
            WHEN 'configurations_parameters' THEN
                entity_name:= 'Configuration parameter (abstract)';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; param_id: "' || the_row.parameter_id || '")';
            WHEN 'configurations_parameters_values__leafs' THEN
                entity_name:= 'Configuration leaf-parameter value';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; cfg_id: "' || the_row.configuration_id || '"; param_id: "' || the_row.parameter_id || '")';
            WHEN 'configurations_parameters_lngvalues__leafs' THEN
                entity_name:= 'Configuration leaf-parameter value in language';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; cfg_id: "' || the_row.configuration_id || '"; param_id: "' || the_row.parameter_id || '"; val_lng_id: ' || the_row.value_lng_code_id || ')';
            WHEN 'configurations_parameters__subconfigs' THEN
                entity_name:= 'Configuration subconfig-parameter';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; param_id: "' || the_row.parameter_id || '")';
            WHEN 'configurations_parameters_values__subconfigs' THEN
                entity_name:= 'Configuration subconfig-parameter value';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; cfg_id: "' || the_row.configuration_id || '"; param_id: "' || the_row.parameter_id || '")';
            ELSE RAISE EXCEPTION 'Error in the "cfgunit_oncredel" TRIGGER function! Unsupported table: "%".', TG_TABLE_NAME;
        END CASE;

        RAISE NOTICE '**> % %: %.', operation_verb, entity_name, instance_id;

        RETURN the_row;
END;
$cfgunit_oncredel$;

CREATE TRIGGER tri_z_confentity_oncredel       AFTER INSERT OR DELETE ON configurable_entities
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_config_oncredel           AFTER INSERT OR DELETE ON configurations
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_lngconfig_oncredel        AFTER INSERT OR DELETE ON configurations_bylngs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparam_oncredel        AFTER INSERT OR DELETE ON configurations_parameters
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparam_l_oncredel      AFTER INSERT OR DELETE ON configurations_parameters__leafs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparamvalue_l_oncredel AFTER INSERT OR DELETE ON configurations_parameters_values__leafs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparamlngvalue_l_oncredel AFTER INSERT OR DELETE ON configurations_parameters_lngvalues__leafs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparam_s_oncredel      AFTER INSERT OR DELETE ON configurations_parameters__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparamvalue_s_oncredel AFTER INSERT OR DELETE ON configurations_parameters_values__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION confentity_domain_onmonify() RETURNS trigger
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $confentity_domain_onmonify$ -- upd
DECLARE
        o_ce_id integer;
        n_ce_id integer;
        recheck_completeness boolean := FALSE;
        new_completeness sch_<<$app_name$>>.t_config_completeness_check_result;
        dep_cts          sch_<<$app_name$>>.t_configs_tree_rel[];
        exclud_cfg       sch_<<$app_name$>>.t_config_key;
        val_lng_id integer;
BEGIN
        IF TG_OP NOT IN ('INSERT', 'DELETE', 'UPDATE') THEN
                RAISE EXCEPTION 'Error in the "confentity_domain_onmonify" TRIGGER function! Unsupported triggerring operation: "%".', TG_OP;
        END IF;

        CASE read_cfgmngsys_setup__perform_completness_routines()
            WHEN TRUE  THEN -- ok
            WHEN FALSE THEN
                CASE TG_OP
                    WHEN 'INSERT' THEN
                        RETURN NEW;
                    WHEN 'UPDATE' THEN
                        RETURN NEW;
                    WHEN 'DELETE' THEN
                        RETURN OLD;
                END CASE;
        END CASE;

        exclud_cfg:= make_configkey_null();
        val_lng_id:= NULL :: integer;
        dep_cts:= ARRAY[] :: t_configs_tree_rel[];

        CASE TG_TABLE_NAME
            WHEN 'configurable_entities' THEN
                CASE TG_OP
                    WHEN 'INSERT' THEN
                        -- nothing to be done
                    WHEN 'UPDATE' THEN
                        IF (NEW.default_configuration_id IS DISTINCT FROM OLD.default_configuration_id) THEN
                                dep_cts:= configs_that_rely_on_confentity_default(NEW.confentity_code_id, TRUE, FALSE)
                                       || configs_that_rely_on_confentity_default(OLD.confentity_code_id, TRUE, FALSE);
                        END IF;
                    WHEN 'DELETE' THEN
                        -- nothing to be done
                END CASE;
            WHEN 'configurations', 'configurations_bylngs' THEN
                IF TG_TABLE_NAME = 'configurations_bylngs' THEN
                    val_lng_id:= the_row.values_lng_code_id;
                END IF;
                CASE TG_OP
                    WHEN 'INSERT' THEN
                        recheck_completeness:= TRUE;
                        dep_cts:= configs_that_use_subconfig(make_configkey(make_confentitykey_byid(NEW.confentity_code_id), NEW.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE);
                    WHEN 'UPDATE' THEN
                        recheck_completeness:= TRUE;
                        IF    (NEW.configuration_id   IS DISTINCT FROM OLD.configuration_id)
                           OR (NEW.confentity_code_id IS DISTINCT FROM OLD.confentity_code_id)
                           OR (completeness_interpretation(NEW.complete_isit) IS DISTINCT FROM completeness_interpretation(OLD.complete_isit))
                        THEN
                                dep_cts:= configs_that_use_subconfig(make_configkey(make_confentitykey_byid(NEW.confentity_code_id), NEW.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE)
                                       || configs_that_use_subconfig(make_configkey(make_confentitykey_byid(OLD.confentity_code_id), OLD.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE);
                                IF completeness_interpretation(OLD.complete_isit) IS DISTINCT FROM TRUE THEN
                                        exclud_cfg:= make_configkey(make_confentitykey_byid(NEW.confentity_code_id), NEW.configuration_id, FALSE, make_codekeyl_byid(val_lng_id));
                                END IF;
                        END IF;
                    WHEN 'DELETE' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey(make_confentitykey_byid(OLD.confentity_code_id), OLD.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE);
                END CASE;
            WHEN 'configurations_parameters', 'configurations_parameters__subconfigs', 'configurations_parameters__leafs' THEN
                CASE TG_OP
                    WHEN 'INSERT' THEN
                        dep_cts:= configs_related_with_confentity(NEW.confentity_code_id, TRUE, FALSE);
                    WHEN 'UPDATE' THEN
                        dep_cts:= configs_related_with_confentity(NEW.confentity_code_id, TRUE, FALSE)
                               || configs_related_with_confentity(OLD.confentity_code_id, TRUE, FALSE);
                    WHEN 'DELETE' THEN
                        dep_cts:= configs_related_with_confentity(OLD.confentity_code_id, TRUE, FALSE);
                END CASE;
            WHEN 'configurations_parameters_values__subconfigs', 'configurations_parameters_values__leafs', 'configurations_parameters_lngvalues__leafs' THEN
                IF TG_TABLE_NAME = 'configurations_parameters_lngvalues__leafs' THEN
                    val_lng_id:= the_row.value_lng_code_id;
                END IF;
                CASE TG_OP
                    WHEN 'INSERT' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey(make_confentitykey_byid(NEW.confentity_code_id), NEW.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE);
                    WHEN 'UPDATE' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey(make_confentitykey_byid(OLD.confentity_code_id), OLD.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE);
                        IF    (NEW.configuration_id   IS DISTINCT FROM OLD.configuration_id)
                           OR (NEW.confentity_code_id IS DISTINCT FROM OLD.confentity_code_id)
                        THEN
                                dep_cts:= dep_cts || configs_that_use_subconfig(make_configkey(make_confentitykey_byid(NEW.confentity_code_id), NEW.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE);
                        END IF;
                    WHEN 'DELETE' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey(make_confentitykey_byid(OLD.confentity_code_id), OLD.configuration_id, FALSE, make_codekeyl_byid(val_lng_id)), TRUE, FALSE);
                END CASE;
            ELSE RAISE EXCEPTION 'Error in the "confentity_domain_onmonify" TRIGGER function! Unsupported table: "%".', TG_TABLE_NAME;
        END CASE;

        PERFORM update_cfgs_ondepmodify(dep_cts, exclud_cfg, val_lng_id);

        IF recheck_completeness THEN -- bad style
            CASE val_lng_id IS NULL
                WHEN TRUE THEN
                    SELECT complete_isit
                    INTO new_completeness
                    FROM configurations AS c
                    WHERE NEW.configuration_id   = c.configuration_id
                      AND NEW.confentity_code_id = c.confentity_code_id;
                ELSE
                    SELECT complete_isit
                    INTO new_completeness
                    FROM configurations_bylngs AS c
                    WHERE NEW.configuration_id   = c.configuration_id
                      AND NEW.confentity_code_id = c.confentity_code_id
                      AND             val_lng_id = c.value_lng_code_id;
            END CASE;
            NEW.complete_isit:= new_completeness;
        END IF;

        CASE TG_OP
            WHEN 'INSERT' THEN
                RETURN NEW;
            WHEN 'UPDATE' THEN
                RETURN NEW;
            WHEN 'DELETE' THEN
                RETURN OLD;
        END CASE;
END;
$confentity_domain_onmonify$;

CREATE TRIGGER tri_confentity_onmodify       AFTER INSERT OR UPDATE OR DELETE ON configurable_entities
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_config_onmodify           AFTER INSERT OR UPDATE OR DELETE ON configurations
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_configlng_onmodify        AFTER INSERT OR UPDATE OR DELETE ON configurations_bylngs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparam_onmodify        AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparam_l_onmodify      AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters__leafs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparamvalue_l_onmodify AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters_values__leafs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparamlngvalue_l_onmodify AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters_lngvalues__leafs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparam_s_onmodify      AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparamvalue_s_onmodify AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters_values__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.init.sql [END]