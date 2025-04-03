#!/bin/bash

echo -e "\n\n"
cat ./assets/banner.txt
echo -e "\n\n"

# Update Homebrew database
echo "Updating Homebrew..."
brew update

# Install CLI Security Tools
echo "Installing CLI Security Tools..."
brew install afflib aircrack-ng apktool arping autopsy bettercap binwalk bulk_extractor cabextract cadaver chkrootkit crunch darkstat dc3dd dcfldd ddrescue dex2jar dns2tcp dnsmap dnstracer ettercap exiv2 exploitdb fcrackzip foremost fping fragroute freerdp gdb hashcat hping httrack hydra ike-scan john libewf libpst llvm lynis mac-robber masscan md5deep mdbtools mitmproxy nasm ncrack nikto nmap ophcrack p0f p7zip pdfcrack pev proxychains-ng proxytunnel ptunnel pwnat radare2 reaver recon-ng rkhunter siege sipp sipsak sleuthkit slowhttptest smali sqlmap ssdeep ssldump sslh sslscan sslsplit sslyze stunnel swaks tcpdump tcpflow tcpreplay theharvester truecrack udptunnel util-linux volatility yara testssl sshtrix gobuster pwntools snort osquery zeek cowpatty amass ffuf dirsearch subfinder nuclei trufflehog semgrep bandit wpscan whatweb wafw00f netcat socat feroxbuster rustscan dnsrecon impacket responder

# Install GUI Security Tools
echo "Installing GUI Security Tools..."
brew install --cask armitage burp-suite cutter jad jd-gui maltego metasploit wireshark zenmap ghidra owasp-zap

# Install CLI Programming Tools
echo "Installing CLI Programming Tools..."
brew install python ruby go node rust cmake make gcc clang git git-lfs maven gradle ant sbt ninja jq shellcheck shfmt bats-core checkstyle hadolint yamllint docker kubectl terraform ansible vagrant jenv

# Install GUI Programming Tools
echo "Installing GUI Programming Tools..."
brew install --cask pycharm-ce visual-studio-code bbedit sublime-text intellij-idea-ce eclipse-ide netbeans android-studio xcode postman dbeaver-community gitkraken

# Install and Update Java (JDK and JRE)
echo "Installing and Updating Java..."
brew install java
brew upgrade java

# Install Virtualization Tools
echo "Installing Virtualization Tools..."
brew install --cask utm
if [ "$(uname -m)" == "x86_64" ]; then
    brew install --cask virtualbox
else
    echo "Note: VirtualBox is not fully supported on Apple Silicon. UTM is recommended for Apple Silicon Macs."
fi

# Install Further Tools (Networking)
echo "Installing Networking Tools..."
brew install openvpn tor

# Install Miscellaneous Tools
echo "Installing Miscellaneous Tools..."
brew install htop tree wget tmux

# Verify Java Installation
echo "Verifying Java installation..."
java -version
javac -version

echo "All tools installed. Please check the documentation for each tool for any additional setup required."
