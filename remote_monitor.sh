#!/bin/bash

#in this script we will connect to a remote host via SSH, run the hardware audit script there, and pull the report back to our local machine. This simulates a remote monitoring scenario.
# Configuration – override via environment or edit here
REMOTE_USER="${REMOTE_USER:-student}"
REMOTE_HOST="${REMOTE_HOST:-192.168.1.100}"
REMOTE_PORT="${REMOTE_PORT:-22}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/audit_key}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_SCRIPT_PATH="/tmp/hardware_audit.sh"
REMOTE_REPORT_DIR="/tmp/sys_audit"
LOCAL_REPORT_DIR="$HOME/sys_audit/remote"
LOG_FILE="$HOME/sys_audit/audit.log"

mkdir -p "$LOCAL_REPORT_DIR"


if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''; GREEN=''; CYAN=''; YELLOW=''; NC=''
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [REMOTE] $1" >> "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${CYAN}--------------------------------------${NC}"
    echo -e "${YELLOW}  $1${NC}"
    echo -e "${CYAN}--------------------------------------${NC}"
}

log_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; } # Success message  
log_err()  { echo -e "${RED}  ✗ $1${NC}"; } # Error message to stderr
log_info() { echo -e "${CYAN}  i $1${NC}"; }

check_prerequisites() { # Check if ssh and scp are available, and if the SSH key exists
    print_header "PRE-FLIGHT CHECKS" # Check if ssh and scp are available, and if the SSH key exists
    if ! command -v ssh &>/dev/null; then # Check if ssh is available
        log_err "ssh not found" # Check if ssh is available
        exit 1
    fi
    if [ ! -f "$SSH_KEY" ]; then # Check if the SSH key file exists
        log_err "SSH key not found: $SSH_KEY"
        log_info "Generate one with: ssh-keygen -t rsa -b 4096 -f $SSH_KEY -N ''"
        exit 1
    fi
    log_ok "Environment ready"
}

test_connection() { # Test SSH connection to the remote host
    print_header "SSH CONNECTION"
    ssh -i "$SSH_KEY" -p "$REMOTE_PORT" -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo ok" &>/dev/null
    if [ $? -ne 0 ]; then
        log_err "Connection failed"
        exit 1
    fi
    log_ok "Connected to $REMOTE_HOST"
    log "Connected"
}

deploy_script() { # Deploy the hardware audit script to the remote host
    print_header "DEPLOY SCRIPT"
    scp -i "$SSH_KEY" -P "$REMOTE_PORT" "$SCRIPT_DIR/hardware_audit.sh" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_PATH"
    if [ $? -ne 0 ]; then
        log_err "Copy failed"
        exit 1
    fi
    ssh -i "$SSH_KEY" -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "chmod +x $REMOTE_SCRIPT_PATH"
    log_ok "Script deployed"
    log "Script deployed"
}

run_remote_audit() { #
    print_header "RUN REMOTE AUDIT"
    TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
    REMOTE_OUTPUT="$REMOTE_REPORT_DIR/remote_$TIMESTAMP.txt"
    ssh -i "$SSH_KEY" -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_REPORT_DIR && bash $REMOTE_SCRIPT_PATH > $REMOTE_OUTPUT"
    if [ $? -ne 0 ]; then
        log_err "Remote execution failed"
        exit 1
    fi
    log_ok "Audit done"
    log "Audit executed"
    echo "$REMOTE_OUTPUT"
}

pull_report() {
    REMOTE_OUTPUT="$1"
    print_header "DOWNLOAD REPORT"
    LOCAL_FILE="$LOCAL_REPORT_DIR/report_$(date '+%Y-%m-%d_%H-%M-%S').txt"
    scp -i "$SSH_KEY" -P "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_OUTPUT" "$LOCAL_FILE"
    if [ $? -ne 0 ]; then
        log_err "Download failed"
        exit 1
    fi
    log_ok "Saved: $LOCAL_FILE"
    log "Report downloaded"
}

main() {
    print_header "REMOTE MONITOR"
    check_prerequisites
    test_connection
    deploy_script
    REMOTE_FILE=$(run_remote_audit)
    pull_report "$REMOTE_FILE"
    echo ""
    echo -e "${GREEN}[✓] Remote monitoring complete${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi