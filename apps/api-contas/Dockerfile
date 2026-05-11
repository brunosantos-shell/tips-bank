FROM cgr.dev/chainguard/python:latest-dev AS builder

USER root

ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/packages


WORKDIR /app

COPY requirements.txt .
COPY main.py .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --target=/packages -r requirements.txt

FROM cgr.dev/chainguard/python:latest

WORKDIR /app

COPY --from=builder /packages /packages
COPY --from=builder /app/main.py /app/main.py

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/packages \
    PATH="/venv/bin:$PATH"

EXPOSE 8080

ENTRYPOINT ["python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
