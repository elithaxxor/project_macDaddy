#!/bin/bash

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew database
echo "Updating Homebrew..."
brew update

# Define tool categories as arrays
cli_security_tools=(afflib aircrack-ng apktool arping autopsy bettercap binwalk bulk_extractor cabextract cadaver chkrootkit crunch darkstat dc3dd dcfldd ddrescue dex2jar dns2tcp dnsmap dnstracer ettercap exiv2 exploitdb fcrackzip foremost fping fragroute freerdp gdb hashcat hping httrack hydra ike-scan john libewf libpst llvm lynis mac-robber masscan md5deep mdbtools mitmproxy nasm ncrack nikto nmap ophcrack p0f p7zip pdfcrack pev proxychains-ng proxytunnel ptunnel pwnat radare2 reaver recon-ng rkhunter siege sipp sipsak sleuthkit slowhttptest smali sqlmap ssdeep ssldump sslh sslscan sslsplit sslyze stunnel swaks tcpdump tcpflow tcpreplay theharvester truecrack udptunnel util-linux volatility yara testssl sshtrix gobuster pwntools snort osquery zeek cowpatty amass ffuf dirsearch subfinder nuclei trufflehog semgrep bandit wpscan whatweb wafw00f netcat socat feroxbuster rustscan dnsrecon impacket responder)

gui_security_tools=(armitage burp-suite cutter jad jd-gui maltego metasploit wireshark zenmap ghidra owasp-zap)

cli_programming_tools=(python ruby go node rust cmake make gcc clang git git-lfs maven gradle ant sbt ninja jq shellcheck shfmt bats-core checkstyle hadolint yamllint docker kubectl terraform ansible vagrant jenv java)

gui_programming_tools=(pycharm-ce visual-studio-code bbedit sublime-text intellij-idea-ce eclipse-ide netbeans android-studio xcode postman dbeaver-community gitkraken)

virtualization_tools=(utm virtualbox)

networking_tools=(openvpn tor)

misc_tools=(htop tree wget tmux)

# Function to install a single tool
install_tool() {
    local tool=$1
    if [[ " ${gui_security_tools[*]} " =~ " ${tool} " || " ${gui_programming_tools[*]} " =~ " ${tool} " || " ${virtualization_tools[*]} " =~ " ${tool} " ]]; then
        if [ "$tool" == "virtualbox" ]; then
            if [ "$(uname -m)" == "x86_64" ]; then
                brew install --cask virtualbox
            else
                echo "VirtualBox is not fully supported on Apple Silicon. Skipping."
            fi
        else
            brew install --cask "$tool"
        fi
    else
        brew install "$tool"
        if [ "$tool" == "java" ]; then
            brew upgrade java
            echo "Verifying Java installation..."
            java -version
            javac -version
        fi
    fi
}

# Function to install all tools in a category
install_all_in_category() {
    local category=$1
    local tools=()
    case $category in
        "CLI Security Tools") tools=("${cli_security_tools[@]}") ;;
        "GUI Security Tools") tools=("${gui_security_tools[@]}") ;;
        "CLI Programming Tools") tools=("${cli_programming_tools[@]}") ;;
        "GUI Programming Tools") tools=("${gui_programming_tools[@]}") ;;
        "Virtualization Tools") tools=("${virtualization_tools[@]}") ;;
        "Networking Tools") tools=("${networking_tools[@]}") ;;
        "Miscellaneous Tools") tools=("${misc_tools[@]}") ;;
    esac
    for tool in "${tools[@]}"; do
        install_tool "$tool"
    done
}

# Function to install all tools
install_all_tools() {
    echo "Installing all tools..."
    install_all_in_category "CLI Security Tools"
    install_all_in_category "GUI Security Tools"
    install_all_in_category "CLI Programming Tools"
    install_all_in_category "GUI Programming Tools"
    install_all_in_category "Virtualization Tools"
    install_all_in_category "Networking Tools"
    install_all_in_category "Miscellaneous Tools"
}

# Function to provide tool descriptions
get_description() {
    local tool=$1
    case $tool in
        afflib) echo "Tools for handling Advanced Forensic Format (AFF) images" ;;
        aircrack-ng) echo "Suite of tools for 802.11a/b/g WEP and WPA cracking" ;;
        apktool) echo "Tool for reverse engineering Android apk files" ;;
        arping) echo "ARP ping utility" ;;
        autopsy) echo "Digital forensics platform" ;;
        python) echo "General-purpose programming language" ;;
        java) echo "Java Development Kit (JDK) and Runtime Environment (JRE)" ;;
        virtualbox) echo "Virtualization software (Intel Macs only)" ;;
        utm) echo "Virtualization software for macOS" ;;
        htop) echo "Interactive process viewer" ;;
        tree) echo "Display directories as trees" ;;
        wget) echo "Non-interactive network downloader" ;;
        tmux) echo "Terminal multiplexer" ;;
        *) echo "No description available" ;;
    esac
}

# Function to display category information
display_category_info() {
    local category=$1
    local tools=()
    case $category in
        "CLI Security Tools") tools=("${cli_security_tools[@]}") ;;
        "GUI Security Tools") tools=("${gui_security_tools[@]}") ;;
        "CLI Programming Tools") tools=("${cli_programming_tools[@]}") ;;
        "GUI Programming Tools") tools=("${gui_programming_tools[@]}") ;;
        "Virtualization Tools") tools=("${virtualization_tools[@]}") ;;
        "Networking Tools") tools=("${networking_tools[@]}") ;;
        "Miscellaneous Tools") tools=("${misc_tools[@]}") ;;
    esac
    for tool in "${tools[@]}"; do
        desc=$(get_description "$tool")
        echo "$tool: $desc"
    done
}

# Function to handle individual tool installation within a category
handle_category() {
    local action=$1
    local category=$2
    shift 2
    local tools=("$@")
    for tool in "${tools[@]}"; do
        desc=$(get_description "$tool")
        echo "Tool: $tool"
        echo "Description: $desc"
        if [ "$action" == "install" ]; then
            read -p "Install $tool? (y/n): " choice
            if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
                install_tool "$tool"
            fi
        fi
        echo ""
    done
}

# Main menu loop
while true; do
    echo "Menu:"
    echo "1. Install all tools at once"
    echo "2. Install tools individually"
    echo "3. Get information about tools"
    echo "4. Exit"
    read -p "Choose an option: " choice
    case $choice in
        1)
            install_all_tools
            echo "All tools installed. Please check documentation for additional setup if required."
            ;;
        2)
            while true; do
                echo "Select category to install individually:"
                echo "1. CLI Security Tools"
                echo "2. GUI Security Tools"
                echo "3. CLI Programming Tools"
                echo "4. GUI Programming Tools"
                echo "5. Virtualization Tools"
                echo "6. Networking Tools"
                echo "7. Miscellaneous Tools"
                echo "0. Back to main menu"
                read -p "Choose a category: " cat_choice
                case $cat_choice in
                    1) handle_category "install" "CLI Security Tools" "${cli_security_tools[@]}" ;;
                    2) handle_category "install" "GUI Security Tools" "${gui_security_tools[@]}" ;;
                    3) handle_category "install" "CLI Programming Tools" "${cli_programming_tools[@]}" ;;
                    4) handle_category "install" "GUI Programming Tools" "${gui_programming_tools[@]}" ;;
                    5) handle_category "install" "Virtualization Tools" "${virtualization_tools[@]}" ;;
                    6) handle_category "install" "Networking Tools" "${networking_tools[@]}" ;;
                    7) handle_category "install" "Miscellaneous Tools" "${misc_tools[@]}" ;;
                    0) break ;;
                    *) echo "Invalid option" ;;
                esac
            done
            ;;
        3)
            while true; do
                echo "Select category for information:"
                echo "1. CLI Security Tools"
                echo "2. GUI Security Tools"
                echo "3. CLI Programming Tools"
                echo "4. GUI Programming Tools"
                echo "5. Virtualization Tools"
                echo "6. Networking Tools"
                echo "7. Miscellaneous Tools"
                echo "0. Back to main menu"
                read -p "Choose a category: " cat_choice
                case $cat_choice in
                    1) display_category_info "CLI Security Tools" ;;
                    2) display_category_info "GUI Security Tools" ;;
                    3) display_category_info "CLI Programming Tools" ;;
                    4) display_category_info "GUI Programming Tools" ;;
                    5) display_category_info "Virtualization Tools" ;;
                    6) display_category_info "Networking Tools" ;;
                    7) display_category_info "Miscellaneous Tools" ;;
                    0) break ;;
                    *) echo "Invalid option" ;;
                esac
            done
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option, please try again."
            ;;
    esac
    echo ""
done
