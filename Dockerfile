# Use the official Python image from the Alpine variant
FROM python:3.10-alpine

# Set the working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY src src

# Install curl for the HEALTHCHECK
RUN apk add --no-cache curl

# Expose the port that the application runs on
EXPOSE 5000

# HEALTHCHECK instruction to monitor the running container
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=5 \
            CMD curl -f http://localhost:5000/health || exit 1

# Use Gunicorn to serve the application in production
ENTRYPOINT ["gunicorn", "-b", "0.0.0.0:5000", "src.app:app"]
