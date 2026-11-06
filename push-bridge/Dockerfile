FROM python:3.11-slim

WORKDIR /app

# Create unprivileged group and user
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -m -s /bin/sh appuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Prepare data directory with appropriate ownership
RUN mkdir -p /app/data && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
