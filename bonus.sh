#!/bin/bash

REPORT_DIR="$HOME/sys_audit"
LOG_FILE="$REPORT_DIR/audit.log"
PORT=8080

mkdir -p "$REPORT_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BONUS] $1" >> "$LOG_FILE"
}

generate_html() {
    OUTPUT="$REPORT_DIR/report_$(date '+%Y-%m-%d_%H-%M-%S').html"
    {
    echo "<html><head><title>System Report</title></head><body>"
    echo "<h1>System Audit Report</h1>"
    echo "<p><b>Host:</b> $(hostname)</p>"
    echo "<p><b>Date:</b> $(date)</p>"
    echo "<h2>CPU</h2><pre>"
    lscpu
    echo "</pre>"
    echo "<h2>Memory</h2><pre>"
    free -h
    echo "</pre>"
    echo "<h2>Disk</h2><pre>"
    df -h
    echo "</pre>"
    echo "<h2>Processes</h2><pre>"
    ps aux | head -10
    echo "</pre>"
    echo "<h2>Ports</h2><pre>"
    ss -tuln
    echo "</pre>"
    echo "</body></html>"
    } > "$OUTPUT"
    log "HTML report generated -> $OUTPUT"
    echo "Saved: $OUTPUT"
}

run_alerts() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    RAM=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
    if (( $(echo "$CPU > 80" | bc -l) )); then
        echo "⚠️ High CPU: $CPU%"
        log "High CPU: $CPU%"
    fi
    if (( RAM > 80 )); then
        echo "⚠️ High RAM: $RAM%"
        log "High RAM: $RAM%"
    fi
}

start_dashboard() {
    cd "$REPORT_DIR" || exit
    echo "Starting dashboard at http://localhost:$PORT"
    echo "Press Ctrl+C to stop and return to menu."
    log "Dashboard started on port $PORT"
    python3 -m http.server "$PORT"
}

menu() {
    echo ""
    echo "1) Generate HTML Report"
    echo "2) Run Alerts Check"
    echo "3) Start Dashboard"
    echo "4) Back"
    echo -n "Choice: "
}

while true; do
    menu
    read -r choice
    case "$choice" in
        1) generate_html ;;
        2) run_alerts ;;
        3) start_dashboard ;;
        4) exit ;;
        *) echo "Invalid" ;;
    esac
done