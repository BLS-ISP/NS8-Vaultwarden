# ns8-vaultwarden

[Vaultwarden](https://github.com/dani-garcia/vaultwarden) (self-hosted Bitwarden-compatible password manager server) module for **NethServer 8 (NS8)**.

- **GitHub Repository:** [`https://github.com/BLS-ISP/NS8-Vaultwarden`](https://github.com/BLS-ISP/NS8-Vaultwarden)
- **Container Image:** `ghcr.io/bls-isp/vaultwarden`
- **NS8 Software Center Repository URL:** `https://raw.githubusercontent.com/BLS-ISP/NS8-Vaultwarden/repomd/`
- **License:** GPL-3.0-or-later

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
add-module ghcr.io/bls-isp/vaultwarden:1.0.1 1
```

The output of the command will return the instance name:

```json
{"module_id": "vaultwarden1", "image_name": "vaultwarden", "image_url": "ghcr.io/bls-isp/vaultwarden:1.0.1"}
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
- `vaultwarden-app.service`: Runs the `docker.io/vaultwarden/server:1.37.4` (`${SERVER_IMAGE}`) container inside the pod. Executes `../bin/write-config` prior to startup to render `state/vaultwarden.env` from the module environment and Redis smarthost settings.
- `vaultwarden-ldap.service`: Optional container (`docker.io/vividboarder/vaultwarden_ldap:2.2.1`, `${VAULTWARDEN_LDAP_IMAGE}`) inside the pod that queries the bound NS8 `Ldapproxy` domain (`10.0.2.2:<port>`) using `state/ldap_config.toml` and automatically sends Vaultwarden invitations to discovered LDAP/AD users via `http://127.0.0.1:80/admin/invite`.

### Persistent Volumes (`imageroot/etc/state-include.conf` & `org.nethserver.volumes`)

| Volume / Path | Container Mountpoint | Description | Included in Backup |
|---|---|---|---|
| `vaultwarden-data` | `/data` | SQLite database (`db.sqlite3`), RSA keypair, file attachments, Bitwarden Sends, icon cache | Yes (`volumes/vaultwarden-data`) |
| `state/vaultwarden.env` | — | Generated Vaultwarden runtime environment file (rendered by `write-config`) | Regenerated on restore/clone |
| `state/ldap_config.toml` | `/config.toml` (`ro`) | Generated `vaultwarden_ldap` configuration file (rendered by `write-config`) | Regenerated on restore/clone |
| `state/environment` | — | Module instance environment variables | Backed up via NS8 agent metadata |

### Environment Variables (`state/environment`)

| Variable | Description |
|---|---|
| `TCP_PORT` | Allocated local TCP port for Vaultwarden HTTP behind Traefik |
| `HOST` | Configured FQDN for the Vaultwarden web vault |
| `HTTP2HTTPS` | Whether Traefik redirects HTTP to HTTPS (`True` / `False`) |
| `LETS_ENCRYPT` | Whether Traefik requests a Let's Encrypt certificate (`True` / `False`) |
| `ADMIN_ENABLED` | Enables or disables the `/admin` portal (`True` / `False`) |
| `ADMIN_PASSWORD` | Configured admin secret (used to generate `ADMIN_TOKEN_HASH` and authenticate `vaultwarden_ldap`) |
| `ADMIN_TOKEN_HASH` | Cached Argon2id PHC string passed as `ADMIN_TOKEN` to Vaultwarden |
| `SIGNUPS_ALLOWED` | Allows open self-registration (`True` / `False`) |
| `SIGNUPS_VERIFY` | Requires email verification on signup (`True` / `False`) |
| `SIGNUPS_DOMAINS_WHITELIST` | Comma-separated list of email domains allowed to self-register |
| `INVITATIONS_ALLOWED` | Allows organization admins to invite users (`True` / `False`) |
| `SHOW_PASSWORD_HINT` | Displays password hints on the web page (`True` / `False`) |
| `SENDS_ALLOWED` | Enables Bitwarden Send (`True` / `False`) |
| `EMERGENCY_ACCESS_ALLOWED` | Enables Emergency Access (`True` / `False`) |
| `ORG_EVENTS_ENABLED` | Enables organization audit event logging (`True` / `False`) |
| `SMTP_FROM` | Optional custom SMTP sender email address |
| `LDAP_DOMAIN` | Optional NethServer 8 user domain name bound via `Ldapproxy` |
| `LDAP_SYNC_INTERVAL` | Interval in seconds between `vaultwarden_ldap` sync cycles |
| `LDAP_SEARCH_FILTER` | Optional custom LDAP user search filter |
| `PUSH_ENABLED` | Enables mobile push notifications via Bitwarden Push Relay (`True` / `False`) |
| `PUSH_INSTALLATION_ID` | Bitwarden Push Installation ID |
| `PUSH_INSTALLATION_KEY` | Bitwarden Push Installation Key |
| `PUSH_RELAY_URI` | Bitwarden Push Relay URI (defaults to `https://push.bitwarden.com`) |

### Maintenance, Backup/Restore & Customization Procedures

- **Online SQLite Backup (`imageroot/bin/module-dump-state`):** Before Restic snapshots `volumes/vaultwarden-data`, `module-dump-state` executes `podman exec vaultwarden-app /vaultwarden backup`, which creates an atomic `VACUUM INTO` snapshot (`/data/db_YYYYMMDD_HHMMSS.sqlite3`). After the backup finishes, `module-cleanup-state` removes the temporary snapshot files. Upon `restore-module`, `50configure` automatically promotes the newest `db_*.sqlite3` snapshot to `/data/db.sqlite3` and removes stale `-wal`/`-shm` files.
- **Interaction with `/data/config.json`:** If an administrator saves settings inside Vaultwarden's internal `/admin` portal, Vaultwarden writes `/data/config.json`. During `write-config`, keys managed by the NS8 UI are automatically stripped from `/data/config.json` so that NS8 UI settings in `state/vaultwarden.env` always remain authoritative, while preserving any other custom settings set in `/admin`.

---

## Data Privacy & Terms

- **Local Encrypted Storage:** All vault items, passwords, attachments, and Bitwarden Sends are encrypted client-side before transmission and stored locally on the NethServer 8 node inside the `vaultwarden-data` volume.
- **Optional Third-Party Connections:**
  - **Let's Encrypt:** When `lets_encrypt` is enabled, Traefik contacts Let's Encrypt ACME servers to issue and renew TLS certificates for the configured `host`.
  - **Bitwarden Push Relay (Optional, disabled by default):** When `push_enabled` is explicitly activated with an Installation ID and Key from `bitwarden.com/host`, Vaultwarden sends push notification wake-up signals (containing no vault data) to `https://push.bitwarden.com` so mobile apps sync immediately.
  - **Website Icons:** By default, Vaultwarden fetches website favicons directly for vault entries unless disabled via `/admin`.
- **Licensing:** This module and Vaultwarden are distributed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**.

---

## Limitations, Roadmap & Contact

- **LDAP Integration Behavior:** Because Bitwarden/Vaultwarden uses zero-knowledge client-side encryption derived from each user's master password, LDAP cannot authenticate master passwords directly. Instead, `vaultwarden_ldap` queries the selected NethServer 8 LDAP/AD user domain and automatically sends email invitations to domain users so they can initialize their encrypted vault.
- **Support & Contact:**
  - **Issue Tracker:** [`https://github.com/BLS-ISP/NS8-Vaultwarden/issues`](https://github.com/BLS-ISP/NS8-Vaultwarden/issues)
  - **Maintainer:** BLS-ISP (`info@bls-isp.de`)
  - **NethServer Community Forum:** [`https://community.nethserver.org/`](https://community.nethserver.org/)

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
git tag -a 1.0.1 -m "Release 1.0.1"
git push origin main --tags
```

The GitHub Actions workflow (`.github/workflows/publish-images.yml`) automatically builds and publishes `ghcr.io/bls-isp/vaultwarden:1.0.1` and updates `repodata.json` on the `repomd` branch.

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
./test-module.sh <NODE_ADDR> ghcr.io/bls-isp/vaultwarden:1.0.1
```
