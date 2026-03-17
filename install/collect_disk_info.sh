#!/bin/bash

# DEPRECATED: This host-based disk info collector has been superseded by the
# disk-collector Docker sidecar. Run install/migrate-disk-collector.sh to migrate.
#
# Reads macOS disk and filesystem info using native tools (diskutil, df).
# Writes JSON to /tmp/nomad-disk-info.json for the admin container to read.

while true; do
    # Get disk layout using diskutil (macOS native)
    # Outputs one entry per physical disk found by diskutil
    DISK_LAYOUT_DEVICES="[]"
    if command -v diskutil &>/dev/null; then
        DISK_LAYOUT_DEVICES=$(diskutil list 2>/dev/null | grep -E '^/dev/disk[0-9]+' | awk '{print $1}' | while read -r disk; do
            info=$(diskutil info "$disk" 2>/dev/null)
            name=$(basename "$disk")
            size=$(echo "$info" | awk -F: '/Disk Size/{gsub(/ /,"",$2); print $2}' | grep -oE '[0-9]+' | head -1)
            model=$(echo "$info" | awk -F: '/Device \/ Media Name/{gsub(/^ +/,"",$2); print $2}')
            tran=$(echo "$info" | awk -F: '/Protocol/{gsub(/^ +/,"",$2); print $2}')
            echo "{\"name\":\"${name}\",\"size\":${size:-0},\"type\":\"disk\",\"model\":\"${model:-}\",\"tran\":\"${tran:-}\"}"
        done | paste -sd ',' -)
        DISK_LAYOUT_DEVICES="[${DISK_LAYOUT_DEVICES}]"
    fi

    DISK_LAYOUT="{\"blockdevices\":${DISK_LAYOUT_DEVICES}}"

    # Get filesystem usage using macOS df
    # -k: 1024-byte blocks, -P: POSIX output (stable column order)
    # Exclude devfs and other macOS virtual filesystems
    FS_SIZE=$(df -kP 2>/dev/null | tail -n +2 | grep -vE '^(devfs|map |auto_home|/private/var/vm)' | \
    awk 'BEGIN {ORS=""; print "["; first=1}
        {
            if (!first) print ","
            first=0
            gsub(/%/, "", $5)
            size = $2 * 1024
            used = $3 * 1024
            avail = $4 * 1024
            printf "{\"fs\":\"%s\",\"size\":%s,\"used\":%s,\"available\":%s,\"use\":%s,\"mount\":\"%s\"}",
                    $1, size, used, avail, $5, $6
        }
        END {print "]"}')

    cat > /tmp/nomad-disk-info.json << EOF
{
"diskLayout": $DISK_LAYOUT,
"fsSize": $FS_SIZE
}
EOF

    sleep 300
done
