# ubtms Push Bridge

The push bridge translates Odoo RFC 8188 WebPush notifications to the UBports Push Server (`https://push.ubports.com/notify`).

The stack consists of:
- `push-bridge`: FastAPI service terminating WebPush encryption and forwarding notifications to UBports.
- `caddy`: Reverse proxy handling automated TLS certificate provisioning (Let's Encrypt / ZeroSSL), HTTP-to-HTTPS redirection, and security headers.

---

## Deployment Option A: Render.com (100% Free, Zero Card Required)

Render allows deploying web services directly from GitHub without entering a payment card.

### Deploy Steps
1. Push your repository to GitHub.
2. Sign up / Log in to [Render.com](https://render.com) using your GitHub account.
3. Click **New +** -> **Web Service**.
4. Connect your `timemanagement` repository.
5. Set:
   - **Name**: `ubtms-push-bridge`
   - **Language / Environment**: `Docker`
   - **Root Directory**: `push-bridge`
   - **Dockerfile Path**: `Dockerfile`
   - **Instance Type**: `Free`
6. Click **Deploy Web Service**.
7. Once deployed, Render provides a public HTTPS URL: `https://ubtms-push-bridge.onrender.com`.

### Keep Awake 24/7 Setup
To prevent Render from sleeping after 15 minutes of inactivity:
1. Create a free account at [UptimeRobot](https://uptimerobot.com).
2. Add a new monitor:
   - **Type**: HTTP(s)
   - **URL**: `https://<your-render-subdomain>.onrender.com/health`
   - **Interval**: `10 minutes`
3. Save monitor. This keeps the push bridge and legacy background poller running 24/7 within Render's free 750 hours/month allowance.

---

## Deployment Option B: Fly.io (Zero DNS, Built-in HTTPS)

If you do not own a custom domain, Fly.io provides an automated public HTTPS URL (e.g. `https://<app-name>.fly.dev`) and 3 GB free persistent volume storage for SQLite.

### 1-Command Fly.io Deployment
From the repository root:
```bash
cd push-bridge
./deploy_fly.sh
```

The script automatically:
1. Installs `flyctl` if not present.
2. Prompts to authenticate (`fly auth login`).
3. Sets up a unique app name.
4. Creates a 1 GB persistent volume `push_data` in Amsterdam (`ams`).
5. Configures `auto_stop_machines = "off"` to ensure continuous 24/7 background polling for legacy Odoo accounts.
6. Deploys the container stack and runs `./verify_deployment.sh https://<app-name>.fly.dev`.

---

## Deployment Option C: Oracle Cloud Infrastructure (OCI Always Free)

Follow these steps to deploy on an Always Free OCI compute instance.

### 1. Launch Compute Instance

1. Log in to the Oracle Cloud Console.
2. Navigate to **Compute** -> **Instances** -> **Create Instance**.
3. Choose instance settings:
   - **Image**: Canonical Ubuntu 22.04 LTS or 24.04 LTS.
   - **Shape**: `VM.Standard.A1.Flex` (ARM, up to 4 OCPUs and 24 GB RAM free) or `VM.Standard.E2.1.Micro` (AMD, 1 OCPU, 1 GB RAM).
   - **Networking**: Select your VCN and ensure **Assign a public IPv4 address** is enabled.
   - **SSH Keys**: Paste or upload your public SSH key.
4. Click **Create** and note down the assigned **Public IP Address**.

---

### 2. Configure OCI VCN Ingress Rules

By default, OCI cloud firewalls block inbound ports except SSH (port 22).

1. In the OCI Console, navigate to **Networking** -> **Virtual Cloud Networks**.
2. Click your VCN, then click **Security Lists** -> **Default Security List for <VCN>**.
3. Click **Add Ingress Rules** and create an entry:
   - **Source Type**: CIDR
   - **Source CIDR**: `0.0.0.0/0`
   - **IP Protocol**: TCP
   - **Source Port Range**: All
   - **Destination Port Range**: `80,443`
   - **Description**: Allow HTTP and HTTPS for Caddy and ACME validation.
4. Click **Add Ingress Rules**.

---

### 3. DNS Mapping

Create a DNS record with your domain registrar or DNS host:
- **Type**: `A`
- **Name**: `push` (or root `@`, e.g., `push.mydomain.com`)
- **IPv4 Address**: The public IP of your OCI instance.
- **TTL**: 300 (or default)

Verify DNS resolution before proceeding:
```bash
dig +short push.mydomain.com
```

---

### 4. Deploy with `deploy.sh`

1. Connect to the instance over SSH:
   ```bash
   ssh ubuntu@<INSTANCE_PUBLIC_IP>
   ```

2. Clone the repository and enter the `push-bridge` folder:
   ```bash
   git clone <REPO_URL>
   cd timemanagement/push-bridge
   ```

3. Run the deployment script passing your domain name:
   ```bash
   ./deploy.sh push.mydomain.com
   ```

The script automatically:
- Resolves the OCI Ubuntu iptables issue by adding accept rules for ports 80 and 443 before the default REJECT rule, then persists them with `netfilter-persistent`.
- Installs Docker and Docker Compose plugin if missing.
- Sets up the `./data` volume folder for persistent SQLite storage.
- Generates the `.env` configuration file.
- Builds and starts the containers in detached mode.
- Validates the service with a health check on `http://localhost/health`.

Once completed, your push bridge is live at `https://push.mydomain.com`.

### 5. Verification

Run the verification test suite to validate all endpoints and subscription generation:
```bash
./verify_deployment.sh https://push.mydomain.com
```

---

## Service Management

All container management uses standard Docker Compose commands from inside `push-bridge/`:

- **Check status**:
  ```bash
  docker compose ps
  ```

- **View logs**:
  ```bash
  docker compose logs -f
  ```

- **View push bridge logs only**:
  ```bash
  docker compose logs -f push-bridge
  ```

- **Restart services**:
  ```bash
  docker compose restart
  ```

- **Stop services**:
  ```bash
  docker compose down
  ```

---

## Local Development

To run locally without a domain for development or testing:

### Option A: Local Docker Compose

```bash
./deploy.sh localhost
```
Caddy will serve on `http://localhost`.

### Option B: Python Virtual Environment

```bash
cd push-bridge
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

---

## Environment Variables Reference

| Variable | Description | Default |
|---|---|---|
| `DOMAIN` | Domain name served by Caddy | `localhost` |
| `BRIDGE_PUBLIC_URL` | Public base URL clients use for subscription endpoints | `https://${DOMAIN}` |
| `BRIDGE_DB_PATH` | Path to persistent SQLite database | `/app/data/subscriptions.db` |
| `UBPORTS_PUSH_URL` | Upstream UBports push notification endpoint | `https://push.ubports.com/notify` |
| `UBPORTS_APP_ID` | Application identifier registered with Ubuntu Touch | `ubtms_ubtms` |
