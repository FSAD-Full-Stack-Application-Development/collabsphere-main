#!/bin/bash
set -e  # exit on any error

PROJECT_ROOT="/Users/saugatshakya/Projects/FSAD2025/collabsphere"
FLUTTER_DIR="$PROJECT_ROOT/flutter"
DOCKER_DIR="$PROJECT_ROOT/docker"

echo "Cleaning old docker/web folder..."
rm -rf "$DOCKER_DIR/web"

echo "Building Flutter web app with base-href /app/ ..."
cd "$FLUTTER_DIR"
flutter build web --release --base-href /app/

echo "Copying build output to docker/web ..."
mkdir -p "$DOCKER_DIR/web"
cp -r build/web/* "$DOCKER_DIR/web/"

echo "Building Docker image..."
cd "$DOCKER_DIR"
docker buildx build --platform linux/amd64 -t sak3e/flutter-web-app --push .

echo "Done! Docker image pushed."
