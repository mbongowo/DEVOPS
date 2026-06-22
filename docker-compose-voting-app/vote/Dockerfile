FROM python:3.12-slim

WORKDIR /app

# Install deps first so the layer caches across code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run as an unprivileged user.
RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:80/healthz').status==200 else 1)"

# 2 workers, threaded, bound to :80.
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "2", "--threads", "4", "app:app"]
