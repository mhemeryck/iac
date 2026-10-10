#!/bin/sh
set -eu

pid=
trap 'if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi; exit 0' TERM INT

fingerprint() {
    sha256sum /etc/frp/tls/tls.crt /etc/frp/tls/tls.key /etc/frp/auth/token
}

# frps reads certificates at startup. Restart after projected Secrets change.
while true; do
    previous=$(fingerprint)
    restart=false
    frps -c /etc/frp/config/frps.toml &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        sleep 10 &
        wait $! || true
        if [ "$(fingerprint)" != "$previous" ]; then
            restart=true
            kill "$pid" 2>/dev/null || true
            break
        fi
    done

    status=0
    wait "$pid" || status=$?
    pid=
    if [ "$restart" != true ]; then
        exit "$status"
    fi
done
