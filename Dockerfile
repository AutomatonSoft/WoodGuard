FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY alembic.ini ./
COPY alembic ./alembic
COPY config ./config
COPY dependencies ./dependencies
COPY models ./models
COPY routers ./routers
COPY services ./services
COPY storage ./storage
COPY main.py ./main.py
COPY streamlit_app.py ./streamlit_app.py
COPY docker-entrypoint.sh ./docker-entrypoint.sh

RUN chmod +x ./docker-entrypoint.sh

EXPOSE 8000

CMD ["./docker-entrypoint.sh"]
