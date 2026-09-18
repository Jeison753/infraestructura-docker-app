FROM python:3.14-slim

WORKDIR /app

RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["python3", "-m", "http.server", "8000"]
