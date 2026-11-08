
FROM python:3.12-slim-bookworm

# Install Java 17
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk-headless \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Configure Java
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

CMD ["python", "main.py"]
