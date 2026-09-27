#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/var/backups/ufla-shop"
DB_NAME="loja"
KEEP=7
TIMESTAMP="$(date +%Y-%m-%d-%H%M)"
OUTPUT="$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql.gz"

mkdir -p "$BACKUP_DIR"

# Carrega DATABASE_URL do EnvironmentFile se nao estiver no ambiente
if [ -z "${DATABASE_URL:-}" ] && [ -f /etc/ufla-shop.env ]; then
    # shellcheck disable=SC1091
    set -a; source /etc/ufla-shop.env; set +a
fi

pg_dump "${DATABASE_URL:-postgresql://loja@localhost/loja}" | gzip > "$OUTPUT"

SIZE="$(du -sh "$OUTPUT" | cut -f1)"
logger -t backup "dump gerado: $OUTPUT ($SIZE)"

# Rotacao: manter apenas os $KEEP mais recentes
TOTAL="$(find "$BACKUP_DIR" -maxdepth 1 -name "$DB_NAME-*.sql.gz" | wc -l)"
if [ "$TOTAL" -gt "$KEEP" ]; then
    find "$BACKUP_DIR" -maxdepth 1 -name "$DB_NAME-*.sql.gz" \
        | sort | head -n "$(( TOTAL - KEEP ))" \
        | xargs rm -f
    logger -t backup "rotacao: mantidos $KEEP dumps, removidos $(( TOTAL - KEEP )) antigos"
fi
