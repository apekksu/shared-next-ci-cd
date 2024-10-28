#!/bin/bash
set -e

APPLICATION_NAME="$1"
APPLICATION_PORT="$2"
S3_BUCKET_NAME="$3"

echo "Starting deployment for $APPLICATION_NAME on port $APPLICATION_PORT..."

cd /home/ubuntu

echo "Stopping any existing PM2 instance of $APPLICATION_NAME"
sudo -u ubuntu pm2 stop "$APPLICATION_NAME" || echo "No running instance to stop"
sudo -u ubuntu pm2 delete "$APPLICATION_NAME" || echo "No instance to delete"

echo "Clearing and creating application directory"
rm -rf "$APPLICATION_NAME"
mkdir "$APPLICATION_NAME"
cd "$APPLICATION_NAME"

echo "Downloading application package from S3"
aws s3 cp "s3://${S3_BUCKET_NAME}/${APPLICATION_NAME}/${APPLICATION_NAME}.zip" . || { echo "Failed to download from S3"; exit 1; }

echo "Unzipping application package"
unzip -o "${APPLICATION_NAME}.zip" || { echo "Failed to unzip application package"; exit 1; }

chown -R ubuntu:ubuntu "/home/ubuntu/${APPLICATION_NAME}"

echo "Starting Next.js application using PM2 on port ${APPLICATION_PORT}"
sudo -u ubuntu pm2 start "npm run start -- -p ${APPLICATION_PORT}" \
  --name "$APPLICATION_NAME" \
  --cwd "/home/ubuntu/${APPLICATION_NAME}" || { echo "Failed to start application with PM2"; exit 1; }

# test