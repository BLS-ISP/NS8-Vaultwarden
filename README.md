# ns8-vaultwarden

[Vaultwarden](https://github.com/dani-garcia/vaultwarden) (self-hosted Bitwarden-compatible password manager server) module for **NethServer 8 (NS8)**.

- **GitHub Repository:** [`https://github.com/BLS-ISP/NS8-Vaultwarden`](https://github.com/BLS-ISP/NS8-Vaultwarden)
- **Container Image:** `ghcr.io/bls-isp/vaultwarden`
- **NS8 Software Center Repository URL:** `https://raw.githubusercontent.com/BLS-ISP/NS8-Vaultwarden/repomd/`

---

## Features

- **Vaultwarden (`1.37.4`)** running in a rootless Podman pod behind the NS8 Traefik reverse proxy (including WebSocket support)
- **Let's Encrypt & HTTP-to-HTTPS redirect** configurable via the NS8 Web UI
- **Admin Panel (`/admin`) & Argon2id PHC hashing** (toggleable in the NS8 Web UI; plaintext admin passwords entered in the UI are automatically converted to an Argon2id PHC `ADMIN_TOKEN` via `/vaultwarden hash`)
- **Registration & Security Policies** (`SIGNUPS_ALLOWED`, `SIGNUPS_VERIFY`, `SIGNUPS_DOMAINS_WHITELIST`, `INVITATIONS_ALLOWED`, `SENDS_ALLOWED`, `EMERGENCY_ACCESS_ALLOWED`, `ORG_EVENTS_ENABLED`, `SHOW_PASSWORD_HINT`) directly manageable from the NS8 Web UI
- **NS8 Smarthost / SMTP integration** (automatic discovery from Redis and reload on `smarthost-changed` events, with optional custom `SMTP_FROM` sender address)
- **NS8 LDAP / Active Directory user invitation sync** (optional `vividboarder/vaultwarden_ldap:2.2.1` sidecar container connected via `Ldapproxy` that automatically invites domain users with an email address to Vaultwarden, including `user-domain-changed` event support)
- **Mobile Push Notifications** (configurable Bitwarden Push Relay `PUSH_INSTALLATION_ID`, `PUSH_INSTALLATION_KEY`, and `PUSH_RELAY_URI`)
- **Consistent Online SQLite Backup, Restore & Clone/Move** (`module-dump-state` runs `/vaultwarden backup` using SQLite `VACUUM INTO` prior to restic snapshots, and `restore-module` promotes the clean snapshot on restore)

---

## Install via NethServer 8 Software Center UI (Recommended)

1. Open the **NethServer 8 Cluster Admin UI**.
2. Go to **Software center → Settings → Software repositories → Add repository**.
3. Enter the following details:
   - **Name:** `bls-isp-vaultwarden`
   - **URL:** `https://raw.githubusercontent.com/BLS-ISP/NS8-Vaultwarden/repomd/`
   - **Status:** Enabled
4. Open **Software center**, find **Vaultwarden**, and click **Install**.
5. Future module updates published with a newer Semantic Version tag (e.g. `1.0.1`, `1.1.0`) will automatically appear in the **Software center → Updates** view.

> **Tip:** To clear the 1-hour repository metadata cache on NS8 and immediately see a newly published release:
> ```bash
> redis-cli del cluster/repository_cache/bls-isp-vaultwarden
> ```

---

## Install via CLI

Instantiate the module using a **Semantic Version tag** (do not use `:latest` in production, as NS8 skips UI updates for `:latest` development instances):

```bash
add-module ghcr.io/bls-isp/vaultwarden:1.0.0 1
```

The output of the command will return the instance name:

```json
{"module_id": "vaultwarden1", "image_name": "vaultwarden", "image_url": "ghcr.io/bls-isp/vaultwarden:1.0.0"}
```

---

## Configure

Assuming the instance is named `vaultwarden1`, you can configure it directly in the **NethServer 8 Web UI** (**Settings → vaultwarden1**) or via CLI using `configure-module`:

- `host`: Fully qualified domain name for the Vaultwarden web vault (e.g. `vault.example.org`)
- `http2https`: Redirect HTTP requests to HTTPS (`true` / `false`)
- `lets_encrypt`: Request a valid Let's Encrypt certificate (`true` / `false`)
- `admin_enabled`: Enable the `/admin` management portal (`true` / `false`)
- `admin_password`: Password for the `/admin` portal (optional, minimum 8 characters; automatically hashed with Argon2id PHC)
- `signups_allowed`: Allow open user registration (`true` / `false`)
- `signups_verify`: Require email verification on registration (`true` / `false`)
- `signups_domains_whitelist`: Comma-separated list of email domains allowed to self-register (`e.g. company.de,example.org`)
- `invitations_allowed`: Allow organization admins to invite users (`true` / `false`)
- `ldap_domain`: NS8 LDAP / Active Directory domain for automatic user invitations (optional)
- `ldap_sync_interval`: Interval in seconds between LDAP sync runs (default `3600`, minimum `60`)
- `ldap_search_filter`: Custom LDAP user search filter (optional; auto-detected for AD vs. RFC2307 when empty)
- `sends_allowed`: Enable Bitwarden Send (`true` / `false`)
- `emergency_access_allowed`: Enable Emergency Access (`true` / `false`)
- `org_events_enabled`: Enable organization audit event logging (`true` / `false`)
- `show_password_hint`: Allow displaying password hints on the web page (`true` / `false`)
- `smtp_from`: Custom SMTP sender address (optional; defaults to `vaultwarden@<host>`)
- `push_enabled`: Enable mobile push notifications (`true` / `false`)
- `push_installation_id`: Bitwarden Push Installation ID from `https://bitwarden.com/host`
- `push_installation_key`: Bitwarden Push Installation Key from `https://bitwarden.com/host`
- `push_relay_uri`: Bitwarden Push Relay URI (default `https://push.bitwarden.com`)

Example CLI invocation:

```bash
api-cli run module/vaultwarden1/configure-module --data '{
  "host": "vault.example.org",
  "http2https": true,
  "lets_encrypt": true,
  "admin_enabled": true,
  "admin_password": "MyStrongAdminPassword123!",
  "signups_allowed": false,
  "signups_verify": true,
  "signups_domains_whitelist": "example.org",
  "invitations_allowed": true,
  "ldap_domain": "",
  "ldap_sync_interval": 3600,
  "ldap_search_filter": "",
  "sends_allowed": true,
  "emergency_access_allowed": true,
  "org_events_enabled": false,
  "show_password_hint": false,
  "smtp_from": "",
  "push_enabled": false,
  "push_installation_id": "",
  "push_installation_key": "",
  "push_relay_uri": "https://push.bitwarden.com"
}'
```

---

## Architecture, Volumes & Environment Variables (Developer / Support Reference)

### Systemd User Units (`imageroot/systemd/user/`)

- `vaultwarden.service`: Manages the rootless Podman pod (`vaultwarden`) with port mapping `127.0.0.1:${TCP_PORT}:80` and `--network=slirp4netns:allow_host_loopback=true`.
- `vaultwarden-app.service`: Runs the `docker.io/vaultwarden/server:1.37.4` container inside the pod. Executes `../bin/write-config` prior to startup to render `state/vaultwarden.env` (and synchronize `/data/config.json` if present).
- `vaultwarden-ldap.service`: Optional container (`docker.io/vividboarder/vaultwarden_ldap:2.2.1`) inside the pod that queries the bound NS8 `Ldapproxy` domain and automatically sends Vaultwarden invitations to discovered LDAP/AD users.

### Persistent Volumes (`imageroot/etc/state-include.conf`)

| Volume / Path | Container Mountpoint | Description | Included in Backup |
|---|---|---|---|
| `vaultwarden-data` | `/data` | SQLite database (`db.sqlite3`), RSA keys, attachments, sends, icon cache | Yes |
| `state/vaultwarden.env` | — | Generated Vaultwarden runtime environment file | Yes |
| `state/environment` | — | Module instance environment variables | Yes |

---

## Update Module via CLI

Updates are normally applied through the **NethServer 8 Software Center UI**. To manually update via CLI:

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/bls-isp/vaultwarden:1.0.1","instances":["vaultwarden1"]}'
```

---

## Publishing a New Release (Semantic Versioning)

In accordance with NethServer 8 standards, releases must use pure **Semantic Versioning (`X.Y.Z`) without a `v` prefix** (e.g. `1.0.0`, `1.0.1`, or `1.0.2-testing.1` for pre-releases):

```bash
git tag -a 1.0.0 -m "Release 1.0.0"
git push origin main --tags
```

The GitHub Actions workflow (`.github/workflows/publish-images.yml`) automatically builds and publishes `ghcr.io/bls-isp/vaultwarden:1.0.0` and updates `repodata.json` on the `repomd` branch.

---

## Uninstall

To uninstall the instance and remove its data:

```bash
remove-module --no-preserve vaultwarden1
```

---

## Testing

Test the module using the `test-module.sh` script:

```bash
./test-module.sh <NODE_ADDR> ghcr.io/bls-isp/vaultwarden:1.0.0
```
