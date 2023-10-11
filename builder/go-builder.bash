#!/bin/bash

set -e

echo "Watching services: $SERVICES"

# $1: the go-binary source file to figure out the hash of.
go_hash() {
    # The "go list" prints all the Go files that "$1" depends on.
    # Then we take the md5sum of them all.
    # Taken from Khan/webapp:deploy/deploy_go_service.py
    go_relpaths=`go list -deps -f '{{if .Module}}{{if .Module.Main}}{{$dir := .Dir}}{{range .GoFiles}}{{$dir}}/{{.}}{{"\n"}}{{end}}{{end}}{{end}}' "$1" \
        | LC_ALL=C sort \
        | sed "s,^$PWD/,,"`
    # Find all the non-Go files under these directories.
    toplevel_dirs=`echo "$go_relpaths" | cut -d/ -f1-2 | uniq`
    nongo_relpaths=`find $toplevel_dirs -type f -a ! -name '*.go' | LC_ALL=C sort`
    cat $go_relpaths $nongo_relpaths $1 | md5sum | tr -d " -"
}

# $1: binary-prefix (usually the service name, e.g. "users")
# $2: source-name (e.g. "services/users/cmd/serve/main.go")
maybe_build() {
    binhash=`go_hash "$2"`
    echo "[`date`] $1 $binhash"

    binfile="$BIN_DIR/$1.$binhash"
    latestfile="$BIN_DIR/$1.latest"
    if [ ! -f "$binfile" ]; then
        echo "[`date`] Building $binfile..."
        # we don't include git metadata in our binaries because it's not that useful for dev development
        # and it sometimes didn't work in our containers for some reason we never figured out
        # also avoiding overhead and failure on vcs shouldn't preclude the binary from compiling at all in dev
        go build -buildvcs=false -o "$binfile" -gcflags="all=-N -l" "./`dirname $2`" && \
            echo "$binhash" > "$latestfile" && \
            echo "[`date`] Built $binfile successfully." || true
    elif [ ! -f "$latestfile" -o "`cat $latestfile`" != "$binhash" ]; then
        echo "$binhash" > "$latestfile"
    fi
}


LOOP=
if [ "$1" = "--loop" ]; then LOOP=1; shift; fi


BIN_DIR="/var/go-binaries"
mkdir -p $BIN_DIR || true
rm -rf $BIN_DIR/*.latest

cd /workspace
go mod download

IFS=' ' read -ra SPLIT_SERVICES <<< "$SERVICES"
while true; do
    for service in "${SPLIT_SERVICES[@]}"; do
        echo "Working on ${service}"
        maybe_build "$service" "services/$service/cmd/serve/main.go"
    done

    touch /tmp/gobinaries.uptodate

    if [ -z "$LOOP" ]; then
        break
    fi

    # Wait for any files that might affect any of our binaries to change,
    # and then loop around so we rebuild them.
    echo "[`date`] Waiting for file changes..."
    inotifywait -e modify -e move -e create -e delete -e attrib -r ./pkg ./services
    echo "[`date`] File changes found!"
done