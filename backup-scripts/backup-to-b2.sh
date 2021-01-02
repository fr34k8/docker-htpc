#!/bin/bash
#
# Example usage from docker:
#
#    docker run \
#      --rm \
#      -v /etc/backup-scripts/rclone.conf:/config/rclone.conf:ro \
#      -v /files:/files:ro \
#      -e BUCKET=joeym-home-backups \
#      joemiller/backup-scripts:latest \
#      /backup-to-b2.sh \
#        /files/photos \
#        /files/online_backups

set -eou pipefail
# set -x

RCLONE_CONFIG="${RCLONE_CONFIG:-/config/rclone.conf}"
# /config/rclone.conf file should look like this: (insert account-id and api-key)
#    [b2]
#    type = b2
#    account = KEY_ID
#    key = KEY
#    endpoint =

SYNC_DIRS=() # pass in a list of dirs to sync as args to the script
BUCKET="${BUCKET:-}"
BWLIMIT="${BWLIMIT:-1.5m}"   # upload bandwidth limit, bytes

RCLONE_FLAGS=("--b2-hard-delete" "--config=$RCLONE_CONFIG")
RCLONE_FLAGS+=("--modify-window=1s" "--retries=10" "--transfers=32" "--checkers=48" "--bwlimit=${BWLIMIT}")
RCLONE_FLAGS+=("--stats-log-level=NOTICE" "--stats=30m")
RCLONE_FLAGS+=("--links")
RCLONE_FLAGS+=("--exclude=.gphotos.token")
# uncomment for interactive runs:
# RCLONE_FLAGS+=("--progress" "--stats=5s")
# uncomment for dry-run
# RCLONE_FLAGS+=("-n")

sync() {
    local errors=0
    local dir

    for dir in "${SYNC_DIRS[@]}"; do
        echo "==> sync: $dir"
        #
        # rclone sync --flags /src b2:bucket/src
        #
        if ! rclone sync "${RCLONE_FLAGS[@]}" "$dir" "b2:${BUCKET}$dir"; then
            errors=$((errors + 1))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        echo "==> sync: $dir: There were $errors errors.";
        exit 1
    fi
}

cleanup() {
    local errors=0
    local dir

    for dir in "${SYNC_DIRS[@]}"; do
        echo "==> cleanup: $dir"
        #
        # rclone cleanup --flags b2:bucket/src
        #
        if ! rclone cleanup "${RCLONE_FLAGS[@]}" "b2:${BUCKET}$dir"; then
            errors=$((errors + 1))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        echo "==> cleanup: $dir: There were $errors errors.";
        exit 1
    fi
}

main() {
    echo "==> Started $(date)"

    SYNC_DIRS=("$@")

    if [[ ${#SYNC_DIRS[@]} -eq 0 ]]; then
        echo "Usage: $0 /local/path1 [/local/path2, ...]"
        exit 1
    fi

    if [[ -z "$BUCKET" ]]; then
        echo "Missing env var 'BUCKET'"
        exit 1
    fi

    if [[ ! -e "$RCLONE_CONFIG" ]]; then
        echo "File not found: $RCLONE_CONFIG"
        exit 1
    fi

    sync
    cleanup
    echo "==> Finished $(date)"
}
main "$@"

