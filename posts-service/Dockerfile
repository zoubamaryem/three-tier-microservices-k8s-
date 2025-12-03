FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY posts_service.py .

EXPOSE 5002

HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import requests; requests.get('http://localhost:5002/health')" || exit 1

CMD ["python", "posts_service.py"]
