CREATE OR REPLACE FUNCTION next_id_v1(sequence_id regclass, OUT result bigint) AS $$
                DECLARE
                    our_epoch bigint := 1409266191000;
                    seq_id bigint;
                    now_millis bigint;
                BEGIN
                    SELECT nextval(sequence_id) % 1024 INTO seq_id;
                    SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
                    result := (now_millis - our_epoch) << 23;
                    result := result | (seq_id << 13);
                END;
                $$ LANGUAGE PLPGSQL;
                
CREATE SEQUENCE IF NOT EXISTS origin_secrets_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_package_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_channel_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_integration_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_invitations_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_private_encryption_key_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_project_integration_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_project_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_public_key_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_secret_key_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_id_seq;
CREATE SEQUENCE IF NOT EXISTS origin_public_encryption_key_id_seq;

CREATE TABLE IF NOT EXISTS origins (
    id bigint DEFAULT next_id_v1('origin_id_seq') PRIMARY KEY NOT NULL,
    name text UNIQUE,
    owner_id bigint,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    default_package_visibility text DEFAULT 'public'::text NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_package (
    origin_id bigint,
    package_id bigint,
    channel_id bigint,
    operation smallint,
    trigger smallint,
    requester_id bigint,
    requester_name text,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_package_group (
    origin_id bigint,
    channel_id bigint,
    package_ids bigint[],
    operation smallint,
    trigger smallint,
    requester_id bigint,
    requester_name text,
    group_id bigint,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS origin_secrets (
    id bigint DEFAULT next_id_v1('origin_secrets_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    owner_id bigint,
    name text,
    value text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (origin_id, name)
);

CREATE TABLE IF NOT EXISTS origin_packages (
    id bigint DEFAULT next_id_v1('origin_package_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    owner_id bigint,
    name text,
    ident text UNIQUE,
    ident_array text[],
    checksum text,
    manifest text,
    config text,
    target text,
    deps text,
    tdeps text,
    exposes text,
    scheduler_sync boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    visibility text DEFAULT 'public'::text NOT NULL
);

CREATE TABLE IF NOT EXISTS origin_channels (
    id bigint DEFAULT next_id_v1('origin_channel_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    owner_id bigint,
    name text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (origin_id, name)
);

CREATE TABLE IF NOT EXISTS origin_integrations (
    id bigint DEFAULT next_id_v1('origin_integration_id_seq') PRIMARY KEY NOT NULL,
    origin text,
    integration text,
    name text,
    body text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (origin, integration, name)
);

CREATE TABLE IF NOT EXISTS origin_invitations (
    id bigint DEFAULT next_id_v1('origin_invitations_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    origin_name text,
    account_id bigint,
    account_name text,
    owner_id bigint,
    ignored boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (origin_id, account_id)
);

CREATE TABLE IF NOT EXISTS origin_private_encryption_keys (
    id bigint DEFAULT next_id_v1('origin_private_encryption_key_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    owner_id bigint,
    name text,
    revision text,
    full_name text UNIQUE,
    body bytea,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS origin_projects (
    id bigint DEFAULT next_id_v1('origin_project_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    origin_name text,
    package_name text,
    name text,
    plan_path text,
    owner_id bigint,
    vcs_type text,
    vcs_data text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    vcs_auth_token text,
    vcs_username text,
    vcs_installation_id bigint,
    visibility text DEFAULT 'public'::text NOT NULL,
    auto_build boolean DEFAULT true NOT NULL,
    UNIQUE (origin_name, package_name, name)
);

CREATE TABLE IF NOT EXISTS origin_project_integrations (
    id bigint DEFAULT next_id_v1('origin_project_integration_id_seq') PRIMARY KEY NOT NULL,
    origin text NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    project_id bigint NOT NULL REFERENCES origin_projects(id) ON DELETE CASCADE,
    integration_id bigint NOT NULL REFERENCES origin_integrations(id) ON DELETE CASCADE,
    UNIQUE (project_id, integration_id)
);

CREATE TABLE IF NOT EXISTS origin_public_encryption_keys (
    id bigint DEFAULT next_id_v1('origin_public_key_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    owner_id bigint,
    name text,
    revision text,
    full_name text UNIQUE,
    body bytea,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS origin_public_keys (
    id bigint DEFAULT next_id_v1('origin_public_key_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    owner_id bigint,
    name text,
    revision text,
    full_name text UNIQUE,
    body bytea,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS origin_secret_keys (
    id bigint DEFAULT next_id_v1('origin_secret_key_id_seq') PRIMARY KEY NOT NULL,
    origin_id bigint REFERENCES origins(id),
    owner_id bigint,
    name text,
    revision text,
    full_name text UNIQUE,
    body bytea,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS origin_channel_packages (
    channel_id bigint NOT NULL REFERENCES origin_channels(id) ON DELETE CASCADE,
    package_id bigint NOT NULL REFERENCES origin_packages(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (channel_id, package_id)
);

CREATE TABLE IF NOT EXISTS origin_members (
    origin_id bigint NOT NULL REFERENCES origins(id),
    origin_name text,
    account_id bigint NOT NULL,
    account_name text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (origin_id, account_id)
);

CREATE OR REPLACE FUNCTION accept_origin_invitation_v1(oi_invite_id bigint, oi_ignore boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    oi_origin_id bigint;
    oi_origin_name text;
    oi_account_id bigint;
    oi_account_name text;
  BEGIN
    IF oi_ignore = true THEN
      UPDATE origin_invitations SET ignored = true, updated_at = now() WHERE id = oi_invite_id;
    ELSE
      SELECT origin_id, origin_name, account_id, account_name INTO oi_origin_id, oi_origin_name, oi_account_id, oi_account_name FROM origin_invitations WHERE id = oi_invite_id;
      PERFORM insert_origin_member_v1(oi_origin_id, oi_origin_name, oi_account_id, oi_account_name);
      DELETE FROM origin_invitations WHERE id = oi_invite_id;
    END IF;
  END
$$;

CREATE OR REPLACE FUNCTION add_audit_package_entry_v1(p_origin_id bigint, p_package_id bigint, p_channel_id bigint, p_operation smallint, p_trigger smallint, p_requester_id bigint, p_requester_name text) RETURNS SETOF audit_package
    LANGUAGE sql
    AS $$
INSERT INTO audit_package (origin_id, package_id, channel_id, operation, trigger, requester_id, requester_name)
VALUES (p_origin_id, p_package_id, p_channel_id, p_operation, p_trigger, p_requester_id, p_requester_name)
RETURNING *;
$$;

CREATE OR REPLACE FUNCTION add_audit_package_group_entry_v1(p_origin_id bigint, p_channel_id bigint, p_package_ids bigint[], p_operation smallint, p_trigger smallint, p_requester_id bigint, p_requester_name text, p_group_id bigint) RETURNS SETOF audit_package_group
    LANGUAGE sql
    AS $$
INSERT INTO audit_package_group (origin_id, channel_id, package_ids, operation, trigger, requester_id, requester_name, group_id)
VALUES (p_origin_id, p_channel_id, p_package_ids, p_operation, p_trigger, p_requester_id, p_requester_name, p_group_id)
RETURNING *;
$$;

CREATE OR REPLACE FUNCTION check_account_in_origin_members_v1(om_origin_name text, om_account_id bigint) RETURNS TABLE(is_member boolean)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT true FROM origin_members WHERE origin_name = om_origin_name AND account_id = om_account_id;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION delete_origin_channel_v1(channel_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
  BEGIN
      DELETE FROM origin_channels WHERE id = channel_id;
  END
$$;

CREATE OR REPLACE FUNCTION delete_origin_integration_v1(in_origin text, in_integration text, in_name text) RETURNS void
    LANGUAGE sql
    AS $$
  DELETE FROM origin_integrations
  WHERE origin = in_origin AND integration = in_integration AND name = in_name
$$;

CREATE OR REPLACE FUNCTION delete_origin_member_v1(om_origin_id bigint, om_account_name text) RETURNS void
    LANGUAGE sql
    AS $$
      DELETE FROM origin_members WHERE origin_id=om_origin_id AND account_name=om_account_name;
$$;

CREATE OR REPLACE FUNCTION delete_origin_project_integration_v1(p_origin text, p_package text, p_integration text) RETURNS void
    LANGUAGE plpgsql
    AS $$
    BEGIN
        DELETE FROM origin_project_integrations
        WHERE origin = p_origin
        AND project_id = (SELECT id FROM origin_projects WHERE origin_name = p_origin AND package_name = p_package)
        AND integration_id = (SELECT id FROM origin_integrations WHERE origin = p_origin AND name = p_integration);
    END
$$;

CREATE OR REPLACE FUNCTION delete_origin_project_v1(project_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
  BEGIN
      DELETE FROM origin_projects WHERE name = project_name;
  END
$$;


CREATE OR REPLACE FUNCTION delete_origin_secret_v1(os_origin_id bigint, os_name text) RETURNS SETOF origin_secrets
    LANGUAGE sql
    AS $$
    DELETE FROM origin_secrets WHERE name = os_name AND origin_id = os_origin_id
    RETURNING *
$$;

CREATE OR REPLACE FUNCTION demote_origin_package_group_v1(opp_channel_id bigint, opp_package_ids bigint[]) RETURNS void
    LANGUAGE sql
    AS $$
    DELETE FROM origin_channel_packages WHERE channel_id=opp_channel_id AND package_id = ANY(opp_package_ids);
$$;

CREATE OR REPLACE FUNCTION demote_origin_package_v1(opp_channel_id bigint, opp_package_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
      DELETE FROM origin_channel_packages WHERE channel_id=opp_channel_id AND package_id=opp_package_id;
$$;

CREATE OR REPLACE FUNCTION get_all_origin_packages_for_ident_v1(op_ident text) RETURNS SETOF origin_packages
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_packages WHERE ident LIKE (op_ident || '%') ORDER BY ident;
    RETURN;
  END
  $$;

CREATE OR REPLACE FUNCTION get_all_origin_packages_for_origin_v1(op_id bigint) RETURNS SETOF origin_packages
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_packages WHERE id = op_id;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_channel_package_latest_v5(op_origin text, op_channel text, op_ident text, op_target text, op_visibilities text) RETURNS SETOF origin_packages
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT op.*
      FROM origin_packages op
      INNER JOIN origin_channel_packages ocp on ocp.package_id = op.id
      INNER JOIN origin_channels oc on ocp.channel_id = oc.id
      INNER JOIN origins o on oc.origin_id = o.id
      WHERE o.name = op_origin
      AND oc.name = op_channel
      AND op.target = op_target
      AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
      AND op.ident LIKE (op_ident  || '%');
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_channel_package_v4(op_origin text, op_channel text, op_ident text, op_visibilities text) RETURNS SETOF origin_packages
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT op.*
      FROM origin_packages op
      INNER JOIN origin_channel_packages ocp on ocp.package_id = op.id
      INNER JOIN origin_channels oc on ocp.channel_id = oc.id
      INNER JOIN origins o on oc.origin_id = o.id
      WHERE op.ident = op_ident
      AND o.name = op_origin
      AND oc.name = op_channel
      AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','));
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_channel_packages_for_channel_v3(op_origin text, op_channel text, op_ident text, op_visibilities text, op_limit bigint, op_offset bigint) RETURNS TABLE(total_count bigint, ident text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT COUNT(*) OVER () AS total_count, op.ident
      FROM origin_packages op
      INNER JOIN origin_channel_packages ocp on ocp.package_id = op.id
      INNER JOIN origin_channels oc on ocp.channel_id = oc.id
      INNER JOIN origins o on oc.origin_id = o.id
      WHERE o.name = op_origin
      AND oc.name = op_channel
      AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
      AND op.ident LIKE (op_ident  || '%')
      ORDER BY ident ASC
      LIMIT op_limit OFFSET op_offset;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_channel_v1(ocg_origin text, ocg_name text) RETURNS SETOF origin_channels
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT origin_channels.*
        FROM origins INNER JOIN origin_channels ON origins.id = origin_channels.origin_id
        WHERE origins.name=ocg_origin AND origin_channels.name = ocg_name;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_channels_for_origin_v2(occ_origin_id bigint, occ_include_sandbox_channels boolean) RETURNS SETOF origin_channels
    LANGUAGE sql STABLE
    AS $$
    SELECT *
    FROM origin_channels
    WHERE origin_id = occ_origin_id
    AND (occ_include_sandbox_channels = true OR (occ_include_sandbox_channels = false AND name NOT LIKE 'bldr-%'))
    ORDER BY name ASC;
$$;

CREATE OR REPLACE FUNCTION get_origin_integration_v1(in_origin text, in_integration text, in_name text) RETURNS SETOF origin_integrations
    LANGUAGE sql STABLE
    AS $$
  SELECT *
    FROM origin_integrations
   WHERE origin = in_origin
     AND integration = in_integration
     AND name = in_name
$$;

CREATE OR REPLACE FUNCTION get_origin_integrations_for_origin_v1(in_origin text) RETURNS SETOF origin_integrations
    LANGUAGE sql STABLE
    AS $$
    SELECT * FROM origin_integrations
    WHERE origin = in_origin
    ORDER BY integration, name
$$;

CREATE OR REPLACE FUNCTION get_origin_integrations_v1(in_origin text, in_integration text) RETURNS SETOF origin_integrations
    LANGUAGE sql STABLE
    AS $$
  SELECT * FROM origin_integrations
  WHERE origin = in_origin AND integration = in_integration
$$;

CREATE OR REPLACE FUNCTION get_origin_invitation_v1(oi_invitation_id bigint) RETURNS SETOF origin_invitations
    LANGUAGE sql
    AS $$
    SELECT * FROM origin_invitations
    WHERE id = oi_invitation_id;
$$;

CREATE OR REPLACE FUNCTION get_origin_invitations_for_account_v1(oi_account_id bigint) RETURNS SETOF origin_invitations
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT * FROM origin_invitations WHERE account_id = oi_account_id AND ignored = false
        ORDER BY origin_name ASC;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_invitations_for_origin_v1(oi_origin_id bigint) RETURNS SETOF origin_invitations
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT * FROM origin_invitations WHERE origin_id = oi_origin_id
        ORDER BY account_name ASC;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_package_channels_for_package_v4(op_ident text, op_visibilities text) RETURNS SETOF origin_channels
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT oc.*
          FROM origin_channels oc INNER JOIN origin_channel_packages ocp ON oc.id = ocp.channel_id
          INNER JOIN origin_packages op ON op.id = ocp.package_id
          WHERE op.ident = op_ident
          AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
          ORDER BY oc.name;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_package_latest_v5(op_ident text, op_target text, op_visibilities text) RETURNS SETOF origin_packages
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT *
      FROM origin_packages
      WHERE ident LIKE (op_ident  || '%')
      AND target = op_target
      AND visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','));
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_package_platforms_for_package_v4(op_ident text, op_visibilities text) RETURNS TABLE(target text)
    LANGUAGE sql STABLE
    AS $$
  SELECT DISTINCT target
  FROM origin_packages
  WHERE ident LIKE (op_ident || '%')
  AND visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
$$;

CREATE OR REPLACE FUNCTION get_origin_package_v4(op_ident text, op_visibilities text) RETURNS SETOF origin_packages
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT *
    FROM origin_packages
    WHERE ident = op_ident
    AND visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','));
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_package_versions_for_origin_v7(op_origin text, op_pkg text, op_visibilities text) RETURNS TABLE(version text, release_count bigint, latest text, platforms text)
    LANGUAGE sql STABLE
    AS $$
  WITH packages AS (
    SELECT *
    FROM origin_packages op INNER JOIN origins o ON o.id = op.origin_id
    WHERE o.name = op_origin
    AND op.name = op_pkg
    AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
  ), idents AS (
    SELECT regexp_split_to_array(ident, '/') as parts, target
    FROM packages
  )
  SELECT i.parts[3] AS version,
  COUNT(i.parts[4]) AS release_count,
  MAX(i.parts[4]) as latest,
  ARRAY_TO_STRING(ARRAY_AGG(DISTINCT i.target), ',')
  FROM idents i
  GROUP BY version
  ORDER BY version DESC
$$;

CREATE OR REPLACE FUNCTION get_origin_packages_for_origin_distinct_v4(op_ident text, op_limit bigint, op_offset bigint, op_visibilities text) RETURNS TABLE(total_count bigint, ident text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT COUNT(p.partial_ident[1] || '/' || p.partial_ident[2]) OVER () AS total_count, p.partial_ident[1] || '/' || p.partial_ident[2] AS ident
    FROM (SELECT regexp_split_to_array(op.ident, '/') as partial_ident
          FROM origin_packages op
          WHERE op.ident LIKE ('%' || op_ident || '%')
          AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
          ) AS p
    GROUP BY (p.partial_ident[1] || '/' || p.partial_ident[2])
    LIMIT op_limit
    OFFSET op_offset;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_packages_for_origin_v5(op_ident text, op_limit bigint, op_offset bigint, op_visibilities text) RETURNS TABLE(total_count bigint, ident text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT COUNT(*) OVER () AS total_count, op.ident
        FROM origin_packages op
        WHERE op.ident LIKE (op_ident  || '%')
        AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
        ORDER BY op.ident DESC
        LIMIT op_limit
        OFFSET op_offset;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_packages_unique_for_origin_v4(op_origin text, op_limit bigint, op_offset bigint, op_visibilities text) RETURNS TABLE(total_count bigint, name text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT COUNT(*) OVER () AS total_count, op.name
        FROM origins o INNER JOIN origin_packages op ON o.id = op.origin_id
        WHERE o.name = op_origin
        AND op.visibility = ANY(STRING_TO_ARRAY(op_visibilities, ','))
        GROUP BY op.name
        ORDER BY op.name ASC
        LIMIT op_limit
        OFFSET op_offset;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_private_encryption_key_v1(opek_name text) RETURNS SETOF origin_private_encryption_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_private_encryption_keys WHERE name = opek_name
      ORDER BY full_name DESC
      LIMIT 1;
    RETURN;
  END
  $$;

CREATE OR REPLACE FUNCTION get_origin_project_integrations_for_project_v2(in_origin text, in_name text) RETURNS SETOF origin_project_integrations
    LANGUAGE sql STABLE
    AS $$
    SELECT opi.* FROM origin_project_integrations opi
    JOIN origin_projects op ON op.id = opi.project_id
    WHERE origin = in_origin
    AND package_name = in_name
$$;

CREATE OR REPLACE FUNCTION get_origin_project_integrations_v2(in_origin text, in_name text, in_integration text) RETURNS SETOF origin_project_integrations
    LANGUAGE sql STABLE
    AS $$
  SELECT opi.* FROM origin_project_integrations opi
  JOIN origin_integrations oi ON oi.id = opi.integration_id
  JOIN origin_projects op ON op.id = opi.project_id
  WHERE opi.origin = in_origin
  AND op.package_name = in_name
  AND oi.name = in_integration
$$;

CREATE OR REPLACE FUNCTION get_origin_project_list_v2(in_origin text) RETURNS SETOF origin_projects
    LANGUAGE sql STABLE
    AS $$
    SELECT * FROM origin_projects
    WHERE origin_name = in_origin
    ORDER BY package_name;
$$;

CREATE OR REPLACE FUNCTION get_origin_project_v1(project_name text) RETURNS SETOF origin_projects
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_projects WHERE name = project_name;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_public_encryption_key_latest_v1(opek_name text) RETURNS SETOF origin_public_encryption_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_public_encryption_keys WHERE name = opek_name
      ORDER BY revision DESC
      LIMIT 1;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_public_encryption_key_v1(opek_name text, opek_revision text) RETURNS SETOF origin_public_encryption_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_public_encryption_keys WHERE name = opek_name and revision = opek_revision
      ORDER BY revision DESC
      LIMIT 1;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_public_encryption_keys_for_origin_v1(opek_origin_id bigint) RETURNS SETOF origin_public_encryption_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT * FROM origin_public_encryption_keys WHERE origin_id = opek_origin_id
        ORDER BY revision DESC;
      RETURN;
  END
$$;


CREATE OR REPLACE FUNCTION get_origin_public_key_latest_v1(opk_name text) RETURNS SETOF origin_public_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_public_keys WHERE name = opk_name
      ORDER BY revision DESC
      LIMIT 1;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_public_key_v1(opk_name text, opk_revision text) RETURNS SETOF origin_public_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_public_keys WHERE name = opk_name and revision = opk_revision
      ORDER BY revision DESC
      LIMIT 1;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_public_keys_for_origin_v1(opk_origin_id bigint) RETURNS SETOF origin_public_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT * FROM origin_public_keys WHERE origin_id = opk_origin_id
        ORDER BY revision DESC;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION get_origin_secret_key_v1(osk_name text) RETURNS SETOF origin_secret_keys
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT * FROM origin_secret_keys WHERE name = osk_name
      ORDER BY full_name DESC
      LIMIT 1;
    RETURN;
  END
  $$;

CREATE OR REPLACE FUNCTION get_origin_secret_v1(os_origin_id bigint, os_name text) RETURNS SETOF origin_secrets
    LANGUAGE sql STABLE
    AS $$
  SELECT *
  FROM origin_secrets
  WHERE name = os_name
  AND origin_id = os_origin_id
  LIMIT 1
$$;

CREATE OR REPLACE FUNCTION get_origin_secrets_for_origin_v1(os_origin_id bigint) RETURNS SETOF origin_secrets
    LANGUAGE sql STABLE
    AS $$
  SELECT *
  FROM origin_secrets
  WHERE origin_id = os_origin_id
$$;

CREATE OR REPLACE FUNCTION ignore_origin_invitation_v1(oi_invitation_id bigint, oi_account_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
    UPDATE origin_invitations
    SET ignored = true, updated_at = now()
    WHERE id = oi_invitation_id AND account_id = oi_account_id;
$$;

CREATE OR REPLACE FUNCTION insert_origin_channel_v1(occ_origin_id bigint, occ_owner_id bigint, occ_name text) RETURNS SETOF origin_channels
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY INSERT INTO origin_channels (origin_id, owner_id, name)
              VALUES (occ_origin_id, occ_owner_id, occ_name)
              RETURNING *;
        RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION insert_origin_integration_v1(in_origin text, in_integration text, in_name text, in_body text) RETURNS SETOF origin_integrations
    LANGUAGE sql
    AS $$
  INSERT INTO origin_integrations(origin, integration, name, body)
  VALUES (in_origin, in_integration, in_name, in_body)
  RETURNING *
$$;

CREATE OR REPLACE FUNCTION insert_origin_invitation_v1(oi_origin_id bigint, oi_origin_name text, oi_account_id bigint, oi_account_name text, oi_owner_id bigint) RETURNS SETOF origin_invitations
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF NOT EXISTS (SELECT true FROM origin_members WHERE origin_id = oi_origin_id AND account_id = oi_account_id) THEN
        RETURN QUERY INSERT INTO origin_invitations (origin_id, origin_name, account_id, account_name, owner_id)
              VALUES (oi_origin_id, oi_origin_name, oi_account_id, oi_account_name, oi_owner_id)
              ON CONFLICT DO NOTHING
              RETURNING *;
        RETURN;
      END IF;
    END
$$;

CREATE OR REPLACE FUNCTION insert_origin_member_v1(om_origin_id bigint, om_origin_name text, om_account_id bigint, om_account_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
  BEGIN
    INSERT INTO origin_members (origin_id, origin_name, account_id, account_name)
          VALUES (om_origin_id, om_origin_name, om_account_id, om_account_name);
  END
$$;

CREATE OR REPLACE FUNCTION insert_origin_package_v3(op_origin_id bigint, op_owner_id bigint, op_name text, op_ident text, op_checksum text, op_manifest text, op_config text, op_target text, op_deps text, op_tdeps text, op_exposes text, op_visibility text) RETURNS SETOF origin_packages
    LANGUAGE plpgsql
    AS $$
    DECLARE
      inserted_package origin_packages;
      channel_id bigint;
    BEGIN
        INSERT INTO origin_packages (origin_id, owner_id, name, ident, ident_array, checksum, manifest, config, target, deps, tdeps, exposes, visibility)
              VALUES (op_origin_id, op_owner_id, op_name, op_ident, regexp_split_to_array(op_ident, '/'), op_checksum, op_manifest, op_config, op_target, op_deps, op_tdeps, op_exposes, op_visibility)
              RETURNING * into inserted_package;

        SELECT id FROM origin_channels WHERE origin_id = op_origin_id AND name = 'unstable' INTO channel_id;
        PERFORM promote_origin_package_v1(channel_id, inserted_package.id);

        RETURN NEXT inserted_package;
        RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION insert_origin_private_encryption_key_v1(opek_origin_id bigint, opek_owner_id bigint, opek_name text, opek_revision text, opek_full_name text, opek_body bytea) RETURNS SETOF origin_private_encryption_keys
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RETURN QUERY INSERT INTO origin_private_encryption_keys (origin_id, owner_id, name, revision, full_name, body)
          VALUES (opek_origin_id, opek_owner_id, opek_name, opek_revision, opek_full_name, opek_body)
          RETURNING *;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION insert_origin_project_v5(project_origin_name text, project_package_name text, project_plan_path text, project_vcs_type text, project_vcs_data text, project_owner_id bigint, project_vcs_installation_id bigint, project_visibility text, project_auto_build boolean) RETURNS SETOF origin_projects
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN QUERY INSERT INTO origin_projects (origin_id,
                                  origin_name,
                                  package_name,
                                  name,
                                  plan_path,
                                  owner_id,
                                  vcs_type,
                                  vcs_data,
                                  vcs_installation_id,
                                  visibility,
                                  auto_build)
            VALUES (
                (SELECT id FROM origins where name = project_origin_name),
                project_origin_name,
                project_package_name,
                project_origin_name || '/' || project_package_name,
                project_plan_path,
                project_owner_id,
                project_vcs_type,
                project_vcs_data,
                project_vcs_installation_id,
                project_visibility,
                project_auto_build)
            RETURNING *;
        RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION insert_origin_public_encryption_key_v1(opek_origin_id bigint, opek_owner_id bigint, opek_name text, opek_revision text, opek_full_name text, opek_body bytea) RETURNS SETOF origin_public_encryption_keys
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN QUERY INSERT INTO origin_public_encryption_keys (origin_id, owner_id, name, revision, full_name, body)
          VALUES (opek_origin_id, opek_owner_id, opek_name, opek_revision, opek_full_name, opek_body)
          RETURNING *;
      RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION insert_origin_public_key_v1(opk_origin_id bigint, opk_owner_id bigint, opk_name text, opk_revision text, opk_full_name text, opk_body bytea) RETURNS SETOF origin_public_keys
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN QUERY INSERT INTO origin_public_keys (origin_id, owner_id, name, revision, full_name, body)
          VALUES (opk_origin_id, opk_owner_id, opk_name, opk_revision, opk_full_name, opk_body)
          RETURNING *;
      RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION insert_origin_secret_key_v1(osk_origin_id bigint, osk_owner_id bigint, osk_name text, osk_revision text, osk_full_name text, osk_body bytea) RETURNS SETOF origin_secret_keys
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RETURN QUERY INSERT INTO origin_secret_keys (origin_id, owner_id, name, revision, full_name, body)
          VALUES (osk_origin_id, osk_owner_id, osk_name, osk_revision, osk_full_name, osk_body)
          RETURNING *;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION insert_origin_secret_v1(os_origin_id bigint, os_name text, os_value text) RETURNS SETOF origin_secrets
    LANGUAGE sql
    AS $$
  INSERT INTO origin_secrets (origin_id, name, value)
  VALUES (os_origin_id, os_name, os_value)
  RETURNING *
$$;

CREATE OR REPLACE FUNCTION insert_origin_v2(origin_name text, origin_owner_id bigint, origin_owner_name text, origin_default_package_visibility text) RETURNS SETOF origins
    LANGUAGE plpgsql
    AS $$
  DECLARE
    inserted_origin origins;
  BEGIN
    INSERT INTO origins (name, owner_id, default_package_visibility)
          VALUES (origin_name, origin_owner_id, origin_default_package_visibility) RETURNING * into inserted_origin;
    PERFORM insert_origin_member_v1(inserted_origin.id, origin_name, origin_owner_id, origin_owner_name);
    PERFORM insert_origin_channel_v1(inserted_origin.id, origin_owner_id, 'unstable');
    PERFORM insert_origin_channel_v1(inserted_origin.id, origin_owner_id, 'stable');
    RETURN NEXT inserted_origin;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION list_origin_by_account_id_v1(o_account_id bigint) RETURNS TABLE(origin_name text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
    RETURN QUERY SELECT origin_members.origin_name FROM origin_members WHERE account_id = o_account_id
      ORDER BY origin_name ASC;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION list_origin_members_v1(om_origin_id bigint) RETURNS TABLE(account_name text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT origin_members.account_name FROM origin_members WHERE origin_id = om_origin_id
        ORDER BY account_name ASC;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION my_origins_v2(om_account_id bigint) RETURNS SETOF origins
    LANGUAGE sql STABLE
    AS $$
  SELECT o.*
  FROM origins o
  INNER JOIN origin_members om ON o.id = om.origin_id
  WHERE om.account_id = om_account_id
  ORDER BY o.name;
$$;

CREATE OR REPLACE FUNCTION promote_origin_package_group_v1(opp_channel_id bigint, opp_package_ids bigint[]) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO origin_channel_packages (channel_id, package_id)
    SELECT opp_channel_id, package_ids.id
    FROM unnest(opp_package_ids) AS package_ids(id)
    ON CONFLICT ON CONSTRAINT origin_channel_packages_pkey DO NOTHING;
$$;

CREATE OR REPLACE FUNCTION promote_origin_package_v1(opp_channel_id bigint, opp_package_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
      INSERT INTO origin_channel_packages (channel_id, package_id) VALUES (opp_channel_id, opp_package_id)
      ON CONFLICT ON CONSTRAINT origin_channel_packages_pkey DO NOTHING;
$$;

CREATE OR REPLACE FUNCTION rescind_origin_invitation_v1(oi_invitation_id bigint, oi_owner_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
    DELETE FROM origin_invitations
    WHERE id = oi_invitation_id
    AND owner_id = oi_owner_id
    AND ignored = false;
$$;

CREATE OR REPLACE FUNCTION search_all_origin_packages_dynamic_v7(op_query text, op_my_origins text) RETURNS TABLE(ident text)
    LANGUAGE sql STABLE
    AS $$
  SELECT p.partial_ident[1] || '/' || p.partial_ident[2] AS ident
  FROM (SELECT regexp_split_to_array(op.ident, '/') as partial_ident
    FROM origin_packages op
    WHERE op.ident LIKE ('%' || op_query || '%')
    AND (op.visibility = 'public'
      OR (op.visibility IN ('hidden', 'private') AND op.origin_id IN (SELECT id FROM origins WHERE name = ANY(STRING_TO_ARRAY(op_my_origins, ',')))))) AS p
  GROUP BY (p.partial_ident[1] || '/' || p.partial_ident[2]);
$$;

CREATE OR REPLACE FUNCTION search_all_origin_packages_v6(op_query text, op_my_origins text) RETURNS TABLE(ident text)
    LANGUAGE sql STABLE
    AS $$
  SELECT op.ident
  FROM origin_packages op
  WHERE op.ident LIKE ('%' || op_query || '%')
  AND (op.visibility = 'public'
    OR (op.visibility IN ('hidden', 'private') AND op.origin_id IN (SELECT id FROM origins WHERE name = ANY(STRING_TO_ARRAY(op_my_origins, ',')))))
  ORDER BY op.ident ASC;
$$;

CREATE OR REPLACE FUNCTION search_origin_packages_for_origin_distinct_v1(op_origin text, op_query text, op_limit bigint, op_offset bigint) RETURNS TABLE(total_count bigint, ident text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT COUNT(p.partial_ident[1] || '/' || p.partial_ident[2]) OVER () AS total_count, p.partial_ident[1] || '/' || p.partial_ident[2] AS ident
      FROM (SELECT regexp_split_to_array(op.ident, '/') as partial_ident FROM origins o INNER JOIN origin_packages op ON o.id = op.origin_id WHERE o.name = op_origin AND op.name LIKE ('%' || op_query || '%')) AS p
      GROUP BY (p.partial_ident[1] || '/' || p.partial_ident[2])
      LIMIT op_limit OFFSET op_offset;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION search_origin_packages_for_origin_v4(op_origin text, op_query text, op_limit bigint, op_offset bigint, op_my_origins text) RETURNS TABLE(total_count bigint, ident text)
    LANGUAGE plpgsql STABLE
    AS $$
  BEGIN
      RETURN QUERY SELECT COUNT(*) OVER () AS total_count, op.ident
        FROM origins o INNER JOIN origin_packages op ON o.id = op.origin_id
        WHERE o.name = op_origin
        AND op.name LIKE ('%' || op_query || '%')
        AND (op.visibility='public' OR (op.visibility IN ('hidden', 'private') AND o.name = ANY(STRING_TO_ARRAY(op_my_origins, ','))))
        ORDER BY op.ident ASC
        LIMIT op_limit
        OFFSET op_offset;
      RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION set_packages_sync_v1(in_package_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
  BEGIN
      UPDATE origin_packages SET scheduler_sync = true WHERE id = in_package_id;
  END
$$;

CREATE OR REPLACE FUNCTION sync_packages_v2() RETURNS TABLE(account_id bigint, package_id bigint, package_ident text, package_deps text, package_target text)
    LANGUAGE sql STABLE
    AS $$
  SELECT owner_id, id, ident, deps, target FROM origin_packages WHERE scheduler_sync = false;
$$;

CREATE OR REPLACE FUNCTION update_origin_package_v1(op_id bigint, op_owner_id bigint, op_name text, op_ident text, op_checksum text, op_manifest text, op_config text, op_target text, op_deps text, op_tdeps text, op_exposes text, op_visibility text) RETURNS void
    LANGUAGE sql
    AS $$
  UPDATE origin_packages SET
    owner_id = op_owner_id,
    name = op_name,
    ident = op_ident,
    checksum = op_checksum,
    manifest = op_manifest,
    config = op_config,
    target = op_target,
    deps = op_deps,
    tdeps = op_tdeps,
    exposes = op_exposes,
    visibility = op_visibility,
    scheduler_sync = false,
    updated_at = now()
    WHERE id = op_id;
$$;

CREATE OR REPLACE FUNCTION update_origin_project_v4(project_id bigint, project_origin_id bigint, project_package_name text, project_plan_path text, project_vcs_type text, project_vcs_data text, project_owner_id bigint, project_vcs_installation_id bigint, project_visibility text, project_auto_build boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
    BEGIN
      UPDATE origin_projects SET
          package_name = project_package_name,
          name = (SELECT name FROM origins WHERE id = project_origin_id) || '/' || project_package_name,
          plan_path = project_plan_path,
          vcs_type = project_vcs_type,
          vcs_data = project_vcs_data,
          owner_id = project_owner_id,
          updated_at = now(),
          vcs_installation_id = project_vcs_installation_id,
          visibility = project_visibility,
          auto_build = project_auto_build
          WHERE id = project_id;
    END
$$;

CREATE OR REPLACE FUNCTION update_origin_v1(origin_id bigint, op_default_package_visibility text) RETURNS void
    LANGUAGE sql
    AS $$
  UPDATE origins SET
    default_package_visibility = op_default_package_visibility,
    updated_at = now()
    WHERE id = origin_id;
$$;

CREATE OR REPLACE FUNCTION update_package_visibility_in_bulk_v1(op_visibility text, op_ids bigint[]) RETURNS void
    LANGUAGE sql
    AS $$
    UPDATE origin_packages
    SET visibility = op_visibility
    WHERE id IN (SELECT(unnest(op_ids)));
$$;

CREATE OR REPLACE FUNCTION upsert_origin_integration_v1(in_origin text, in_integration text, in_name text, in_body text) RETURNS SETOF origin_integrations
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RETURN QUERY
      INSERT INTO origin_integrations(origin, integration, name, body)
      VALUES (in_origin, in_integration, in_name, in_body)
      ON CONFLICT(origin, integration, name)
      DO UPDATE SET body = in_body RETURNING *;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION upsert_origin_project_integration_v3(in_origin text, in_name text, in_integration text, in_body text) RETURNS SETOF origin_project_integrations
    LANGUAGE plpgsql
    AS $$
  BEGIN
    -- We currently support running only one publish step per build job. This
    -- temporary fix ensures we store (and can retrieve) only one project integration.
    DELETE FROM origin_project_integrations
    WHERE origin = in_origin
    AND project_id = (SELECT id FROM origin_projects WHERE package_name = in_name AND origin_name = in_origin);

    RETURN QUERY INSERT INTO origin_project_integrations(
        origin,
        body,
        updated_at,
        project_id,
        integration_id)
        VALUES (
          in_origin,
          in_body,
          NOW(),
          (SELECT id FROM origin_projects WHERE package_name = in_name AND origin_name = in_origin),
          (SELECT id FROM origin_integrations WHERE origin = in_origin AND name = in_integration)
        )
        ON CONFLICT(project_id, integration_id)
        DO UPDATE SET body=in_body RETURNING *;
    RETURN;
  END
$$;

CREATE OR REPLACE FUNCTION validate_origin_invitation_v1(oi_invite_id bigint, oi_account_id bigint) RETURNS TABLE(is_valid boolean)
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RETURN QUERY SELECT true FROM origin_invitations WHERE id = oi_invite_id AND account_id = oi_account_id;
    RETURN;
  END
  $$;

CREATE OR REPLACE VIEW origins_with_private_encryption_key_full_name_v1 AS
 SELECT origins.id,
    origins.name,
    origins.owner_id,
    origin_private_encryption_keys.full_name AS private_key_name,
    origins.default_package_visibility
   FROM (origins
     LEFT JOIN origin_private_encryption_keys ON ((origins.id = origin_private_encryption_keys.origin_id)))
  ORDER BY origins.id, origin_private_encryption_keys.full_name DESC;

CREATE OR REPLACE VIEW origins_with_secret_key_full_name_v2 AS
 SELECT origins.id,
    origins.name,
    origins.owner_id,
    origin_secret_keys.full_name AS private_key_name,
    origins.default_package_visibility
   FROM (origins
     LEFT JOIN origin_secret_keys ON ((origins.id = origin_secret_keys.origin_id)))
  ORDER BY origins.id, origin_secret_keys.full_name DESC;

CREATE INDEX IF NOT EXISTS origin_packages_ident_array ON origin_packages(ident_array);

CREATE SEQUENCE IF NOT EXISTS accounts_id_seq; 
CREATE SEQUENCE IF NOT EXISTS account_tokens_id_seq;

CREATE TABLE IF NOT EXISTS accounts (
    id bigint DEFAULT next_id_v1('accounts_id_seq') PRIMARY KEY NOT NULL,
    name text UNIQUE,
    email text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS account_tokens (
    id bigint DEFAULT next_id_v1('account_tokens_id_seq') PRIMARY KEY NOT NULL,
    account_id bigint,
    token text UNIQUE,
    created_at timestamp with time zone DEFAULT now()
);

CREATE OR REPLACE FUNCTION get_account_by_id_v1(account_id bigint) RETURNS SETOF accounts
    LANGUAGE plpgsql STABLE
    AS $$
    BEGIN
      RETURN QUERY SELECT * FROM accounts WHERE id = account_id;
      RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION get_account_by_name_v1(account_name text) RETURNS SETOF accounts
    LANGUAGE plpgsql STABLE
    AS $$
    BEGIN
      RETURN QUERY SELECT * FROM accounts WHERE name = account_name;
      RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION get_account_token_with_id_v1(p_id bigint) RETURNS SETOF account_tokens
    LANGUAGE sql STABLE
    AS $$
    SELECT * FROM account_tokens WHERE id = p_id;
$$;

CREATE OR REPLACE FUNCTION get_account_tokens_v1(p_account_id bigint) RETURNS SETOF account_tokens
    LANGUAGE sql STABLE
    AS $$
    SELECT * FROM account_tokens WHERE account_id = p_account_id;
$$;

CREATE OR REPLACE FUNCTION insert_account_token_v1(p_account_id bigint, p_token text) RETURNS SETOF account_tokens
    LANGUAGE sql
    AS $$
    DELETE FROM account_tokens WHERE account_id = p_account_id;
    INSERT INTO account_tokens (account_id, token)
    VALUES (p_account_id, p_token)
    RETURNING *;
$$;

CREATE OR REPLACE FUNCTION revoke_account_token_v1(p_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
    DELETE FROM account_tokens WHERE id = p_id;
$$;

CREATE OR REPLACE FUNCTION select_or_insert_account_v1(account_name text, account_email text) RETURNS SETOF accounts
    LANGUAGE plpgsql
    AS $$
    DECLARE
      existing_account accounts%rowtype;
    BEGIN
      SELECT * INTO existing_account FROM accounts WHERE name = account_name LIMIT 1;
      IF FOUND THEN
          RETURN NEXT existing_account;
      ELSE
          RETURN QUERY INSERT INTO accounts (name, email) VALUES (account_name, account_email) ON CONFLICT DO NOTHING RETURNING *;
      END IF;
      RETURN;
    END
$$;

CREATE OR REPLACE FUNCTION update_account_v1(op_id bigint, op_email text) RETURNS void
    LANGUAGE sql
    AS $$
    UPDATE accounts SET email = op_email WHERE id = op_id;
$$;
