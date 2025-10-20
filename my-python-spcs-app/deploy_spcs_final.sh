#!/bin/bash

echo "🚀 Starting SPCS deployment..."

# Set role and database context, create stage and image repo
snow sql -q "USE ROLE SPCS_ROLE; USE DATABASE SPCS_DB; USE SCHEMA SPCS_SCHEMA; CREATE STAGE IF NOT EXISTS spcs_stage; CREATE IMAGE REPOSITORY IF NOT EXISTS my_image_repo;" --role SPCS_ROLE --database SPCS_DB --schema SPCS_SCHEMA

# Get the image repository URL with better error handling
echo "📦 Getting image repository URL..."
REPO_OUTPUT=$(snow spcs image-repository url my_image_repo --role SPCS_ROLE --database SPCS_DB --schema SPCS_SCHEMA)
echo "Raw output: $REPO_OUTPUT"

# Extract the URL from the output
REPO_URL=$(echo "$REPO_OUTPUT" | grep -o '[a-zA-Z0-9-]*\.registry\.snowflakecomputing\.com[^[:space:]]*')

echo "Repository URL: $REPO_URL"

# Check if REPO_URL is empty
if [ -z "$REPO_URL" ]; then
    echo "❌ Failed to get repository URL. Exiting."
    exit 1
fi

# Build Docker image for AMD64 platform (required for SPCS)
echo "🔨 Building Docker image for AMD64 platform..."
docker build --platform linux/amd64 -t my-python-app .

# Tag for Snowflake registry
echo "🏷️ Tagging image for Snowflake registry..."
docker tag my-python-app $REPO_URL/my-python-app:latest

# Login to Snowflake registry
echo "🔐 Logging into Snowflake registry..."
snow spcs image-registry login --role SPCS_ROLE --database SPCS_DB --schema SPCS_SCHEMA

# Push image to registry
echo "⬆️ Pushing image to registry..."
docker push $REPO_URL/my-python-app:latest

# Deploy the service
echo "🚀 Deploying service..."
snow spcs service deploy my_python_service --role SPCS_ROLE --database SPCS_DB --schema SPCS_SCHEMA

# Check deployment status
echo "✅ Deployment complete!"
snow spcs service list --role SPCS_ROLE --database SPCS