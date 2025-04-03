#!/bin/bash

# Define tool categories as arrays
cli_security_tools=(nmap wireshark aircrack-ng)
gui_security_tools=(burp-suite wireshark)
cli_programming_tools=(python ruby java)
gui_programming_tools=(pycharm-ce visual-studio-code)
virtualization_tools=(utm virtualbox)
networking_tools=(openvpn tor)
misc_tools=(htop tree wget)

# Define cask tools (GUI tools installed with --cask)
cask_tools=("${gui_security_tools[@]}" "${gui_programming_tools[@]}" utm virtualbox)

# Function to get brief description of a tool
get_description() {
    case $1 in
        nmap) echo "Network exploration tool and security scanner" ;;
        wireshark) echo "Network protocol analyzer" ;;
        aircrack-ng) echo "WiFi security auditing tools" ;;
        burp-suite) echo "Web vulnerability scanner" ;;
        python) echo "High-level programming language" ;;
        ruby) echo "Dynamic, open-source programming language" ;;
        java) echo "Java Development Kit and Runtime Environment" ;;
        pycharm-ce) echo "Python IDE by JetBrains" ;;
        visual-studio-code) echo "Lightweight code editor" ;;
        utm) echo "Virtualization tool for macOS (Intel and Apple Silicon)" ;;
        virtualbox) echo "Virtualization tool (Intel Macs only)" ;;
        openvpn) echo "Open-source VPN solution" ;;
        tor) echo "Anonymity network" ;;
        htop) echo "Improved process viewer" ;;
        tree) echo "Directory structure visualizer" ;;
        wget) echo "File downloader" ;;
        *) echo "No description available" ;;
    esac
}

# Function to install a tool with appropriate command
install_tool() {
    local tool=$1
    if [[ " ${cask_tools[@]} " =~ " ${tool} " ]]; then
        if [ "$tool" == "virtualbox" ]; then
            if [ "$(uname -m)" == "x86_64" ]; then
                brew install --cask virtualbox
            else
                echo "VirtualBox is not fully supported on Apple Silicon. Skipping."
            fi
        else
            brew install --cask $tool
        fi
    else
        brew install $tool
    fi
}

# Function to handle category (install or info)
handle_category() {
    local action=$1
    local category=$2
    shift 2
    local tools=("$@")
    for tool in "${tools[@]}"; do
        desc=$(get_description $tool)
        echo "Tool: $tool"
        echo "Description: $desc"
        if [ "$action" == "install" ]; then
            read -p "Install $tool? (y/n): " choice
            if [ "$choice" == "y" ]; then
                install_tool $tool
            fi
        fi
        echo ""
    done
}

# Function to install all tools at once
install_all_tools() {
    echo "This will install all tools, which may take time and disk space."
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        return
    fi

    for tool in "${cli_security_tools[@]}"; do brew install $tool; done
    for tool in "${gui_security_tools[@]}"; do brew install --cask $tool; done
    for tool in "${cli_programming_tools[@]}"; do brew install $tool; done
    for tool in "${gui_programming_tools[@]}"; do brew install --cask $tool; done
    brew install --cask utm
    if [ "$(uname -m)" == "x86_64" ]; then brew install --cask virtualbox; fi
    for tool in "${networking_tools[@]}"; do brew install $tool; done
    for tool in "${misc_tools[@]}"; do brew install $tool; done
    brew upgrade java
}

# Main menu
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
                    1) handle_category "info" "CLI Security Tools" "${cli_security_tools[@]}" ;;
                    2) handle_category "info" "GUI Security Tools" "${gui_security_tools[@]}" ;;
                    3) handle_category "info" "CLI Programming Tools" "${cli_programming_tools[@]}" ;;
                    4) handle_category "info" "GUI Programming Tools" "${gui_programming_tools[@]}" ;;
                    5) handle_category "info" "Virtualization Tools" "${virtualization_tools[@]}" ;;
                    6) handle_category "info" "Networking Tools" "${networking_tools[@]}" ;;
                    7) handle_category "info" "Miscellaneous Tools" "${misc_tools[@]}" ;;
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
