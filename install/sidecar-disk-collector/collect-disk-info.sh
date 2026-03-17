#!/bin/bash

# Project N.O.M.A.D. - Disk Info Collector Sidecar
#
# Reads block device and filesystem info from within the Linux container environment.
# No special capabilities required. Writes JSON to /storage/nomad-disk-info.json, which is read by the admin container.
# Runs continually and updates the JSON data every 2 minutes.
#
# NOTE (macOS): On macOS Docker Desktop, the /:/host:ro bind-mount exposes the Docker VM
# filesystem, not the macOS host filesystem. Disk info reflects the Docker VM's virtual disk.

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

log "disk-collector sidecar starting..."

# Write a valid placeholder immediately so admin has something to parse if the
# file is missing (first install, user deleted it, etc.). The real data from the
# first full collection cycle below will overwrite this within seconds.
if [[ ! -f /storage/nomad-disk-info.json ]]; then
    echo '{"diskLayout":{"blockdevices":[]},"fsSize":[]}' > /storage/nomad-disk-info.json
    log "Created initial placeholder — will be replaced after first collection."
fi

while true; do

    # Get disk layout (-b outputs SIZE in bytes as a number rather than a human-readable string)
    DISK_LAYOUT=$(lsblk --json -b -o NAME,SIZE,TYPE,MODEL,SERIAL,VENDOR,ROTA,TRAN 2>/dev/null)
    if [[ -z "$DISK_LAYOUT" ]]; then
        log "WARNING: lsblk failed, using empty block devices"
        DISK_LAYOUT='{"blockdevices":[]}'
    fi

    # Get filesystem usage by parsing /proc/mounts (the container's mount table)
    # On macOS Docker Desktop this reflects the Docker VM's filesystem view.
    FS_JSON="["
    FIRST=1
    while IFS=' ' read -r dev mountpoint fstype opts _rest; do
        # Disregard pseudo and virtual filesystems
        [[ "$fstype" =~ ^(tmpfs|devtmpfs|squashfs|sysfs|proc|devpts|cgroup|cgroup2|overlay|nsfs|autofs|hugetlbfs|mqueue|pstore|fusectl|binfmt_misc)$ ]] && continue
        [[ "$mountpoint" == "none" ]] && continue

        STATS=$(df -B1 "${mountpoint}" 2>/dev/null | awk 'NR==2{print $2,$3,$4,$5}')
        [[ -z "$STATS" ]] && continue

        read -r size used avail pct <<< "$STATS"
        pct="${pct/\%/}"

        [[ "$FIRST" -eq 0 ]] && FS_JSON+=","
        FS_JSON+="{\"fs\":\"${dev}\",\"size\":${size},\"used\":${used},\"available\":${avail},\"use\":${pct},\"mount\":\"${mountpoint}\"}"
        FIRST=0
    done < /proc/mounts
    FS_JSON+="]"

    # Use a tmp file for atomic update
    cat > /storage/nomad-disk-info.json.tmp << EOF
{
"diskLayout": ${DISK_LAYOUT},
"fsSize": ${FS_JSON}
}
EOF

    if mv /storage/nomad-disk-info.json.tmp /storage/nomad-disk-info.json; then
        log "Disk info updated successfully."
    else
        log "ERROR: Failed to move temp file to /storage/nomad-disk-info.json"
    fi

    sleep 120
done
