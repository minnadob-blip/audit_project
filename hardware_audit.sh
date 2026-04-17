#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW="\e[1;35m"
NC='\033[0m' # No Color (reset)

REPORT_DIR="$HOME/sys_audit"
LOG_FILE="$REPORT_DIR/audit.log"
mkdir -p "$REPORT_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HARDWARE] $1" >> "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${CYAN}----------------------------------${NC}"
    echo -e "${YELLOW}  $1${NC}"
    echo -e "${CYAN}----------------------------------${NC}"
}


print_field() {
    echo -e "${GREEN}  $1  :  ${NC} $2"
}


check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${RED}  [WARNING] Command '$1' not found. Skipping.${NC}"
        return 1
    fi
    return 0
}



collect_cpu_info() {
    print_header "CPU INFORMATION"

    
    if check_command lscpu; then
        print_field "Model"        "$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
        print_field "Architecture" "$(lscpu | grep 'Architecture' | awk -F: '{print $2}' | xargs)"
        print_field "CPU Cores"    "$(lscpu | grep '^CPU(s):' | awk -F: '{print $2}' | xargs)"
        print_field "Threads/Core" "$(lscpu | grep 'Thread(s) per core' | awk -F: '{print $2}' | xargs)"
        print_field "Max Speed"    "$(lscpu | grep 'CPU max MHz' | awk -F: '{print $2}' | xargs) MHz"
    fi
}


collect_gpu_info() {
    print_header "GPU INFORMATION"

    
    if check_command lspci; then
        GPU=$(lspci | grep -E 'VGA|3D|Display')
        if [ -z "$GPU" ]; then
            print_field "GPU" "No dedicated GPU detected"
        else
            echo "$GPU" | while read -r line; do
                print_field "GPU" "$line"
            done
        fi
    fi
}


collect_ram_info() {
    print_header "RAM INFORMATION"

    
    if check_command free; then
        TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
        USED=$(free -h  | awk '/^Mem:/ {print $3}')
        AVAIL=$(free -h | awk '/^Mem:/ {print $7}')
        SWAP=$(free -h  | awk '/^Swap:/ {print $2}')

        print_field "Total RAM"     "$TOTAL"
        print_field "Used RAM"      "$USED"
        print_field "Available RAM" "$AVAIL"
        print_field "Swap Space"    "$SWAP"
    fi

    # dmidecode reads hardware info directly from BIOS/UEFI (requires root)
    if check_command dmidecode; then
        echo ""
        echo -e "${CYAN}  -- Physical Memory Slots --${NC}"
        sudo dmidecode --type memory 2>/dev/null | grep -E 'Size|Type:|Speed' | grep -v 'No Module' | \
        while read -r line; do
            print_field "DIMM" "$line"
        done
    fi
}


collect_disk_info() {
    print_header "DISK INFORMATION 💽"

    
    if check_command df; then
        echo -e "${CYAN}  -- Filesystem Usage --${NC}"
        df -hT | grep -v tmpfs | grep -v udev | grep -v loop
    fi

    echo ""

    
    if check_command lsblk; then
        echo -e "${CYAN}  -- Block Devices & Partitions --${NC}"
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    fi
}


collect_network_info() {
    print_header "NETWORK INTERFACES 🌐"

    # ip link show lists all network interfaces with their MAC addresses
    if check_command ip; then
        echo -e "${CYAN}  -- Interfaces & MAC Addresses --${NC}"
        ip link show | awk '/^[0-9]+:/ {iface=$2} /link\/ether/ {print "  Interface: " iface "  MAC: " $2}'

        echo ""
        echo -e "${CYAN}  -- IP Addresses --${NC}"
        # ip addr show gives IP addresses assigned to each interface
        ip addr show | awk '/^[0-9]+:/ {iface=$2} /inet / {print "  Interface: " iface "  IP: " $2}'
    fi
}


collect_motherboard_info() {
    print_header "MOTHERBOARD & SYSTEM INFORMATION"

    
    if check_command dmidecode; then
        print_field "Manufacturer" "$(sudo dmidecode -s system-manufacturer 2>/dev/null)"
        print_field "Product Name" "$(sudo dmidecode -s system-product-name 2>/dev/null)"
        print_field "Serial Number" "$(sudo dmidecode -s system-serial-number 2>/dev/null)"
        print_field "BIOS Version" "$(sudo dmidecode -s bios-version 2>/dev/null)"
        print_field "BIOS Date"    "$(sudo dmidecode -s bios-release-date 2>/dev/null)"
    else
        
        print_field "Manufacturer" "$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)"
        print_field "Product Name" "$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
    fi
}

#
collect_usb_info() {
    print_header "USB DEVICES 🔌"

    # lsusb lists all USB devices connected to the system
    if check_command lsusb; then
        lsusb | while read -r line; do
            print_field "USB" "$line"
        done
    fi
}


main() {
    OUTPUT_FILE="$REPORT_DIR/hardware_$(date '+%Y-%m-%d_%H-%M-%S').txt"

    log "START hardware audit"

    echo ""
    echo -e "${CYAN}🖥️                                                                🖥️${NC}"
    echo -e "${CYAN}                  🖥️   HARDWARE AUDIT REPORT   🖥️                  ${NC}"
    echo -e "${YELLOW}    Hostname : ${NC}$(hostname)                                   "
    echo -e "${YELLOW}    Date     :${NC} $(date '+%Y-%m-%d %H:%M:%S')                  "
    echo -e "${CYAN}🖥️                                                                🖥️${NC}"

    {
        collect_cpu_info
        collect_gpu_info
        collect_ram_info
        collect_disk_info
        collect_network_info
        collect_motherboard_info
        collect_usb_info

        echo ""
        echo -e "${GREEN}[✓] Hardware audit complete.${NC}"
        echo ""
    } | tee "$OUTPUT_FILE"

    log "END hardware audit -> $OUTPUT_FILE"
}



    main
