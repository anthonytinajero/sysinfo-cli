#!/bin/bash

# System Information CLI for macOS
# Collect and display system information

# Basic system information
USER_NAME=$(whoami)
HOST=$(hostname -s)
OS=$(sw_vers -productName)
VERSION=$(sw_vers -productVersion)
KERNEL=$(uname -r)
SHELL_NAME=$(basename "$SHELL")

# CPU information
CPU=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)

# Apple Silicon CPU detection
if [ -z "$CPU" ]; then
    CPU=$(system_profiler SPHardwareDataType |
        awk -F ': ' '/Chip:/ {print $2; exit}')
fi

# RAM information
RAM_BYTES=$(sysctl -n hw.memsize)
RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
# Calculate memory usage
PAGE_SIZE=$(pagesize)

PAGES_ACTIVE=$(vm_stat | awk '/Pages active:/ {gsub(/\./, "", $3); print $3}')
PAGES_WIRED=$(vm_stat | awk '/Pages wired down:/ {gsub(/\./, "", $4); print $4}')
PAGES_COMPRESSED=$(vm_stat | awk '/Pages occupied by compressor:/ {gsub(/\./, "", $5); print $5}')

USED_BYTES=$(( (PAGES_ACTIVE + PAGES_WIRED + PAGES_COMPRESSED) * PAGE_SIZE ))

# Convert bytes to GB
USED_GB=$(awk -v bytes="$USED_BYTES" 'BEGIN {printf "%.1f", bytes/1073741824}')

# Calculate percentage
RAM_PERCENT=$((USED_BYTES * 100 / RAM_BYTES))

# Create memory progress bar
RAM_BAR=""

RAM_FILLED=$(((RAM_PERCENT * 20 + 99) / 100))
RAM_EMPTY=$((20 - RAM_FILLED))

for ((i=0; i<RAM_FILLED; i++)); do
    RAM_BAR+="█"
done

for ((i=0; i<RAM_EMPTY; i++)); do
    RAM_BAR+="░"
done

# Disk usage
DISK=$(df -h / | awk 'NR==2 {print $5}')

# Disk usage progress bar
DISK_PERCENT=${DISK%\%}

BAR_WIDTH=20
FILLED=$(((DISK_PERCENT * BAR_WIDTH + 99) / 100))
EMPTY=$((BAR_WIDTH - FILLED))

DISK_BAR=""

for ((i=0; i<FILLED; i++)); do
    DISK_BAR+="█"
done

for ((i=0; i<EMPTY; i++)); do
    DISK_BAR+="░"
done

# System uptime
UPTIME=$(uptime | sed -E 's/.* up (.*), [0-9]+ users?,.*/\1/')

# GPU information
GPU=$(system_profiler SPDisplaysDataType |
    awk -F ': ' '/Chipset Model:/ {print $2; exit}')

if [ -z "$GPU" ]; then
    GPU="Apple Integrated Graphics"
fi

# Terminal colors

BLUE=$'\033[38;2;173;216;230m'
WHITE=$'\033[38;2;255;255;255m'
GRAY=$'\033[38;2;130;130;130m'
RESET=$'\033[0m'

# Display system information beside ASCII art

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

{
    echo
    printf '%s%s@%s%s\n' "$CYAN" "$USER_NAME" "$HOST" "$RESET"
    echo "-----------------------------"
    printf '%sOS:%s %s %s\n' "$CYAN" "$RESET" "$OS" "$VERSION"
    echo "Host: $(sysctl -n hw.model)"
    echo "Kernel: $KERNEL"
    echo "Shell: $SHELL_NAME"
    echo "CPU: $CPU"
    echo "GPU: $GPU"
    echo "Uptime: $UPTIME"
    echo "Memory: [$RAM_BAR] $USED_GB / ${RAM_GB} GB"
    echo "Disk: [$DISK_BAR] $DISK"
    # Terminal color palette
    # Monochrome color palette
    echo ""

    printf '\033[48;2;38;38;38m    '
    printf '\033[48;2;64;64;64m    '
    printf '\033[48;2;89;89;89m    '
    printf '\033[48;2;115;115;115m    '
    printf '\033[48;2;140;140;140m    '
    printf '\033[48;2;166;166;166m    '
    printf '\033[48;2;217;217;217m    '
    printf '\033[48;2;255;255;255m    '
    printf '\033[0m\n'
} > "$SCRIPT_DIR/info.txt"

# Combine artwork and system information
paste "$SCRIPT_DIR/art.txt" "$SCRIPT_DIR/info.txt"
