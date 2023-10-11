#!/bin/bash

BIN_DIR="/var/go-binaries"

sigint_handler()
{
  kill $PID
  exit
}

trap sigint_handler SIGINT

# These should be in the dockerfile
apt-get update
apt-get install -y inotify-tools

while true; do
  VERSIONFILE="$BIN_DIR/$SERVICE_NAME.latest"
  if [ -e $VERSIONFILE ]
  then
    SERVICE_VERSION=`cat $VERSIONFILE`
    echo "Starting $SERVICE_NAME ($SERVICE_VERSION)..."
    $BIN_DIR/$SERVICE_NAME.$SERVICE_VERSION "$@" &
    PID=$!
    inotifywait -e modify -e move -e create -e delete -e attrib $VERSIONFILE
    echo "Killing $SERVICE_NAME..."
    kill $PID
  else
    echo "Service $SERVICE_NAME has not been built. Waiting..."
    sleep 5
  fi
done