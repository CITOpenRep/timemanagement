# ubtms Push Bridge

Stateless bridge translating Odoo RFC 8188 WebPush notifications to the UBports Push Server (`https://push.ubports.com/notify`).

## Running Locally

```bash
cd push-bridge
pip install -r requirements.txt
uvicorn app:app --port 8000
```

## Running with Docker

```bash
docker build -t ubtms-push-bridge .
docker run -p 8000:8000 -e BRIDGE_PUBLIC_URL=https://your-domain.com ubtms-push-bridge
```

## Environment Variables

* `BRIDGE_PUBLIC_URL`: Public base URL of this bridge (e.g. `https://push.example.com`).
* `UBPORTS_PUSH_URL`: UBports push endpoint (default: `https://push.ubports.com/notify`).
* `UBPORTS_APP_ID`: Application ID in Ubuntu Touch (default: `ubtms_ubtms`).
* `BRIDGE_DB_PATH`: SQLite database path for local subscription keys (default: `subscriptions.db`).
