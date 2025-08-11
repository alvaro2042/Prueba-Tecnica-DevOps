#!/bin/bash
LOG_DIR="/var/log/myapp"
MAX_LOGS=5

mkdir -p "$LOG_DIR"

ls -t "$LOG_DIR"/*.log 2>/dev/null | tail -n +$((MAX_LOGS+1)) | while read file; do
    rm -f "$file"
done

echo "Log rotation completed at $(date)"
