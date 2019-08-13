#!/bin/bash
#
# Example usage from docker:
#
# docker run \
#    --rm \
#    -v /files/online_backups/restic:/data \
#    -v /home/joeym:/home/joeym:ro \
#    -v /etc/backup-scripts:/etc/backup-scripts:ro \
#    -v /virt/persistent:/virt/persistent:ro \
#    -v /etc/backup-scripts/restic-exclude.txt:/config/exclude:ro \
#    -e "HOST=server" \
#    -e "RESTIC_PASSWORD=password-here-foo" \
#    joemiller/backup-scripts:latest \
#    /backup-restic.sh \
#      /home/joe \
#      /etc/backup-scripts \
#      /virt/persistent
#

set -eou pipefail

# RESTIC=./restic-master
RESTIC=restic

HOST="${HOST:-$(hostname -s)}"
EXCLUDE_LIST="${EXCLUDE_LIST:-/config/exclude}"

RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-/data}"
export RESTIC_REPOSITORY


if [[ -z "${RESTIC_PASSWORD:-}" ]]; then
  echo 'Missing env var RESTIC_PASSWORD'
  exit 1
fi

init() {
    if [[ ! -e "$RESTIC_REPOSITORY/config" ]]; then
        echo "==> initializing new repo: $RESTIC_REPOSITORY"
        $RESTIC init
    fi
}

backup() {
    for i in "${DIRS[@]}"; do
        $RESTIC backup "$i" --exclude-file="$EXCLUDE_LIST" --host="$HOST" # --quiet
    done
}

cleanup() {
    # run pruner ever 3rd day
    if [[ $(( $(date +%e) % 3)) == 0 ]]; then
      restic forget --keep-last 4 --keep-daily 14 --keep-weekly 8 --keep-monthly 12
    fi

    # prune every 30th days-ish
    if [[ $(( $(date +%e) % 30)) == 0 ]]; then
      restic prune
    fi
}

check() {
    echo "TODO: run 'check' command periodically too..."
}

main() {
    echo "==> Started $(date)"

    DIRS=("$@")

    if [[ ${#DIRS[@]} -eq 0 ]]; then
        echo "Usage: $0 /local/path1 [/local/path2, ...]"
        exit 1
    fi

    init
    backup
    cleanup
    check
    echo "==> Finished $(date)"
}
main "$@"
