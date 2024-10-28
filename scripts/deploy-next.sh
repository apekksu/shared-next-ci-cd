#!/bin/bash
set -e

APPLICATION_NAME="$1"
APPLICATION_PORT="$2"

cd /home/ubuntu


sudo -u ubuntu pm2 stop "$APPLICATION_NAME" || echo "No running instance to stop"
sudo -u ubuntu pm2 delete "$APPLICATION_NAME" || echo "No instance to delete"

rm -rf "$APPLICATION_NAME"
mkdir "$APPLICATION_NAME"
cd "$APPLICATION_NAME"

echo "Downloading application package from S3"
aws s3 cp "s3://${S3_BUCKET_NAME}/${APPLICATION_NAME}/${APPLICATION_NAME}.zip" . || exit 1

echo "Unzipping application package"
unzip -o "${APPLICATION_NAME}.zip" || exit 1

chown -R ubuntu:ubuntu "/home/ubuntu/${APPLICATION_NAME}"

echo "Starting Next.js application using PM2 on port ${APPLICATION_PORT}"
sudo -u ubuntu pm2 start "npm run start -- -p ${APPLICATION_PORT}" \
  --name "$APPLICATION_NAME" \
  --cwd "/home/ubuntu/${APPLICATION_NAME}" || exit 1
