#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Get the directory of the current script
REPORT_DIR="$HOME/sys_audit" # Directory to store reports and logs
LOG_FILE="$REPORT_DIR/audit.log" # Log file for audit activities

RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m'

mkdir -p "$REPORT_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MAIN] $1" >> "$LOG_FILE" # Log function to write messages to the log file with timestamp and [MAIN] tag
}

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "============================================================"
    echo "        LINUX SYSTEM AUDIT & MONITORING SYSTEM"
    echo "============================================================"
    echo -e "  Host : ${YELLOW}$(hostname)"
    echo -e "  Date : ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  User : ${YELLOW}$(whoami)"
    echo -e "${NC}"
}

menu() {
    echo -e "${BOLD}${YELLOW} MAIN MENU${NC}"
    echo ""
    echo "1) Hardware Audit"
    echo "2) Software Audit"
    echo "3) Full Audit"
    echo "4) Generate Report"
    echo "5) Send Email"
    echo "6) Remote Monitor"
    echo "7) Bonus Features"
    echo "8) View Logs"
    echo "9) View README"
    echo "10) Exit"
    echo ""
    echo -ne "${CYAN}Choice: ${NC}"
}

while true; do
    print_banner
    menu
    read -r choice

    log "User selected option: $choice"

    case "$choice" in
        1)
            bash "$SCRIPT_DIR/hardware_audit.sh" # to call the hardware audit script
            ;;
        2)
            bash "$SCRIPT_DIR/software_audit.sh"
            ;;
        3)
            bash "$SCRIPT_DIR/hardware_audit.sh"
            bash "$SCRIPT_DIR/software_audit.sh"
            ;;
        4)
            echo "Select report type:"
            echo "1) Hardware"
            echo "2) Software"
            echo "3) Both"
            read -r rtype
            echo "Select mode:"
            echo "1) Short"
            echo "2) Full"
            read -r rmode
            case "$rtype" in
                1) TYPE="hardware" ;;
                2) TYPE="software" ;;
                3) TYPE="both" ;;
                *) echo "Invalid"; continue ;;
            esac
            case "$rmode" in
                1) MODE="short" ;;
                2) MODE="full" ;;
                *) echo "Invalid"; continue ;;
            esac
            bash "$SCRIPT_DIR/report_gen.sh" "$TYPE" "$MODE"
            ;;
        5)
            echo -n "Enter email address: "
            read -r email
            echo "Select report type:"
            echo "1) Hardware"
            echo "2) Software"
            echo "3) Both"
            read -r etype
            echo "Select mode:"
            echo "1) Short"
            echo "2) Full"
            read -r emode
            case "$etype" in
                1) TYPE="hardware" ;;
                2) TYPE="software" ;;
                3) TYPE="both" ;;
                *) echo "Invalid"; continue ;;
            esac
            case "$emode" in
                1) MODE="short" ;;
                2) MODE="full" ;;
                *) echo "Invalid"; continue ;;
            esac
            bash "$SCRIPT_DIR/email_send.sh" "$TYPE" "$MODE" "$email"
            ;;
        6)
            bash "$SCRIPT_DIR/remote_monitor.sh"
            ;;
        7)
            bash "$SCRIPT_DIR/bonus.sh"
            ;;
        8)
            tail -20 "$LOG_FILE" 2>/dev/null || echo "No logs yet"
            ;;
        9)
            if [ -f "$SCRIPT_DIR/README.md" ]; then
                less -R "$SCRIPT_DIR/README.md"
            else
                echo -e "${RED}README.md not found in $SCRIPT_DIR${NC}"
                echo "Press Enter to continue..."
                read -r
            fi
            ;;
        10)
            log "User exited"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
done