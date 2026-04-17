#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Get the directory of the current script
REPORT_DIR="$HOME/sys_audit/reports"
mkdir -p "$REPORT_DIR" # Ensure the reports directory exists

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S') # Generate a timestamp for the report filename

# Load functions from audit scripts (they won't run because of the guard)
source "$SCRIPT_DIR/hardware_audit.sh"
source "$SCRIPT_DIR/software_audit.sh"

# SHORT mode functions (subset of the full report for quick checks)
shorthard() {
    collect_cpu_info
    collect_ram_info
}

shortsoft() {
    collect_os_info
    collect_processes
}

# MAIN LOGIC TODO: could be more robust (e.g. use getopts for CLI args)
if [ $# -ge 2 ]; then
    TYPE_ARG="$1"
    MODE_ARG="$2"
    # Convert to internal numeric codes
    case "$TYPE_ARG" in
        hardware) TYPE=1 ;;
        software) TYPE=2 ;;
        both)     TYPE=3 ;;
        *) echo "Invalid type: $TYPE_ARG"; exit 1 ;;
    esac
    case "$MODE_ARG" in #MEAN: could be more robust (e.g. use getopts for CLI args)
        short) MODE=1 ;;
        full)  MODE=2 ;;        #1=SHORT, 2=FULL
        *) echo "Invalid mode: $MODE_ARG"; exit 1 ;;
    esac
else
    echo "Choose type:"
    echo "1) Hardware"
    echo "2) Software"
    echo "3) Both"
    echo -n "Choice: "
    read -r TYPE
    echo ""
    echo "Choose mode:"
    echo "1) Short"
    echo "2) Full"
    echo -n "Choice: "
    read -r MODE
fi


TYPE_NAME="" # For filename and logging
case $TYPE in
    1) TYPE_NAME="hardware" ;; 
    2) TYPE_NAME="software" ;;
    3) TYPE_NAME="both" ;;
esac
MODE_NAME=$([ "$MODE" = "1" ] && echo "short" || echo "full") # For filename and logging TODO: could be more robust
FILE="$REPORT_DIR/report_${TYPE_NAME}_${MODE_NAME}_$TIMESTAMP.txt"


{
    echo "===== SYSTEM REPORT ====="
    echo "Host: $(hostname)"
    echo "Date: $(date)"
    echo ""

    if [ "$MODE" = "1" ]; then
        # SHORT mode
        case $TYPE in
            1) shorthard ;;
            2) shortsoft ;;
            3) shorthard; shortsoft ;;
            *) echo "Invalid choice" ;;
        esac
    elif [ "$MODE" = "2" ]; then
        # FULL mode – run the original scripts (output captured here)
        case $TYPE in
            1) bash "$SCRIPT_DIR/hardware_audit.sh" ;;
            2) bash "$SCRIPT_DIR/software_audit.sh" ;;
            3) bash "$SCRIPT_DIR/hardware_audit.sh"; bash "$SCRIPT_DIR/software_audit.sh" ;;
            *) echo "Invalid choice" ;;
        esac
    else
        echo "Invalid mode"
    fi
} > "$FILE" # MEAN: Capture all output to the report file

echo "Saved: $FILE"