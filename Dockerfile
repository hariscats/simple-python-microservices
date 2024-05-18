# Use the official Python image from the buster variant
FROM --platform=linux/amd64 python:3.10-slim

# Install build dependencies and curl
RUN apt-get update && apt-get install -y gcc build-essential libpq-dev curl

# Set the working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY src src

# Expose the port that the application runs on
EXPOSE 5000

# HEALTHCHECK instruction to monitor the running container
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=5 \
            CMD curl -f http://localhost:5000/health || exit 1

# Use Gunicorn to serve the application in production
ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:5000", "src.app:app"]
