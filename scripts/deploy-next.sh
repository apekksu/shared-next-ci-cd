#!/bin/bash
set -e

APPLICATION_NAME="$1"
APPLICATION_PORT="$2"
S3_BUCKET_NAME="$3"
SECRET_NAME="$4"
WORKSPACE="${5:-}"

echo "Cleaning up disk space..."
npm cache clean --force 2>/dev/null || true
rm -rf /var/lib/amazon/ssm/*/document/orchestration/* 2>/dev/null || true
sudo journalctl --vacuum-time=3d 2>/dev/null || true

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

if [ -n "$WORKSPACE" ]; then
  echo "Workspace mode ($WORKSPACE): node_modules ships in the artifact, skipping npm ci"
else
  echo "Installing dependencies"
  sudo -u ubuntu npm ci --omit=dev
fi

if [ -n "$WORKSPACE" ]; then
  ENV_FILE="apps/$WORKSPACE/.env"
else
  ENV_FILE=".env"
fi

echo "Fetching secrets from AWS Secrets Manager"
SECRET_VALUES=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query SecretString --output text)
echo "$SECRET_VALUES" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"' > "$ENV_FILE"
chmod 600 "$ENV_FILE"
chown ubuntu:ubuntu "$ENV_FILE"

unset NODE_OPTIONS

echo "Starting application using PM2"
if [ -n "$WORKSPACE" ]; then
  sudo -u ubuntu pm2 start npm --name "$APPLICATION_NAME" -- start --workspace="$WORKSPACE" -- -p "$APPLICATION_PORT"
else
  sudo -u ubuntu pm2 start npm --name "$APPLICATION_NAME" -- start -- -p "$APPLICATION_PORT"
fi
sudo -u ubuntu pm2 save