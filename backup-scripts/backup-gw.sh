#!/bin/bash
#
# Usage
# -----
#
# - Backups: Run this script periodically. Weekly or Daily. It will backup the
#   BACKUP_HOST's root disk using the `dump` utility and store in a zbackup
#   repo at the $REPO path on the local node.
#
# - Cleanup: After each backup run a `find -mtime 180` is run against the $REPO/backups/
#   path to delete backups older than 180 days. A `zbackup gc` is then run to garbage collect
#   any removed blocks from the $REPO.
#
# - Restore: Use `zbackup restore` to pipe a backup from $REPO/backups/ into `restore`, similar
#   to gunzip -c'ing a gzip'd dump file, eg:
#
#      zbackup restore --password-file "$REPO_PASSWD_FILE" $REPO/backups/gw-2019-06-08.dump \
#          | restore -ivf -
#
# Example usage from docker:
#
#   docker run \
#      --rm \
#      -v /files/online_backups/zbackup-gw/:/data \
#      -v /etc/backup-scripts/backup-gw.zbackup.pass:/config/zbackup.pass:ro \
#      -v /etc/backup-scripts/gw-backup-ssh:/config/ssh.key:ro \
#      -e "BACKUP_HOST=firewall" \
#      -e "BACKUP_USER=backup" \
#      joemiller/backup-scripts:latest \
#      /backup-gw.sh
#

set -eou pipefail

REPO="${REPO:-/data}"
REPO_PASSWD_FILE="${REPO_PASSWD_FILE:-/config/zbackup.pass}"

BACKUP_HOST="${BACKUP_HOST:-}"
BACKUP_USER="${BACKUP_USER:-}"
BACKUP_SSH_KEY="${BACKUP_SSH_KEY:-/config/ssh.key}"

BACKUP_NAME="gw-$(date +%Y-%m-%d).dump"

init() {
    if [[ ! -e "$REPO/info" ]]; then
        echo "==> initializing new repo: $REPO"
        zbackup init --password-file "$REPO_PASSWD_FILE" "$REPO"
    fi
}

backup() {
    local ssh_args=("-oCompression=no" "-oStrictHostKeyChecking=no" "-c" "aes256-gcm@openssh.com")

    echo "==> Backing up $BACKUP_HOST to $REPO/backups/$BACKUP_NAME"

    ssh "${ssh_args[@]}" "$BACKUP_USER@$BACKUP_HOST" -i "$BACKUP_SSH_KEY" 'dump -0au -h0 -f - /' \
        | zbackup backup --password-file "$REPO_PASSWD_FILE" --cache-size 512mb "$REPO/backups/$BACKUP_NAME"
}

cleanup() {
    echo "==> Removing old backups"
    find "$REPO/backups/" -type f -mtime +180 -print -delete

    zbackup gc --password-file "$REPO_PASSWD_FILE" "$REPO"
}

main() {
    echo "==> Started $(date)"
    init
    du -shx "$REPO"
    backup
    cleanup
    du -shx "$REPO"
    echo "==> Finished $(date)"
}
main "$@"
