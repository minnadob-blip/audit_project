#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW="\e[1;35m"
NC='\033[0m'

REPORT_DIR="$HOME/sys_audit"
LOG_FILE="$REPORT_DIR/audit.log"
mkdir -p "$REPORT_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SOFTWARE] $1" >> "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${CYAN}--------------------------------------------${NC}"
    echo -e "${YELLOW}  $1${NC}"
    echo -e "${CYAN}--------------------------------------------${NC}"
}

print_field() {
    echo -e "${GREEN}  $1 : ${NC} $2"
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${RED}  [WARNING] Command '$1' not found. Skipping.${NC}"
        return 1
    fi
    return 0
}

collect_os_info() {
    print_header "OPERATING SYSTEM INFORMATION"

    if [ -f /etc/os-release ]; then
        print_field "OS Name" "$(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '\"')"
        print_field "OS ID" "$(grep '^ID=' /etc/os-release | cut -d= -f2)"
        print_field "Version" "$(grep '^VERSION=' /etc/os-release | cut -d= -f2 | tr -d '\"')"
    fi

    print_field "Kernel Version" "$(uname -r)"
    print_field "Architecture" "$(uname -m)"
    print_field "Hostname" "$(hostname)"
    print_field "System Uptime" "$(uptime -p)"
    print_field "Current Date/Time" "$(date '+%Y-%m-%d %H:%M:%S')"
    print_field "Kernel Build" "$(cat /proc/version 2>/dev/null | cut -d' ' -f1-5)"
}

collect_packages_info() {
    print_header "INSTALLED PACKAGES"

    if check_command dpkg; then
        TOTAL=$(dpkg -l 2>/dev/null | grep '^ii' | wc -l)
        print_field "Total Installed Packages (dpkg)" "$TOTAL"
        echo ""
        echo -e "${CYAN}  -- Last 10 Installed Packages --${NC}"
        # dpkg lists installed packages
        dpkg -l 2>/dev/null | grep '^ii' | awk '{print "  "$2"\t"$3}' | tail -10
    fi

    if check_command apt; then
        echo ""
        echo -e "${CYAN}  -- Recently Installed (apt history) --${NC}"
        # apt history stored in /var/log/apt/history.log
        if [ -f /var/log/apt/history.log ]; then
            grep "Install:" /var/log/apt/history.log | tail -5
        else
            echo "  apt history log not available"
        fi
    fi

    if check_command rpm; then
        echo ""
        TOTAL_RPM=$(rpm -qa 2>/dev/null | wc -l)
        print_field "Total Installed Packages (rpm)" "$TOTAL_RPM"
    fi
}

collect_users_info() {
    print_header "LOGGED-IN USERS"

    if check_command who; then
        # who shows logged-in users
        echo -e "${CYAN}  -- Currently Logged In --${NC}"
        who
    fi

    echo ""

    if check_command last; then
        # last shows login history
        echo -e "${CYAN}  -- Recent Login History --${NC}"
        last -n 10
    fi

    echo ""

    # /etc/passwd contains system users
    echo -e "${CYAN}  -- All System Users --${NC}"
    awk -F: '$3 >= 1000 && $1 != "nobody" {print "  User: "$1" UID: "$3" Shell: "$7}' /etc/passwd
}

collect_services_info() {
    print_header "RUNNING SERVICES"

    if check_command systemctl; then
        # systemctl manages services
        systemctl list-units --type=service --state=running --no-pager 2>/dev/null | head -20
    fi
}

collect_processes_info() {
    print_header "ACTIVE PROCESSES"

    if check_command ps; then
        # ps shows running processes
        ps aux --sort=-%cpu | head -15
    fi
}

collect_ports_info() {
    print_header "OPEN PORTS"

    if check_command ss; then
        # ss shows network sockets
        ss -tuln
    fi
}

collect_firewall_info() {
    print_header "FIREWALL"

    if check_command ufw; then
        # ufw firewall status
        sudo ufw status 2>/dev/null | head -1
    elif check_command iptables; then
        # iptables firewall rules
        sudo iptables -L | head -20
    fi
}

collect_environment_info() {
    print_header "ENVIRONMENT"

    print_field "Shell" "$SHELL"
    print_field "User" "$(whoami)"
    print_field "Home" "$HOME"
    print_field "PATH" "$PATH"
}

collect_cron_info() {
    print_header "CRON JOBS"

    # crontab lists scheduled tasks
    crontab -l 2>/dev/null || echo "No crontab"
}

main() {
    OUTPUT_FILE="$REPORT_DIR/software_$(date '+%Y-%m-%d_%H-%M-%S').txt"

    log "START software audit"

    {
        echo ""
        echo -e "${CYAN}⚙️   SOFTWARE & OS AUDIT REPORT   ⚙️${NC}"
        echo -e "${YELLOW}Hostname :${NC} $(hostname)"
        echo -e "${YELLOW}Date     :${NC} $(date '+%Y-%m-%d %H:%M:%S')"

        collect_os_info
        collect_packages_info
        collect_users_info
        collect_services_info
        collect_processes_info
        collect_ports_info
        collect_firewall_info
        collect_environment_info
        collect_cron_info

        echo ""
        echo -e "${GREEN}[✓] Software & OS audit complete.${NC}"
        echo ""

    } | tee "$OUTPUT_FILE" # Save output to file and also print to console

    log "END software audit -> $OUTPUT_FILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi