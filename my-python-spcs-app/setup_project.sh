#!/bin/bash

# Create Python application
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        "message": "Hello from Snowpark Container Services!",
        "status": "running",
        "service": "my-python-app"
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.3
gunicorn==21.2.0
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
EOF

# Create service specification
cat > service_spec.yaml << 'EOF'
spec:
  containers:
  - name: my-python-app
    image: /spcs_db/spcs_schema/my_image_repo/my-python-app:latest
    env:
      PORT: 8080
    resources:
      requests:
        memory: 1Gi
        cpu: 0.5
      limits:
        memory: 1Gi
        cpu: 0.5
  endpoints:
  - name: app-endpoint
    port: 8080
    public: true
EOF

# Create snowflake.yml project definition
cat > snowflake.yml << 'EOF'
definition_version: 2
entities:
  my_python_service:
    type: service
    identifier: my_python_service
    stage: spcs_stage
    compute_pool: my_compute_pool
    spec_file: service_spec.yaml
    min_instances: 1
    max_instances: 1
    artifacts:
      - service_spec.yaml
      - Dockerfile
      - app.py
      - requirements.txt
EOF

echo "✅ All project files created successfully!"