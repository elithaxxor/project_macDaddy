#!/bin/bash
# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Setup logging
LOGS_DIR="$HOME/cleanup_logs"
mkdir -p "$LOGS_DIR"
DELETION_LOG="$LOGS_DIR/deletions.log"
OPERATIONS_LOG="$LOGS_DIR/operations.log"
ERROR_LOG="$LOGS_DIR/errors.log"

# Also create a log file in the current working directory
CWD_LOG="$(pwd)/cleanup_$(date +%Y-%m-%d_%H-%M-%S).log"
touch "$CWD_LOG"
echo "System Cleanup Utility - Deletion Log" > "$CWD_LOG"
echo "Started: $(date)" >> "$CWD_LOG"
echo "User: $(whoami)" >> "$CWD_LOG"
echo "----------------------------------------" >> "$CWD_LOG"

# Timestamp function for logs
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Log functions
log_operation() {
    echo "$(timestamp) - $1" >> "$OPERATIONS_LOG"
    echo -e "${BLUE}${BOLD}INFO:${NC} $1"
}

log_error() {
    echo "$(timestamp) - ERROR: $1" >> "$ERROR_LOG"
    echo -e "${RED}${BOLD}ERROR:${NC} $1" >&2
}

log_deletion() {
    local item="$1"
    echo "$(timestamp) - DELETED: $item" >> "$DELETION_LOG"
    echo "DELETED: $item" >> "$CWD_LOG"
}

# Function to check if the script is run with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} Some operations may require administrative privileges."
        echo -e "You can run again with 'sudo' for full functionality.\n"
    fi
}

# Function to get system information
get_system_info() {
    echo -e "\n=============== SYSTEM INFORMATION ===============" >> "$OPERATIONS_LOG"
    log_operation "Gathering system information..."
    
    OS_TYPE=$(uname -s)
    OS_VERSION=$(uname -r)
    HOSTNAME=$(hostname)
    CURRENT_USER=$(whoami)
    UPTIME=$(uptime)
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        CPU_MODEL=$(sysctl -n machdep.cpu.brand_string)
        CPU_CORES=$(sysctl -n hw.physicalcpu)
        CPU_THREADS=$(sysctl -n hw.logicalcpu)
        RAM_TOTAL=$(sysctl -n hw.memsize | awk '{print $0/1073741824}')
        RAM_TOTAL=$(printf "%.2f GB" $RAM_TOTAL)
    else
        CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//')
        CPU_CORES=$(grep -c "^processor" /proc/cpuinfo)
        CPU_THREADS=$CPU_CORES
        RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    fi
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
        MAC_ADDRESS=$(ifconfig en0 | awk '/ether/{print $2}')
        WIRELESS_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device" | awk '{print $2}')
        GATEWAY=$(netstat -nr | grep default | head -n 1 | awk '{print $2}')
        NETWORK_NAME=$(networksetup -getairportnetwork en0 2>/dev/null | cut -d ":" -f 2 | sed 's/^[ \t]*//')
    else
        IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
        MAC_ADDRESS=$(ip link show | grep -oP '(?<=link/ether\s)([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -n 1)
        WIRELESS_INTERFACE=$(ip link show | grep -i wireless | cut -d: -f2 | awk '{print $1}' | head -n 1)
        GATEWAY=$(ip route | grep default | head -n 1 | awk '{print $3}')
        NETWORK_NAME=$(iwgetid -r 2>/dev/null)
    fi
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        DISK_INFO=$(df -h / | tail -n 1)
        DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
        DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    else
        DISK_INFO=$(df -h / | tail -n 1)
        DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
        DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
        DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    fi
    
    echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                   SYSTEM INFORMATION                         ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}${BOLD}⚙️  HARDWARE INFORMATION${NC}"
    echo -e "${CYAN}${BOLD}CPU Model:${NC}        $CPU_MODEL"
    echo -e "${CYAN}${BOLD}CPU Cores:${NC}        $CPU_CORES physical cores, $CPU_THREADS threads"
    echo -e "${CYAN}${BOLD}RAM:${NC}              $RAM_TOTAL"
    
    echo -e "\n${YELLOW}${BOLD}💻 SYSTEM INFORMATION${NC}"
    echo -e "${CYAN}${BOLD}Operating System:${NC} $OS_TYPE $OS_VERSION"
    echo -e "${CYAN}${BOLD}Hostname:${NC}         $HOSTNAME"
    echo -e "${CYAN}${BOLD}Username:${NC}         $CURRENT_USER"
    echo -e "${CYAN}${BOLD}Date/Time:${NC}        $(date)"
    echo -e "${CYAN}${BOLD}Uptime:${NC}           $UPTIME"
    
    echo -e "\n${YELLOW}${BOLD}🌐 NETWORK INFORMATION${NC}"
    echo -e "${CYAN}${BOLD}IP Address:${NC}       $IP_ADDRESS"
    echo -e "${CYAN}${BOLD}Gateway:${NC}          $GATEWAY"
    echo -e "${CYAN}${BOLD}Network Name:${NC}     $NETWORK_NAME"
    echo -e "${CYAN}${BOLD}MAC Address:${NC}      $MAC_ADDRESS"
    echo -e "${CYAN}${BOLD}Interface:${NC}        $WIRELESS_INTERFACE"
    
    echo -e "\n${YELLOW}${BOLD}💾 DISK INFORMATION${NC}"
    echo -e "${CYAN}${BOLD}Total Disk Space:${NC} $DISK_TOTAL"
    echo -e "${CYAN}${BOLD}Used Disk Space:${NC}  $DISK_USED ($DISK_PERCENT)"
    echo -e "${CYAN}${BOLD}Available Space:${NC}  $DISK_AVAIL"
    
    local disk_percent_num=$(echo "$DISK_PERCENT" | tr -d '%')
    local bar_length=50
    local filled_length=$(($disk_percent_num * $bar_length / 100))
    local empty_length=$(($bar_length - $filled_length))
    
    disk_bar="["
    for ((i=0; i<$filled_length; i++)); do
        disk_bar+="█"
    done
    for ((i=0; i<$empty_length; i++)); do
        disk_bar+="░"
    done
    disk_bar+="] $DISK_PERCENT"
    
    if [ "$disk_percent_num" -gt 90 ]; then
        echo -e "${RED}${BOLD}Disk Usage:${NC}        $disk_bar ${RED}(CRITICAL)${NC}"
    elif [ "$disk_percent_num" -gt 75 ]; then
        echo -e "${YELLOW}${BOLD}Disk Usage:${NC}        $disk_bar ${YELLOW}(WARNING)${NC}"
    else
        echo -e "${GREEN}${BOLD}Disk Usage:${NC}        $disk_bar ${GREEN}(OK)${NC}"
    fi
    
    echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                END OF SYSTEM INFORMATION                     ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo "OS Type: $OS_TYPE $OS_VERSION" >> "$OPERATIONS_LOG"
    echo "Hostname: $HOSTNAME" >> "$OPERATIONS_LOG"
    echo "User: $CURRENT_USER" >> "$OPERATIONS_LOG"
    echo "CPU: $CPU_MODEL ($CPU_CORES cores, $CPU_THREADS threads)" >> "$OPERATIONS_LOG"
    echo "RAM: $RAM_TOTAL" >> "$OPERATIONS_LOG"
    echo "Date/Time: $(date)" >> "$OPERATIONS_LOG"
    echo "IP Address: $IP_ADDRESS" >> "$OPERATIONS_LOG"
    echo "Gateway: $GATEWAY" >> "$OPERATIONS_LOG"
    echo "Network: $NETWORK_NAME" >> "$OPERATIONS_LOG"
    echo "MAC Address: $MAC_ADDRESS" >> "$OPERATIONS_LOG"
    echo "Wireless Interface: $WIRELESS_INTERFACE" >> "$OPERATIONS_LOG"
    echo "Disk Space: Total=$DISK_TOTAL, Used=$DISK_USED ($DISK_PERCENT), Available=$DISK_AVAIL" >> "$OPERATIONS_LOG"
    echo "=========================================" >> "$OPERATIONS_LOG"
    
    echo "=== SYSTEM INFORMATION ===" >> "$CWD_LOG"
    echo "OS: $OS_TYPE $OS_VERSION" >> "$CWD_LOG"
    echo "Hostname: $HOSTNAME" >> "$CWD_LOG"
    echo "CPU: $CPU_MODEL" >> "$CWD_LOG"
    echo "RAM: $RAM_TOTAL" >> "$CWD_LOG"
    echo "IP: $IP_ADDRESS" >> "$CWD_LOG"
    echo "Gateway: $GATEWAY" >> "$CWD_LOG"
    echo "Disk: Total=$DISK_TOTAL, Available=$DISK_AVAIL" >> "$CWD_LOG"
    echo "=========================" >> "$CWD_LOG"
    
    read -p "Press Enter to continue..."
}

# Function to safely delete files with user confirmation
safe_delete() {
    local dir="$1"
    local description="$2"
    local skip_pattern="$3"
    
    if [ ! -d "$dir" ]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    
    local file_count=$(find "$dir" -type f | wc -l)
    if [ "$file_count" -eq 0 ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} No files found in $dir"
        return 0
    fi
    
    local total_size=$(du -sh "$dir" | awk '{print $1}')
    echo -e "\n--- Cleaning $description ($dir) - $(timestamp) ---" >> "$CWD_LOG"
    echo -e "${YELLOW}${BOLD}Warning:${NC} About to delete $file_count files in $dir ($total_size)"
    read -p "Are you sure you want to proceed? (y/n): " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo -e "${BLUE}${BOLD}Info:${NC} Deletion cancelled for $dir"
        log_operation "Deletion cancelled for $dir by user"
        echo "* Deletion cancelled by user" >> "$CWD_LOG"
        return 0
    fi
    
    log_operation "Starting deletion of $description in $dir"
    echo "===== Deleting files from $dir on $(timestamp) =====" >> "$DELETION_LOG"
    
    local deleted_count=0
    local skipped_count=0
    local error_count=0
    
    find "$dir" -type f | while read file; do
        if [[ -n "$skip_pattern" && "$file" =~ $skip_pattern ]]; then
            echo -e "${YELLOW}${BOLD}Skipping protected file:${NC} $file"
            ((skipped_count++))
        else
            rm -f "$file" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}${BOLD}Deleted:${NC} $file"
                log_deletion "$file"
                ((deleted_count++))
            else
                echo -e "${RED}${BOLD}Failed to delete:${NC} $file"
                log_error "Failed to delete: $file"
                ((error_count++))
            fi
        fi
    done
    
    find "$dir" -type d -empty -delete 2>/dev/null
    local new_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    echo -e "${GREEN}${BOLD}Completed cleaning $description.${NC}"
    echo -e "Directory size: Before=$total_size, After=$new_size"
    log_operation "Completed deletion in $dir. Size before: $total_size, after: $new_size"
    
    echo "* Size before: $total_size, after: $new_size" >> "$CWD_LOG"
    echo "* Files deleted: $deleted_count, skipped: $skipped_count, errors: $error_count" >> "$CWD_LOG"
    
    read -p "Press Enter to continue..."
}

# Function to analyze disk usage
analyze_disk_usage() {
    log_operation "Analyzing disk usage"
    
    echo -e "\n${GREEN}${BOLD}====== Disk Usage Analysis ======${NC}"
    
    if [ "$(uname)" = "Darwin" ]; then
        echo -e "${CYAN}${BOLD}System and User Temporary Locations:${NC}"
        echo -e "============================================"
        du -sh /private/var/log/ /private/var/tmp/ /tmp/ ~/Library/Logs/ ~/Library/Caches/ ~/.Trash/ 2>/dev/null
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/Library/Caches/:${NC}"
        du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -n 15
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/Library/Logs/:${NC}"
        du -sh ~/Library/Logs/* 2>/dev/null | sort -rh | head -n 15
    else
        echo -e "${CYAN}${BOLD}System and User Temporary Locations:${NC}"
        echo -e "============================================"
        du -sh /var/log/ /tmp/ /var/tmp/ ~/.cache/ ~/.local/share/Trash/files 2>/dev/null
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in ~/.cache/:${NC}"
        du -sh ~/.cache/* 2>/dev/null | sort -rh | head -n 15
        
        echo -e "\n${CYAN}${BOLD}Top 15 largest directories in /var/log/:${NC}"
        du -sh /var/log/* 2>/dev/null | sort -rh | head -n 15
    fi
    
    log_operation "Disk usage analysis completed"
    read -p "Press Enter to continue..."
}

# Function to clean user cache
clean_user_cache() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "$HOME/Library/Caches" "user cache" ".*\.(plist|app)$"
    else
        safe_delete "$HOME/.cache" "user cache" ".*\.(conf|log)$"
    fi
}

# Function to clean temporary files
clean_temp_files() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "/tmp" "temporary files" ".*\.(plist|app)$"
        safe_delete "/private/var/tmp" "system temporary files" ".*\.(plist|app)$"
    else
        safe_delete "/tmp" "temporary files" ".*\.(conf|log)$"
        safe_delete "/var/tmp" "system temporary files" ".*\.(conf|log)$"
    fi
}

# Function to clean trash
clean_trash() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "$HOME/.Trash" "trash" ""
    else
        safe_delete "$HOME/.local/share/Trash/files" "trash" ""
    fi
}

# Function to clean logs
clean_logs() {
    if [ "$(uname)" = "Darwin" ]; then
        safe_delete "$HOME/Library/Logs" "user logs" ".*System.*"
    else
        echo -e "${YELLOW}${BOLD}Note:${NC} Cleaning system logs typically requires sudo privileges."
        echo -e "This option will only clean logs the current user has permission to modify."
        if [ -d "$HOME/.local/share/logs" ]; then
            safe_delete "$HOME/.local/share/logs" "user logs" ""
        else
            echo -e "${YELLOW}${BOLD}Notice:${NC} No user logs directory found."
        fi
    fi
}

# Function to clean macOS System Data
clean_macos_system_data() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} This option is only available on macOS."
        read -p "Press Enter to continue..."
        return
    fi
    
    log_operation "Starting macOS System Data cleanup"
    echo -e "\n${GREEN}${BOLD}====== macOS System Data Cleanup ======${NC}"
    echo -e "This will safely clean various system caches and temporary files that"
    echo -e "contribute to the 'System Data' category in macOS storage."
    echo
    
    echo -e "${CYAN}${BOLD}Current Storage Status:${NC}"
    df -h | grep -E '/$|/System/Volumes/Data'
    echo
    
    echo -e "${CYAN}${BOLD}Analyzing System Data directories...${NC}"
    
    if [ -d "$HOME/Library/Application Support/MobileSync/Backup" ]; then
        BACKUP_SIZE=$(du -sh "$HOME/Library/Application Support/MobileSync/Backup" | awk '{print $1}')
        echo -e "iOS Device Backups: ${YELLOW}${BOLD}$BACKUP_SIZE${NC}"
        echo -e "  Location: $HOME/Library/Application Support/MobileSync/Backup"
        echo -e "  Note: These are your iOS device backups. Only delete if you don't need them."
        echo
        read -p "Would you like to see the list of backups? (y/n): " show_backups
        if [[ "$show_backups" == [yY] ]]; then
            echo
            ls -la "$HOME/Library/Application Support/MobileSync/Backup"
            echo
            read -p "Would you like to delete these backups? (y/n): " delete_backups
            if [[ "$delete_backups" == [yY] ]]; then
                safe_delete "$HOME/Library/Application Support/MobileSync/Backup" "iOS device backups" ""
            fi
        fi
    else
        echo -e "No iOS Device Backups found."
    fi
    
    if [ -d "$HOME/Library/Developer" ]; then
        XCODE_SIZE=$(du -sh "$HOME/Library/Developer" | awk '{print $1}')
        echo -e "XCode Developer Cache: ${YELLOW}${BOLD}$XCODE_SIZE${NC}"
        read -p "Would you like to clean XCode caches? (y/n): " clean_xcode
        if [[ "$clean_xcode" == [yY] ]]; then
            safe_delete "$HOME/Library/Developer/Xcode/DerivedData" "XCode derived data" ""
            safe_delete "$HOME/Library/Developer/Xcode/Archives" "XCode archives" ""
            safe_delete "$HOME/Library/Developer/Xcode/iOS DeviceSupport" "iOS device support files" ""
        fi
    fi
    
    if [ -d "$HOME/Library/Developer/CoreSimulator" ]; then
        SIM_SIZE=$(du -sh "$HOME/Library/Developer/CoreSimulator" | awk '{print $1}')
        echo -e "iOS Simulator Data: ${YELLOW}${BOLD}$SIM_SIZE${NC}"
        read -p "Would you like to clean simulator data? (y/n): " clean_sim
        if [[ "$clean_sim" == [yY] ]]; then
            if command -v xcrun &>/dev/null; then
                echo -e "Cleaning simulator data using xcrun..."
                xcrun simctl delete unavailable
                log_operation "Cleaned unavailable simulators"
            else
                safe_delete "$HOME/Library/Developer/CoreSimulator/Devices" "simulator devices" ""
            fi
        fi
    fi
    
    REVS_SIZE=$(du -sh "$HOME/.DocumentRevisions-V100" 2>/dev/null | awk '{print $1}')
    if [ -n "$REVS_SIZE" ]; then
        echo -e "Document Revisions: ${YELLOW}${BOLD}$REVS_SIZE${NC}"
        echo -e "  Note: These are used for document versioning. Cleaning may affect document history."
        read -p "Would you like to clean document revisions? (y/n): " clean_revs
        if [[ "$clean_revs" == [yY] ]]; then
            if [ "$EUID" -eq 0 ]; then
                safe_delete "$HOME/.DocumentRevisions-V100/PerUID" "document revisions" ""
            else
                echo -e "${YELLOW}${BOLD}Notice:${NC} Administrative privileges required for this operation."
                echo -e "Please run this script with sudo to clean document revisions."
            fi
        fi
    fi
    
    if [ -d "/Library/Updates" ]; then
        UPDATES_SIZE=$(du -sh "/Library/Updates" 2>/dev/null | awk '{print $1}')
        echo -e "Software Update Downloads: ${YELLOW}${BOLD}$UPDATES_SIZE${NC}"
        read -p "Would you like to clean software update downloads? (y/n): " clean_updates
        if [[ "$clean_updates" == [yY] ]]; then
            if [ "$EUID" -eq 0 ]; then
                safe_delete "/Library/Updates" "software update downloads" ""
            else
                echo -e "${YELLOW}${BOLD}Notice:${NC} Administrative privileges required for this operation."
                echo -e "Please run this script with sudo to clean software update downloads."
            fi
        fi
    fi
    
    if [ -d "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads" ]; then
        MAIL_SIZE=$(du -sh "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads" | awk '{print $1}')
        echo -e "Mail Downloads: ${YELLOW}${BOLD}$MAIL_SIZE${NC}"
        read -p "Would you like to clean mail downloads? (y/n): " clean_mail
        if [[ "$clean_mail" == [yY] ]]; then
            safe_delete "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads" "mail downloads" ""
        fi
    fi
    
    if [ -d "$HOME/Library/Safari" ]; then
        SAFARI_SIZE=$(du -sh "$HOME/Library/Safari" | awk '{print $1}')
        echo -e "Safari Cache: ${YELLOW}${BOLD}$SAFARI_SIZE${NC}"
        read -p "Would you like to clean Safari cache? This will clear your browsing history (y/n): " clean_safari
        if [[ "$clean_safari" == [yY] ]]; then
            safe_delete "$HOME/Library/Safari/LocalStorage" "safari local storage" ""
            safe_delete "$HOME/Library/Safari/Databases" "safari databases" ""
            safe_delete "$HOME/Library/Safari/Cache.db" "safari cache database" ""
        fi
    fi
    
    if [ -f "$HOME/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2" ]; then
        echo -e "Cleaning download quarantine database..."
        rm -f "$HOME/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2" 2>/dev/null
        log_deletion "$HOME/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2"
        echo -e "${GREEN}${BOLD}Done!${NC}"
    fi
    
    echo -e "\n${CYAN}${BOLD}Checking for large Application Support caches...${NC}"
    find "$HOME/Library/Application Support" -type d -mindepth 1 -maxdepth 1 | while read dir; do
        dir_size=$(du -sm "$dir" 2>/dev/null | awk '{print $1}')
        if [ "$dir_size" -gt 100 ]; then
            app_name=$(basename "$dir")
            echo -e "$app_name: ${YELLOW}${BOLD}${dir_size}MB${NC}"
        fi
    done
    
    echo -e "\n${CYAN}${BOLD}Checking for unnecessary language resources...${NC}"
    echo -e "Applications contain resources for many languages, which can take up space."
    read -p "Would you like to list applications with their language resource sizes? (y/n): " list_langs
    if [[ "$list_langs" == [yY] ]]; then
        echo -e "\nThis may take a while to analyze..."
        find /Applications -type d -name "*.app" -maxdepth 2 | while read app; do
            app_name=$(basename "$app" .app)
            if [ -d "$app/Contents/Resources" ]; then
                lang_count=$(find "$app/Contents/Resources" -name "*.lproj" | wc -l)
                if [ "$lang_count" -gt 0 ]; then
                    lang_size=$(du -sm $(find "$app/Contents/Resources" -name "*.lproj") 2>/dev/null | awk '{sum+=$1} END {print sum}')
                    if [ -n "$lang_size" ] && [ "$lang_size" -gt 5 ]; then
                        echo -e "$app_name: ${YELLOW}${BOLD}${lang_size}MB${NC} in language resources"
                    fi
                fi
            fi
        done
        echo -e "\n${YELLOW}${BOLD}Warning:${NC} Removing language resources may cause issues with localization."
        echo -e "It's recommended to only remove languages you don't use from apps you don't need localized."
        echo -e "This requires administrative privileges."
        if [ "$EUID" -ne 0 ]; then
            echo -e "${RED}${BOLD}This operation requires sudo privileges.${NC}"
            echo -e "Please run the script with sudo to perform language resource cleanup."
        else
            read -p "Do you want to remove non-English language resources from an application? (y/n): " clean_langs
            if [[ "$clean_langs" == [yY] ]]; then
                echo -e "Enter the exact name of the application (e.g., 'Firefox'):"
                read target_app
                app_path=$(find /Applications -maxdepth 2 -name "${target_app}.app" | head -1)
                if [ -n "$app_path" ] && [ -d "$app_path" ]; then
                    echo -e "Found $target_app at $app_path"
                    echo -e "Removing non-English language resources..."
                    find "$app_path/Contents/Resources" -name "*.lproj" ! -name "en.lproj" ! -name "English.lproj" ! -name "Base.lproj" -exec rm -rf {} \; 2>/dev/null
                    echo -e "${GREEN}${BOLD}Done!${NC}"
                    log_operation "Removed non-English language resources from $target_app"
                else
                    echo -e "${RED}${BOLD}Error:${NC} Could not find application '$target_app'."
                fi
            fi
        fi
    fi
    
    echo -e "\n${CYAN}${BOLD}Storage Status After Cleanup:${NC}"
    df -h | grep -E '/$|/System/Volumes/Data'
    
    log_operation "macOS System Data cleanup completed"
    read -p "Press Enter to continue..."
}

# Function to clean Time Machine snapshots (macOS only)
clean_time_machine_snapshots() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}Notice:${NC} Time Machine is only available on macOS."
        read -p "Press Enter to continue..."
        return
    fi
    
    log_operation "Listing Time Machine snapshots"
    echo -e "${CYAN}${BOLD}Current Time Machine Snapshots:${NC}"
    tmutil listlocalsnapshots / 2>/dev/null
    echo
    read -p "Do you want to delete all local Time Machine snapshots? (y/n): " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo -e "${BLUE}${BOLD}Info:${NC} Snapshot deletion cancelled."
        log_operation "Time Machine snapshot deletion cancelled by user"
        read -p "Press Enter to continue..."
        return
    fi
    if [ "$EUID" -eq 0 ]; then
        log_operation "Deleting all Time Machine snapshots"
        echo -e "${GREEN}${BOLD}Deleting all Time Machine snapshots...${NC}"
        tmutil deletelocalsnapshots / &>/dev/null
        echo -e "${GREEN}${BOLD}Done!${NC}"
    else
        echo -e "${YELLOW}${BOLD}Notice:${NC} Administrative privileges required for this operation."
        echo -e "Please run this script with sudo to delete Time Machine snapshots."
    fi
    log_operation "Time Machine snapshot cleanup completed"
    read -p "Press Enter to continue..."
}

# --- New Functions for Additional Cleanup Tasks on Darwin ---

# Clean Mail Attachments
clean_mail_attachments() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}This function is available only on macOS.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    log_operation "Starting mail attachments cleanup"
    ATTACHMENTS_DIR="$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"
    if [ -d "$ATTACHMENTS_DIR" ]; then
        safe_delete "$ATTACHMENTS_DIR" "Mail Attachments" ""
    else
        echo -e "${YELLOW}Mail attachments directory not found.${NC}"
    fi
    log_operation "Mail attachments cleanup completed"
    read -p "Press Enter to continue..."
}

# Clean System Caches (in /Library/Caches)
clean_system_caches() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}This function is available only on macOS.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    log_operation "Starting system caches cleanup"
    SYS_CACHE="/Library/Caches"
    if [ -d "$SYS_CACHE" ]; then
        safe_delete "$SYS_CACHE" "System Caches" ""
    else
        echo -e "${YELLOW}System caches directory not found.${NC}"
    fi
    log_operation "System caches cleanup completed"
    read -p "Press Enter to continue..."
}

# Clean iMessage Attachments
clean_imessage_attachments() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}This function is available only on macOS.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    log_operation "Starting iMessage attachments cleanup"
    MSG_ATTACH="$HOME/Library/Messages/Attachments"
    if [ -d "$MSG_ATTACH" ]; then
        safe_delete "$MSG_ATTACH" "iMessage Attachments" ""
    else
        echo -e "${YELLOW}iMessage attachments directory not found.${NC}"
    fi
    log_operation "iMessage attachments cleanup completed"
    read -p "Press Enter to continue..."
}

# Clean Quick Look Cache
clean_quicklook_cache() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}This function is available only on macOS.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    log_operation "Resetting Quick Look cache"
    qlmanage -r cache
    log_operation "Quick Look cache reset"
    read -p "Press Enter to continue..."
}

# Rebuild Spotlight Index
clean_spotlight_index() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}This function is available only on macOS.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    log_operation "Rebuilding Spotlight index"
    sudo mdutil -E /
    log_operation "Spotlight index rebuilt"
    read -p "Press Enter to continue..."
}

# Clean System Update Files
clean_system_update_files() {
    if [ "$(uname)" != "Darwin" ]; then
        echo -e "${YELLOW}${BOLD}This function is available only on macOS.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    log_operation "Cleaning system update files"
    UPDATE_DIR="/Library/Updates"
    if [ -d "$UPDATE_DIR" ]; then
        safe_delete "$UPDATE_DIR" "System Update Files" ""
    else
        echo -e "${YELLOW}System update files directory not found.${NC}"
    fi
    log_operation "System update files cleanup completed"
    read -p "Press Enter to continue..."
}

# --- End of New Functions ---

# Main menu function
show_menu() {
    clear
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                 SYSTEM CLEANUP UTILITY                       ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "${CYAN}${BOLD}Operating System:${NC} $(uname -s) $(uname -r)"
    echo -e "${CYAN}${BOLD}Hostname:${NC}        $(hostname)"
    echo -e "${CYAN}${BOLD}User:${NC}            $(whoami)"
    echo -e "${CYAN}${BOLD}Date:${NC}            $(date +"%Y-%m-%d %H:%M:%S")"
    
    DISK_INFO=$(df -h / | tail -n 1)
    DISK_USED=$(echo "$DISK_INFO" | awk '{print $5}')
    DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
    
    DISK_PERCENT_NUM=$(echo "$DISK_USED" | tr -d '%')
    if [ "$DISK_PERCENT_NUM" -gt 90 ]; then
        DISK_COLOR="${RED}${BOLD}"
    elif [ "$DISK_PERCENT_NUM" -gt 75 ]; then
        DISK_COLOR="${YELLOW}${BOLD}"
    else
        DISK_COLOR="${GREEN}${BOLD}"
    fi
    
    echo -e "${CYAN}${BOLD}Disk Usage:${NC}       ${DISK_COLOR}$DISK_USED used, $DISK_AVAIL available${NC}"
    
    echo -e "\n${YELLOW}${BOLD}Select an option:${NC}"
    echo -e "${WHITE}╔════╦════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}${BOLD}1${NC}  ${WHITE}║${NC} ${CYAN}System Information${NC}                  ${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}${BOLD}2${NC}  ${WHITE}║${NC} ${CYAN}Analyze Disk Usage${NC}                  ${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}${BOLD}3${NC}  ${WHITE}║${NC} ${CYAN}Clean User Cache${NC}                    ${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}${BOLD}4${NC}  ${WHITE}║${NC} ${CYAN}Clean Temporary Files${NC}               ${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}${BOLD}5${NC}  ${WHITE}║${NC} ${CYAN}Clean Trash/Recycle Bin${NC}             ${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}${BOLD}6${NC}  ${WHITE}║${NC} ${CYAN}Clean Logs${NC}                          ${WHITE}║${NC}"
    echo -e "${WHITE}║${NC} ${GREEN}${BOLD}7${NC}  ${WHITE}║${NC} ${CYAN}Wi-Fi Diagnostics${NC}                   ${WHITE}║${NC}"
    
    if [ "$(uname)" = "Darwin" ]; then
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}8${NC}  ${WHITE}║${NC} ${CYAN}Clean Time Machine Snapshots${NC}        ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}9${NC}  ${WHITE}║${NC} ${CYAN}Clean macOS System Data${NC}             ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}10${NC}  ${WHITE}║${NC} ${CYAN}Clean Browser Caches${NC}                ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}11${NC}  ${WHITE}║${NC} ${CYAN}Clean Package Manager Caches${NC}        ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}12${NC}  ${WHITE}║${NC} ${CYAN}Clean Mail Attachments${NC}              ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}13${NC}  ${WHITE}║${NC} ${CYAN}Clean System Caches${NC}                 ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}14${NC}  ${WHITE}║${NC} ${CYAN}Clean iMessage Attachments${NC}          ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}15${NC}  ${WHITE}║${NC} ${CYAN}Clean Quick Look Cache${NC}              ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}16${NC}  ${WHITE}║${NC} ${CYAN}Rebuild Spotlight Index${NC}             ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC} ${GREEN}${BOLD}17${NC}  ${WHITE}║${NC} ${CYAN}Clean System Update Files${NC}           ${WHITE}║${NC}"
    fi
    
    echo -e "${WHITE}║${NC} ${RED}${BOLD}0${NC}  ${WHITE}║${NC} ${RED}Exit${NC}                                ${WHITE}║${NC}"
    echo -e "${WHITE}╚════╩════════════════════════════════════╝${NC}"
    
    if [ -f "$CWD_LOG" ]; then
        DELETION_COUNT=$(grep -c "DELETED:" "$CWD_LOG")
        if [ "$DELETION_COUNT" -gt 0 ]; then
            echo -e "\n${BLUE}${BOLD}Session summary:${NC} $DELETION_COUNT files deleted so far"
            echo -e "${BLUE}${BOLD}Log file:${NC} $CWD_LOG"
        fi
    fi
    
    echo -e "\n${YELLOW}${BOLD}Enter your choice:${NC} "
}

# Set up trap to handle script interruption
trap "echo -e '\n${MAGENTA}${BOLD}🛑 Script interrupted${NC}'; exit 1" SIGINT SIGTERM

# Welcome message and main function
main() {
    clear
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║             WELCOME TO SYSTEM CLEANUP UTILITY                ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${RED}${BOLD}⚠️  WARNING - PLEASE READ CAREFULLY${NC}"
    echo -e "${YELLOW}This utility will delete files from your system. While it has been designed"
    echo -e "with safety in mind, deleting system files always carries some risk."
    echo -e "Possible consequences include:${NC}"
    echo -e "  ${RED}• Loss of unsaved data${NC}"
    echo -e "  ${RED}• Removal of application settings${NC}"
    echo -e "  ${RED}• Potential issues with some applications${NC}"
    echo -e "  ${RED}• Removal of cached content that will need to be re-downloaded${NC}"
    
    echo -e "\n${YELLOW}RECOMMENDED PRECAUTIONS:${NC}"
    echo -e "  ${GREEN}• Backup important data before proceeding${NC}"
    echo -e "  ${GREEN}• Close all running applications${NC}"
    echo -e "  ${GREEN}• Review the logs after each operation${NC}"
    echo -e "  ${GREEN}• Read confirmation prompts carefully${NC}"
    
    echo -e "\n${BLUE}${BOLD}This utility will:${NC}"
    echo -e "  ${CYAN}• Show you what will be deleted before taking action${NC}"
    echo -e "  ${CYAN}• Ask for confirmation before any deletion${NC}"
    echo -e "  ${CYAN}• Log all actions to help track changes${NC}"
    echo -e "  ${CYAN}• Protect sensitive system files${NC}"
    
    echo -e "\n${WHITE}${BOLD}Do you understand these risks and wish to continue? (y/n)${NC}"
    read -p "> " consent
    if [[ "$consent" != [yY] ]]; then
        echo -e "\n${CYAN}Script canceled. No changes were made to your system.${NC}"
        exit 0
    fi
    
    echo -e "\n${GREEN}${BOLD}Thank you. Let's proceed with the cleanup utility...${NC}"
    sleep 1
    log_operation "Script started by user $(whoami)"
    IFS_OLD="$IFS"
    IFS=
}  # End of main function

# Start the script
main
check_sudo

while true; do
    show_menu
    read choice
    echo
    
    case $choice in
        1) get_system_info ;;
        2) analyze_disk_usage ;;
        3) clean_user_cache ;;
        4) clean_temp_files ;;
        5) clean_trash ;;
        6) clean_logs ;;
        7) scan_wifi ;;
        8)
            if [ "$(uname)" = "Darwin" ]; then
                clean_time_machine_snapshots
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        9)
            if [ "$(uname)" = "Darwin" ]; then
                clean_macos_system_data
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        10)
            if [ "$(uname)" = "Darwin" ]; then
                clean_browser_caches
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        11)
            if [ "$(uname)" = "Darwin" ]; then
                clean_package_manager_caches
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        12)
            if [ "$(uname)" = "Darwin" ]; then
                clean_mail_attachments
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        13)
            if [ "$(uname)" = "Darwin" ]; then
                clean_system_caches
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        14)
            if [ "$(uname)" = "Darwin" ]; then
                clean_imessage_attachments
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        15)
            if [ "$(uname)" = "Darwin" ]; then
                clean_quicklook_cache
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        16)
            if [ "$(uname)" = "Darwin" ]; then
                clean_spotlight_index
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        17)
            if [ "$(uname)" = "Darwin" ]; then
                clean_system_update_files
            else
                echo -e "${RED}${BOLD}Invalid option${NC}"
                sleep 1
            fi
            ;;
        0)
            echo -e "${GREEN}${BOLD}Thank you for using System Cleanup Utility!${NC}"
            log_operation "Script terminated normally by user"
            echo "----------------------------------------" >> "$CWD_LOG"
            echo "Cleanup completed: $(date)" >> "$CWD_LOG"
            DELETION_COUNT=$(grep -c "DELETED:" "$CWD_LOG")
            echo "Total items deleted: $DELETION_COUNT" >> "$CWD_LOG"
            IFS="$IFS_OLD"
            echo -e "${GREEN}${BOLD}A log of all deletions has been saved to:${NC}"
            echo -e "${CYAN}$CWD_LOG${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}${BOLD}Invalid option${NC}"
            sleep 1
            ;;
    esac
done
