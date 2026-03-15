#!/bin/sh
set -e

python - <<'PY'
import os
import time

from sqlalchemy import create_engine, text

database_url = os.environ.get("DATABASE_URL", "")
if database_url.startswith("sqlite"):
    raise SystemExit(0)

for attempt in range(60):
    try:
        engine = create_engine(database_url, pool_pre_ping=True)
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        break
    except Exception:
        if attempt == 59:
            raise
        time.sleep(2)
PY

alembic upgrade head
exec uvicorn main:app --host 0.0.0.0 --port 8000
