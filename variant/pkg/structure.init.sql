-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> structure.init.sql
\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

INSERT INTO dbp_packages (package_name, package_version, dbp_standard_version)
                   VALUES('<<$pkg.name$>>', '<<$pkg.ver$>>', '<<$pkg.std_ver$>>');

-- ^^^ don't change this !!

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Usual codifiers')
        , ROW ('Configurable entities', 'codifier' :: code_type) :: code_construction_input
        , ''
        , VARIADIC ARRAY[] :: code_construction_input[] -- subcodes
        ) AS configurable_entities__codifier_id;
SELECT new_code_by_userseqs(
          ROW ('configurable entity', 'plain code' :: code_type) :: code_construction_input
        , make_codekeyl_bystr('Named entities')
        , FALSE
        , ''
        , 'sch_<<$app_name$>>.namentities_ids_seq'
        ) AS configurable_entity__as_nameable_entitiy_id;

------

CREATE TABLE configurable_entities (
        confentity_code_id       integer NOT NULL PRIMARY KEY
      , default_configuration_id varchar     NULL
      , CONSTRAINT cnstr_delfrom_tbl_configurable_entities_first FOREIGN KEY (confentity_code_id) REFERENCES codes (code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , CHECK (code_belongs_to_codifier(
                          FALSE
                        , make_acodekeyl( make_codekey_null()
                                        , make_codekey_bystr('Configurable entities')
                                        , make_codekey_byid(confentity_code_id)
               )        )               )
     -- A FK is also added a bit later
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurable_entities TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurable_entities TO user_<<$app_name$>>_data_reader;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TYPE t_config_completeness_check_result AS ENUM ('th_chk_V', 'th_chk_X', 'li_chk_V', 'li_chk_X', 'nf_X', 'cy_X', 'le_V');
COMMENT ON TYPE t_config_completeness_check_result IS '
th_chk_V - subconfig is   complete (by thorough check)
th_chk_X - subconfig is incomplete (by thorough check)
li_chk_V - subconfig is   complete (by light check)
li_chk_X - subconfig is incomplete (by light check)
nf_X - subconfig not found in configurations table
cy_X - cycles not supported
le_V - check skipped because N/A to leaf
';

---------------------

CREATE TYPE t_completeness_as_regulator AS ENUM ('RESTRICT', 'STRICT CHECK', 'CHECK SET', 'SET INCOMPLETE');
COMMENT ON TYPE t_completeness_as_regulator IS'
The parameter determines what to do, when some action takes place which may influence completeness of configurations.
The use of this parameter is coupled with parameter "when to check completeness".
If "when to check completeness" = "FOR COMPLETE ONLY", then behavior determined by "completeness as regulator" will be trigger only for complete configurations, but for noncomplete ones - no concern will occur.
Possible values:
** "RESTRICT"       - do not allow any such action (which may influence on completeness of configuration).
** "STRICT CHECK"   - for complete configurations - fully recheck completeness; for (previously) noncomplete ones - check if resulting config is complete. If resulting config is complete, then the action is allowed, otherwise action is restricted.
** "CHECK SET"      - action is allowed anyway, but for complete configurations full completeness recheck is also performed, - if it isn''t complete, then set to FALSE.
** "SET INCOMPLETE" - action is allowed and configuration compleness is set to FALSE.
';

----------------------

CREATE TABLE configurations (
        confentity_code_id integer NOT NULL REFERENCES configurable_entities(confentity_code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , configuration_id   varchar NOT NULL
      , complete_isit      t_config_completeness_check_result NOT NULL DEFAULT 'li_chk_X' CHECK (complete_isit NOT IN ('nf_X', 'le_V'))
      , completeness_as_regulator
                           t_completeness_as_regulator NULL
      , PRIMARY KEY (confentity_code_id, configuration_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

COMMENT ON TABLE configurations IS '
If field "completeness_as_regulator" is NULL, then value from "Configuration management system setup" is taken as default.
This is a very useful for case, when you want to protect configurations used in real system from accidental modification - just set it to "RESTRICT", and no change will be allowed even in the deepest subconfig.
Meanwhile, you may clone your protected config (using "clone_config" function), and play with the clone however you want, creating new critical configuration version.

Field "complete_isit" is an indicator, that shows if all values for all parameters and/in subconfiguration parts (recursively) are specified and respect all user-imposed constraints. Only complete configurations are good enough to be used in real systems.
Configuration may become incomplete automatically, once user modifies any "complete-sensetive" data ((sub)parameter values, defaults, subconfigs, constraints...).
There are two ways to command system to recheck completeness and update the "complete_isit" field of incomplete configuration:
(1) Using "try_to_complete_config(par_config_key t_config_key)" function (or using related function: "config_completeness").
(2) (      Set filed "completeness_as_regulator" value to "STRICT CHECK" OR "CHECK SET";
    OR (   Set filed "completeness_as_regulator" value to NULL
       AND Set configuration parameter "Configuration management system setup"."completeness as regulator" = "STRICT CHECK" OR "CHECK SET"
       )
    )
    Then do the "UPDATE configurations SET complete_isit = ''li_chk_V'' WHERE confentity_code_id = <your_confentity_code> AND configuration_id = <your_config_id>;"
    (Notice, that you must specify confentity code ID, since configuration_id alone is not enough to uniquely identify config)
';

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations TO user_<<$app_name$>>_data_reader;

CREATE INDEX configs_confentities_idx ON configurations(confentity_code_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

ALTER TABLE configurable_entities
        ADD CONSTRAINT cnstr_confentities_default_configs
                FOREIGN KEY              (confentity_code_id, default_configuration_id)
                REFERENCES configurations(confentity_code_id,         configuration_id)
                        ON DELETE RESTRICT ON UPDATE CASCADE;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TABLE configurations_names (
        confentity_code_id integer NOT NULL
      , configuration_id   varchar NOT NULL
      , PRIMARY KEY (confentity_code_id, configuration_id, lng_of_name)
      , FOREIGN KEY (confentity_code_id, configuration_id) REFERENCES configurations(confentity_code_id, configuration_id)
                                                            ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , FOREIGN KEY (entity)      REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

SELECT new_code_by_userseqs(
                  ROW ('configuration', 'plain code' :: code_type) :: code_construction_input
                , make_codekeyl_bystr('Named entities')
                , FALSE
                , ''
                , 'sch_<<$app_name$>>.namentities_ids_seq'
                ) AS configuration__as_namable_entity_id;

ALTER TABLE configurations_names ALTER COLUMN entity SET DEFAULT code_id_of_entity('configuration');

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations_names TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations_names TO user_<<$app_name$>>_data_reader;

CREATE INDEX names_of_configs_idx ON configurations_names(name) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TYPE t_confparam_type AS ENUM ('leaf', 'subconfig');

CREATE TYPE t_confparam_constraint AS (constraint_function varchar);

CREATE OR REPLACE FUNCTION mk_confparam_constraint(par_fun varchar) RETURNS t_confparam_constraint AS $$
        SELECT ROW($1) :: t_confparam_constraint;
$$ LANGUAGE SQL;

COMMENT ON TYPE t_confparam_constraint IS
'A definite standart must be followed here:
(1) Constraint function is a function that accepts $1 as a parameter value (subconfiguration ID in case, when parameter type is "subconfig")
(2) Constraint function is a function that accepts $2 as a configuration ID, for which the parameter value is specified
(3) Constraint function return-type is boolean.
(4) If constraint function returns NULL it is treated as a constraint violation.

--------

It''s recommended to use "mk_confparam_constraint(varchar)" constructor.
Examples of constraints:
** mk_confparam_constraint(''SELECT (($1 :: integer) >= -100) AND (($1 :: integer) <= 100)'')
** mk_confparam_constraint(''SELECT my_constraint_function_that_returns_boolean($1,$2)'')
** mk_confparam_constraint(''SELECT $1 ~ ''''^(yes|no)[1234567890]*$'''' '')
** mk_confparam_constraint(''upper($1) IN (SELECT x.a :: varchar FROM unnest(enum_range(NULL :: t_my_own_enum_type)) AS x(a)) IS NOT DISTINCT FROM TRUE''
Notice, that both parameters are of type varchar, but there is no need to put quotes around them inside a constraint function.

Btw, manual on usage of POSIX regexps in PostgreSQL (v8.4):
http://www.postgresql.org/docs/8.4/interactive/functions-matching.html
';

------

CREATE TYPE t_confparam_default_usage AS ENUM ('no_d', 'par_d', 'sce_d', 'par_d_sce_d');
COMMENT ON TYPE t_confparam_default_usage IS '
Field "use_default_instead_of_null" may have following values
no_d        - don''t use defaults
par_d       -        use only parameter default
sce_d       -        use only subconfentity default
par_d_sce_d -        use parameter default - if it is NULL, then use subconfentity default
';

--------

CREATE TABLE configurations_parameters (
         confentity_code_id integer NOT NULL
       , parameter_id       varchar NOT NULL
       , parameter_type     t_confparam_type NOT NULL
       , constraints_array  t_confparam_constraint[] NOT NULL DEFAULT (ARRAY[] :: t_confparam_constraint[])
       , allow_null_final_value        boolean NOT NULL
       , use_default_instead_of_null   t_confparam_default_usage NOT NULL
       , PRIMARY KEY (confentity_code_id, parameter_id)
       , FOREIGN KEY (confentity_code_id) REFERENCES configurable_entities(confentity_code_id) ON DELETE CASCADE ON UPDATE CASCADE
       , CHECK (parameter_type = 'subconfig' OR use_default_instead_of_null NOT IN ('sce_d', 'par_d_sce_d'))
         -- don't remove this constraint - some API trusts in it
       , UNIQUE (confentity_code_id, parameter_id, parameter_type)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations_parameters TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations_parameters TO user_<<$app_name$>>_data_reader;

CREATE INDEX confentities_of_params_idx ON configurations_parameters(confentity_code_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE INDEX params_of_confentities_idx ON configurations_parameters(parameter_id)       TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TABLE configurations_parameters_names (
        confentity_code_id integer NOT NULL
      , parameter_id       varchar NOT NULL
      , PRIMARY KEY (confentity_code_id, parameter_id, lng_of_name)
      , FOREIGN KEY (confentity_code_id, parameter_id) REFERENCES configurations_parameters(confentity_code_id, parameter_id)
                                                            ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , FOREIGN KEY (entity)      REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

SELECT new_code_by_userseqs(
                  ROW ('configuration parameter', 'plain code' :: code_type) :: code_construction_input
                , make_codekeyl_bystr('Named entities')
                , FALSE
                , ''
                , 'sch_<<$app_name$>>.namentities_ids_seq'
                ) AS configuration_parameter__as_nameable_entity_id;

ALTER TABLE configurations_parameters_names ALTER COLUMN entity SET DEFAULT code_id_of_entity('configuration parameter');

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations_parameters_names TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations_parameters_names TO user_<<$app_name$>>_data_reader;

CREATE INDEX names_of_confparams_idx ON configurations_parameters_names(name) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TABLE configurations_parameters__leafs (
        confentity_code_id integer NOT NULL
      , parameter_id       varchar NOT NULL
      , default_value      varchar     NULL
      , parameter_type     t_confparam_type NOT NULL DEFAULT 'leaf' CHECK (parameter_type = 'leaf')
      , PRIMARY KEY (confentity_code_id, parameter_id)
      , FOREIGN KEY (confentity_code_id, parameter_id)
                    REFERENCES configurations_parameters(confentity_code_id, parameter_id)
                    ON DELETE CASCADE  ON UPDATE CASCADE
      , UNIQUE (confentity_code_id, parameter_id, parameter_type)
      , FOREIGN KEY (confentity_code_id, parameter_id, parameter_type)
                    REFERENCES configurations_parameters(confentity_code_id, parameter_id, parameter_type)
                    ON DELETE CASCADE ON UPDATE CASCADE
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations_parameters__leafs TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations_parameters__leafs TO user_<<$app_name$>>_data_reader;

CREATE        INDEX pl_confentities_of_params_idx ON configurations_parameters__leafs(confentity_code_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE        INDEX pl_params_of_confentities_idx ON configurations_parameters__leafs(parameter_id)       TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TABLE configurations_parameters_values__leafs (
        confentity_code_id integer NOT NULL
      , parameter_id       varchar NOT NULL
      , configuration_id   varchar NOT NULL
      , value              varchar     NULL
      , PRIMARY KEY (confentity_code_id, parameter_id, configuration_id)
      , FOREIGN KEY (confentity_code_id, parameter_id)
                    REFERENCES configurations_parameters__leafs(confentity_code_id, parameter_id)
                    ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (confentity_code_id, configuration_id)
                    REFERENCES configurations(confentity_code_id, configuration_id)
                    ON DELETE CASCADE  ON UPDATE CASCADE
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations_parameters_values__leafs TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations_parameters_values__leafs TO user_<<$app_name$>>_data_reader;

CREATE INDEX pvl_confentities_of_params_idx ON configurations_parameters_values__leafs(confentity_code_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE INDEX pvl_params_of_confentities_idx ON configurations_parameters_values__leafs(parameter_id)       TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TYPE t_subconfig_value_linking_read_rule AS ENUM ('alw_onl_lnk', 'whn_vnull_lnk', 'no_lnk');

COMMENT ON TYPE t_subconfig_value_linking_read_rule IS '
Values:
alw_onl_lnk   - parameter value will always be considered from the link-field, and the value-field will be always ignored
whn_vnull_lnk - parameter value will always be considered from the link-field only when value-field contains NULL
no_lnk        - link-field will always be ignored
';
-------

CREATE TABLE configurations_parameters__subconfigs (
        confentity_code_id    integer NOT NULL
      , parameter_id          varchar NOT NULL
      , subconfentity_code_id integer NOT NULL REFERENCES configurable_entities(confentity_code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , overload_default_subconfig varchar NULL
      , overload_default_link      varchar NULL
      , overload_default_link_usage  t_subconfig_value_linking_read_rule NOT NULL
      , parameter_type        t_confparam_type NOT NULL DEFAULT 'subconfig' CHECK (parameter_type = 'subconfig')
      , PRIMARY KEY (confentity_code_id, parameter_id)
      , FOREIGN KEY (confentity_code_id, parameter_id)
                    REFERENCES configurations_parameters(confentity_code_id, parameter_id)
                    ON DELETE CASCADE  ON UPDATE CASCADE
      , UNIQUE (confentity_code_id, parameter_id, parameter_type)
      , FOREIGN KEY (confentity_code_id, parameter_id, parameter_type)
                    REFERENCES configurations_parameters(confentity_code_id, parameter_id, parameter_type)
                    ON DELETE CASCADE ON UPDATE CASCADE
      , FOREIGN KEY (subconfentity_code_id, overload_default_subconfig)
                    REFERENCES configurations(confentity_code_id, configuration_id)
                    ON DELETE RESTRICT ON UPDATE CASCADE
      , UNIQUE (confentity_code_id, parameter_id, subconfentity_code_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

ALTER TABLE configurations_parameters__subconfigs
        ADD CONSTRAINT cnstr_configurations_parameters__subconfigs_paramlinks
                FOREIGN KEY     (confentity_code_id, overload_default_link, subconfentity_code_id)
                REFERENCES configurations_parameters__subconfigs
                                (confentity_code_id, parameter_id, subconfentity_code_id)
                        ON DELETE RESTRICT ON UPDATE CASCADE;

COMMENT ON TABLE configurations_parameters__subconfigs IS
'Default specified for subconfig parameter may be
**   direct reference on subconfiguration: (subconfentity_code_id, overload_default_subconfig)
** indirect reference on subconfiguration: (confentity_code_id, overload_default_link, subconfentity_code_id) -> configurations_parameters__subconfigs(confentity_code_id, parameter_id, subconfentity_code_id)
For the second case, the final value is read from referenced parameter, *under same configuration*.
For the second case to be possible, field "overload_default_link_usage" value must be apropriate.
Indirect reference on subconfiguration may be also used in the table with values of parameters.
';

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations_parameters__subconfigs TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations_parameters__subconfigs TO user_<<$app_name$>>_data_reader;

CREATE UNIQUE INDEX          cp_s_ilref_base_uidx ON configurations_parameters__subconfigs(confentity_code_id, parameter_id, subconfentity_code_id)
                                                                                                               TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE        INDEX ps_confentities_of_params_idx ON configurations_parameters__subconfigs(confentity_code_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE        INDEX ps_params_of_confentities_idx ON configurations_parameters__subconfigs(parameter_id)       TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TABLE configurations_parameters_values__subconfigs (
        confentity_code_id    integer NOT NULL
      , parameter_id          varchar NOT NULL
      , configuration_id      varchar NOT NULL
      , subconfentity_code_id integer NOT NULL
      , subconfiguration_id   varchar     NULL
      , subconfiguration_link varchar     NULL
      , subconfiguration_link_usage t_subconfig_value_linking_read_rule NOT NULL
      , PRIMARY KEY (confentity_code_id, parameter_id, configuration_id)
      , FOREIGN KEY (confentity_code_id, parameter_id, subconfentity_code_id)
                    REFERENCES configurations_parameters__subconfigs(confentity_code_id, parameter_id, subconfentity_code_id)
                    ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (confentity_code_id, configuration_id)
                    REFERENCES configurations(confentity_code_id, configuration_id)
                    ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (subconfentity_code_id, subconfiguration_id)
                    REFERENCES configurations(confentity_code_id, configuration_id)
                    ON DELETE RESTRICT ON UPDATE CASCADE
      , FOREIGN KEY (confentity_code_id, subconfiguration_link, subconfentity_code_id)
                    REFERENCES configurations_parameters__subconfigs(confentity_code_id, parameter_id, subconfentity_code_id)
                    ON DELETE RESTRICT ON UPDATE CASCADE
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE configurations_parameters_values__subconfigs TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE configurations_parameters_values__subconfigs TO user_<<$app_name$>>_data_reader;

CREATE        INDEX pvs_confentities_of_params_idx ON configurations_parameters_values__subconfigs(confentity_code_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE        INDEX pvs_params_of_confentities_idx ON configurations_parameters_values__subconfigs(parameter_id)       TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

COMMENT ON TABLE configurations_parameters_values__subconfigs IS
'Default specified for subconfig parameter may be
**   direct reference on subconfiguration: (subconfentity_code_id, subconfiguration_id)
** indirect reference on subconfiguration: (confentity_code_id, configuration_id, subconfiguration_link, subconfentity_code_id) -> configurations_parameters__subconfigs(confentity_code_id, configuration_id, parameter_id, subconfentity_code_id)
For the second case, the final value is read from referenced parameter, under same configuration.
For the second case to be possible, field "subconfiguration_link_usage" value must be apropriate.
Indirect reference on subconfiguration may be also used in the table with instaniation of parameters.
';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\i functions.init.sql
\i ../data/data.init.sql

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Triggers:

-- now selfreferring configs will be deletable
CREATE OR REPLACE FUNCTION confentity_ondelete() RETURNS trigger AS $confentity_ondelete$ -- before delete
BEGIN
        DELETE FROM sch_<<$app_name$>>.configurations_parameters WHERE confentity_code_id = OLD.confentity_code_id;
        RETURN OLD;
END;
$confentity_ondelete$ LANGUAGE plpgsql;

CREATE TRIGGER tri_a_confentity_ondelete BEFORE DELETE ON sch_<<$app_name$>>.configurable_entities
    FOR EACH ROW EXECUTE PROCEDURE confentity_ondelete();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION cfgunit_oncredel() RETURNS trigger AS $cfgunit_oncredel$ -- ins, del
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
            WHEN 'configurations_parameters__leafs' THEN
                entity_name:= 'Configuration leaf-parameter';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; param_id: "' || the_row.parameter_id || '")';
            WHEN 'configurations_parameters' THEN
                entity_name:= 'Configuration parameter (abstract)';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; param_id: "' || the_row.parameter_id || '")';
            WHEN 'configurations_parameters_values__leafs' THEN
                entity_name:= 'Configuration leaf-parameter value';
                instance_id:= '(ce_id: ' || the_row.confentity_code_id || '; cfg_id: "' || the_row.configuration_id || '"; param_id: "' || the_row.parameter_id || '")';
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
$cfgunit_oncredel$ LANGUAGE plpgsql;

CREATE TRIGGER tri_z_confentity_oncredel       AFTER INSERT OR DELETE ON configurable_entities
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_config_oncredel           AFTER INSERT OR DELETE ON configurations
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparam_oncredel        AFTER INSERT OR DELETE ON configurations_parameters
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparam_l_oncredel      AFTER INSERT OR DELETE ON configurations_parameters__leafs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparamvalue_l_oncredel AFTER INSERT OR DELETE ON configurations_parameters_values__leafs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparam_s_oncredel      AFTER INSERT OR DELETE ON configurations_parameters__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();
CREATE TRIGGER tri_z_confparamvalue_s_oncredel AFTER INSERT OR DELETE ON configurations_parameters_values__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE cfgunit_oncredel();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION confentity_domain_onmonify() RETURNS trigger AS $confentity_domain_onmonify$ -- upd
DECLARE
        o_ce_id integer;
        n_ce_id integer;
        recheck_completeness boolean := FALSE;
        new_completeness sch_<<$app_name$>>.t_config_completeness_check_result;
        dep_cts          sch_<<$app_name$>>.t_configs_tree_rel[];
        exclud_cfg       sch_<<$app_name$>>.t_config_key;

        namespace_info   sch_<<$app_name$>>.t_namespace_info;
BEGIN
        IF TG_OP NOT IN ('INSERT', 'DELETE', 'UPDATE') THEN
                RAISE EXCEPTION 'Error in the "confentity_domain_onmonify" TRIGGER function! Unsupported triggerring operation: "%".', TG_OP;
        END IF;

        CASE sch_<<$app_name$>>.read_cfgmngsys_setup__perform_completness_routines()
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

        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        exclud_cfg:= make_configkey_null();
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

            WHEN 'configurations' THEN
                CASE TG_OP
                    WHEN 'INSERT' THEN
                        recheck_completeness:= TRUE;
                        dep_cts:= configs_that_use_subconfig(make_configkey_bystr(NEW.confentity_code_id, NEW.configuration_id), TRUE, FALSE);
                    WHEN 'UPDATE' THEN
                        recheck_completeness:= TRUE;
                        IF    (NEW.configuration_id   IS DISTINCT FROM OLD.configuration_id)
                           OR (NEW.confentity_code_id IS DISTINCT FROM OLD.confentity_code_id)
                           OR (completeness_interpretation(NEW.complete_isit) IS DISTINCT FROM completeness_interpretation(OLD.complete_isit))
                        THEN
                                dep_cts:= configs_that_use_subconfig(make_configkey_bystr(NEW.confentity_code_id, NEW.configuration_id), TRUE, FALSE)
                                       || configs_that_use_subconfig(make_configkey_bystr(OLD.confentity_code_id, OLD.configuration_id), TRUE, FALSE);
                                IF completeness_interpretation(OLD.complete_isit) IS DISTINCT FROM TRUE THEN
                                        exclud_cfg:= make_configkey_bystr(NEW.confentity_code_id, NEW.configuration_id);
                                END IF;
                        END IF;
                    WHEN 'DELETE' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey_bystr(OLD.confentity_code_id, OLD.configuration_id), TRUE, FALSE);
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
            WHEN 'configurations_parameters_values__subconfigs', 'configurations_parameters_values__leafs' THEN
                CASE TG_OP
                    WHEN 'INSERT' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey_bystr(NEW.confentity_code_id, NEW.configuration_id), TRUE, FALSE);
                    WHEN 'UPDATE' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey_bystr(OLD.confentity_code_id, OLD.configuration_id), TRUE, FALSE);
                        IF    (NEW.configuration_id   IS DISTINCT FROM OLD.configuration_id)
                           OR (NEW.confentity_code_id IS DISTINCT FROM OLD.confentity_code_id)
                        THEN
                                dep_cts:= dep_cts || configs_that_use_subconfig(make_configkey_bystr(NEW.confentity_code_id, NEW.configuration_id), TRUE, FALSE);
                        END IF;
                    WHEN 'DELETE' THEN
                        dep_cts:= configs_that_use_subconfig(make_configkey_bystr(OLD.confentity_code_id, OLD.configuration_id), TRUE, FALSE);
                END CASE;
            ELSE RAISE EXCEPTION 'Error in the "confentity_domain_onmonify" TRIGGER function! Unsupported table: "%".', TG_TABLE_NAME;
        END CASE;

        PERFORM update_cfgs_ondepmodify(dep_cts, exclud_cfg);

        IF recheck_completeness THEN -- bad style
                SELECT complete_isit
                INTO new_completeness
                FROM configurations AS c
                WHERE NEW.configuration_id   = c.configuration_id
                  AND NEW.confentity_code_id = c.confentity_code_id;

                NEW.complete_isit:= new_completeness;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        CASE TG_OP
            WHEN 'INSERT' THEN
                RETURN NEW;
            WHEN 'UPDATE' THEN
                RETURN NEW;
            WHEN 'DELETE' THEN
                RETURN OLD;
        END CASE;
END;
$confentity_domain_onmonify$ LANGUAGE plpgsql;

CREATE TRIGGER tri_confentity_onmodify       AFTER INSERT OR UPDATE OR DELETE ON configurable_entities
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_config_onmodify           AFTER INSERT OR UPDATE OR DELETE ON configurations
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparam_onmodify        AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparam_l_onmodify      AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters__leafs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparamvalue_l_onmodify AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters_values__leafs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparam_s_onmodify      AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();
CREATE TRIGGER tri_confparamvalue_s_onmodify AFTER INSERT OR UPDATE OR DELETE ON configurations_parameters_values__subconfigs
    FOR EACH ROW EXECUTE PROCEDURE confentity_domain_onmonify();

------------------

-- CREATE ...
-- GRANT ...

-- CREATE TRIGGER ...

