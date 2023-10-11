#!/bin/bash

set -e

echo "Building and Running $SERVICE_NAME"

cd /workspace

while true; do
    go run services/$SERVICE_NAME/cmd/serve/main.go &
    PID=$!
    echo "Service $SERVICE_NAME is pid $PID"

    # Wait for any files that might affect any of our binaries to change,
    # and then loop around so we rebuild them.
    echo "[`date`] Waiting for file changes..."
    inotifywait -e modify -e move -e create -e delete -e attrib -r ./pkg ./services/$SERVICE_NAME
    echo "[`date`] File changes found!"

    echo "Killing $SERVICE_NAME..."
    kill $PID
done