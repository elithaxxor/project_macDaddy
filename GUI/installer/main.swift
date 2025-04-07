import SwiftUI

// Define a Tool struct to hold tool data
struct Tool: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isCask: Bool // True for GUI tools installed via Homebrew cask
    let category: String
}

// Define installation status for progress tracking
enum InstallationStatus {
    case notStarted
    case inProgress
    case completed
    case failed(String)
}

// Create an observable object for managing installations
class InstallationManager: ObservableObject {
    @Published var installationStatus = [UUID: InstallationStatus]()
    @Published var overallProgress: Double = 0.0
    @Published var isInstalling = false
    @Published var currentMessage = ""
    
    func installTools(_ toolsToInstall: [Tool]) async {
        guard !toolsToInstall.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isInstalling = true
            self.overallProgress = 0.0
            
            // Initialize all tools as not started
            for tool in toolsToInstall {
                self.installationStatus[tool.id] = .notStarted
            }
        }
        
        let totalTools = Double(toolsToInstall.count)
        var completedTools = 0.0
        
        for tool in toolsToInstall {
            do {
                // Update status to in progress
                DispatchQueue.main.async {
                    self.installationStatus[tool.id] = .inProgress
                    self.currentMessage = "Installing \(tool.name)..."
                }
                
                // Perform the installation
                try await installTool(tool)
                
                // Update status to completed
                DispatchQueue.main.async {
                    self.installationStatus[tool.id] = .completed
                    completedTools += 1
                    self.overallProgress = completedTools / totalTools
                }
            } catch {
                // Update status to failed with error message
                DispatchQueue.main.async {
                    self.installationStatus[tool.id] = .failed(error.localizedDescription)
                    completedTools += 1
                    self.overallProgress = completedTools / totalTools
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isInstalling = false
            self.currentMessage = "Installation complete"
        }
    }
    
    private func installTool(_ tool: Tool) async throws {
        // Get the script path
        guard let scriptPath = Bundle.main.path(forResource: "install_tools", ofType: "sh") else {
            throw NSError(domain: "ToolInstaller", code: 1, userInfo: [NSLocalizedDescriptionKey: "Installation script not found"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "\(scriptPath) --install \(tool.name)"]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.terminationHandler = { process in
                    if process.terminationStatus == 0 {
                        continuation.resume()
                    } else {
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        let error = NSError(domain: "ToolInstaller", code: Int(process.terminationStatus), 
                                           userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        continuation.resume(throwing: error)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// Main view with sidebar navigation
struct ContentView: View {
    @State private var selectedTools = Set<UUID>()
    @State private var selectedCategory = "CLI Security"
    @StateObject private var installationManager = InstallationManager()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            // Sidebar with categories
            List {
                Section(header: Text("Categories")) {
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(destination: ToolListView(
                            tools: filteredTools(category: category), 
                            selectedTools: $selectedTools,
                            installationManager: installationManager,
                            searchText: $searchText)
                        ) {
                            Text(category)
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())

            // Default tool list view
            ToolListView(
                tools: filteredTools(category: selectedCategory), 
                selectedTools: $selectedTools,
                installationManager: installationManager,
                searchText: $searchText
            )
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                TextField("Search tools...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
            }
            
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    let selected = tools.filter { selectedTools.contains($0.id) }
                    Task {
                        await installationManager.installTools(selected)
                    }
                }) {
                    Text("Install Selected")
                }
                .disabled(installationManager.isInstalling || selectedTools.isEmpty)
            }
            
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    Task {
                        await installationManager.installTools(tools)
                    }
                }) {
                    Text("Install All")
                }
                .disabled(installationManager.isInstalling)
            }
        }
        .overlay(
            Group {
                if installationManager.isInstalling {
                    VStack {
                        Text("Installation Progress")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        ProgressView(value: installationManager.overallProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal)
                        
                        Text("\(Int(installationManager.overallProgress * 100))%")
                            .font(.caption)
                            .padding(.top, 5)
                        
                        Text(installationManager.currentMessage)
                            .font(.caption)
                            .padding(.bottom)
                    }
                    .padding()
                    .frame(width: 300)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
            }
        )
        .frame(minWidth: 600, minHeight: 400)
    }

    // Extract unique categories from tools
    private var categories: [String] {
        Array(Set(tools.map { $0.category })).sorted()
    }

    // Filter tools by category and search text
    private func filteredTools(category: String) -> [Tool] {
        let categoryFiltered = tools.filter { $0.category == category }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) || 
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

// View for displaying tools in a category
struct ToolListView: View {
    let tools: [Tool]
    @Binding var selectedTools: Set<UUID>
    let installationManager: InstallationManager
    @Binding var searchText: String
    @State private var selectedTool: Tool? = nil
    
    var body: some View {
        VStack {
            List {
                ForEach(tools) { tool in
                    HStack {
                        Image(systemName: tool.isCask ? "display" : "terminal")
                            .foregroundColor(.blue)
                            .frame(width: 25)
                        
                        VStack(alignment: .leading) {
                            Text(tool.name).font(.headline)
                            Text(tool.description).font(.subheadline).foregroundColor(.gray)
                        }
                        .onTapGesture {
                            selectedTool = tool
                        }
                        
                        Spacer()
                        
                        // Installation status indicator
                        if let status = installationManager.installationStatus[tool.id] {
                            switch status {
                            case .notStarted:
                                EmptyView()
                            case .inProgress:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            case .completed:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            case .failed(let message):
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .help(message)
                            }
                        }
                        
                        if tool.category != "Virtualization" || (tool.name != "virtualbox" || isIntel()) {
                            Toggle("", isOn: Binding(
                                get: { selectedTools.contains(tool.id) },
                                set: { if $0 { selectedTools.insert(tool.id) } else { selectedTools.remove(tool.id) } }
                            )).labelsHidden()
                            .disabled(installationManager.isInstalling)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTool = tool
                    }
                }
            }
            
            if tools.isEmpty && !searchText.isEmpty {
                VStack {
                    Spacer()
                    Text("No tools match your search criteria")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .navigationTitle("Install Tools")
        .sheet(item: $selectedTool) { tool in
            ToolDetailView(tool: tool)
        }
    }

    // Check if the system is Intel-based
    private func isIntel() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/uname"
        process.arguments = ["-m"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return output == "x86_64"
    }
}

// Detail view for a selected tool
struct ToolDetailView: View {
    let tool: Tool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: tool.isCask ? "display" : "terminal")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text(tool.name)
                    .font(.largeTitle)
                    .bold()
            }
            
            Divider()
            
            Text("Description")
                .font(.headline)
            
            Text(tool.description)
                .font(.body)
            
            Divider()
            
            Group {
                Text("Installation Type")
                    .font(.headline)
                
                Text(tool.isCask ? "GUI Application (Homebrew Cask)" : "Command Line Tool (Homebrew Formula)")
                    .font(.body)
                
                Text("Category")
                    .font(.headline)
                
                Text(tool.category)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

let tools = [
    // CLI Security Tools
    Tool(name: "afflib", description: "Tools for handling Advanced Forensic Format (AFF) images", isCask: false, category: "CLI Security"),
    Tool(name: "aircrack-ng", description: "Suite of tools for 802.11a/b/g WEP and WPA cracking", isCask: false, category: "CLI Security"),
    Tool(name: "apktool", description: "Tool for reverse engineering Android apk files", isCask: false, category: "CLI Security"),
    Tool(name: "arping", description: "ARP ping utility", isCask: false, category: "CLI Security"),
    Tool(name: "autopsy", description: "Digital forensics platform", isCask: false, category: "CLI Security"),
    Tool(name: "bettercap", description: "Swiss Army knife for network attacks and monitoring", isCask: false, category: "CLI Security"),
    Tool(name: "binwalk", description: "Firmware analysis tool", isCask: false, category: "CLI Security"),
    Tool(name: "bulk_extractor", description: "Extracts information from digital evidence", isCask: false, category: "CLI Security"),
    Tool(name: "cabextract", description: "Extracts files from Microsoft cabinet archives", isCask: false, category: "CLI Security"),
    Tool(name: "cadaver", description: "Command-line WebDAV client", isCask: false, category: "CLI Security"),
    Tool(name: "chkrootkit", description: "Locally checks for signs of a rootkit", isCask: false, category: "CLI Security"),
    Tool(name: "crunch", description: "Wordlist generator", isCask: false, category: "CLI Security"),
    Tool(name: "darkstat", description: "Network traffic analyzer", isCask: false, category: "CLI Security"),
    Tool(name: "dc3dd", description: "Enhanced version of dd for forensics", isCask: false, category: "CLI Security"),
    Tool(name: "dcfldd", description: "Enhanced version of dd for forensics", isCask: false, category: "CLI Security"),
    Tool(name: "ddrescue", description: "Data recovery tool", isCask: false, category: "CLI Security"),
    Tool(name: "dex2jar", description: "Tools to work with Android .dex and Java .class files", isCask: false, category: "CLI Security"),
    Tool(name: "dns2tcp", description: "Tool for tunneling TCP over DNS", isCask: false, category: "CLI Security"),
    Tool(name: "dnsmap", description: "Subdomain brute-forcing tool", isCask: false, category: "CLI Security"),
    Tool(name: "dnstracer", description: "Trace a chain of DNS servers", isCask: false, category: "CLI Security"),
    Tool(name: "ettercap", description: "Multipurpose sniffer/interceptor/logger for switched LAN", isCask: false, category: "CLI Security"),
    Tool(name: "exiv2", description: "Image metadata manipulation tool", isCask: false, category: "CLI Security"),
    Tool(name: "exploitdb", description: "Archive of public exploits", isCask: false, category: "CLI Security"),
    Tool(name: "fcrackzip", description: "Zip password cracker", isCask: false, category: "CLI Security"),
    Tool(name: "foremost", description: "Console program to recover files based on headers and footers", isCask: false, category: "CLI Security"),
    Tool(name: "fping", description: "Scriptable ping program for multiple hosts", isCask: false, category: "CLI Security"),
    Tool(name: "fragroute", description: "Intercepts, modifies, and rewrites egress traffic", isCask: false, category: "CLI Security"),
    Tool(name: "freerdp", description: "Remote Desktop Protocol client", isCask: false, category: "CLI Security"),
    Tool(name: "gdb", description: "GNU debugger", isCask: false, category: "CLI Security"),
    Tool(name: "hashcat", description: "Advanced password recovery utility", isCask: false, category: "CLI Security"),
    Tool(name: "hping", description: "Command-line TCP/IP packet assembler/analyzer", isCask: false, category: "CLI Security"),
    Tool(name: "httrack", description: "Website copier", isCask: false, category: "CLI Security"),
    Tool(name: "hydra", description: "Network logon cracker", isCask: false, category: "CLI Security"),
    Tool(name: "ike-scan", description: "IKE protocol scanner", isCask: false, category: "CLI Security"),
    Tool(name: "john", description: "John the Ripper password cracker", isCask: false, category: "CLI Security"),
    Tool(name: "libewf", description: "Library for handling Expert Witness Compression Format", isCask: false, category: "CLI Security"),
    Tool(name: "libpst", description: "Library for reading PST files", isCask: false, category: "CLI Security"),
    Tool(name: "llvm", description: "Low Level Virtual Machine compiler system", isCask: false, category: "CLI Security"),
    Tool(name: "lynis", description: "Security auditing tool", isCask: false, category: "CLI Security"),
    Tool(name: "mac-robber", description: "Digital forensics tool for collecting data", isCask: false, category: "CLI Security"),
    Tool(name: "masscan", description: "Fast TCP port scanner", isCask: false, category: "CLI Security"),
    Tool(name: "md5deep", description: "Compute MD5 message digests", isCask: false, category: "CLI Security"),
    Tool(name: "mdbtools", description: "Tools for reading Microsoft Access databases", isCask: false, category: "CLI Security"),
    Tool(name: "mitmproxy", description: "Interactive HTTPS proxy", isCask: false, category: "CLI Security"),
    Tool(name: "nasm", description: "Netwide Assembler", isCask: false, category: "CLI Security"),
    Tool(name: "ncrack", description: "Network authentication cracking tool", isCask: false, category: "CLI Security"),
    Tool(name: "nikto", description: "Web server scanner", isCask: false, category: "CLI Security"),
    Tool(name: "nmap", description: "Port scanning utility", isCask: false, category: "CLI Security"),
    Tool(name: "ophcrack", description: "Windows password cracker", isCask: false, category: "CLI Security"),
    Tool(name: "p0f", description: "Passive OS fingerprinting tool", isCask: false, category: "CLI Security"),
    Tool(name: "p7zip", description: "7-Zip file archiver", isCask: false, category: "CLI Security"),
    Tool(name: "pdfcrack", description: "PDF password cracker", isCask: false, category: "CLI Security"),
    Tool(name: "pev", description: "PE file analyzer", isCask: false, category: "CLI Security"),
    Tool(name: "proxychains-ng", description: "Redirect connections through proxy servers", isCask: false, category: "CLI Security"),
    Tool(name: "proxytunnel", description: "Tunnel TCP connections through HTTPS proxies", isCask: false, category: "CLI Security"),
    Tool(name: "ptunnel", description: "Tunnel TCP connections over ICMP", isCask: false, category: "CLI Security"),
    Tool(name: "pwnat", description: "NAT traversal tool", isCask: false, category: "CLI Security"),
    Tool(name: "radare2", description: "Reverse engineering framework", isCask: false, category: "CLI Security"),
    Tool(name: "reaver", description: "Brute force attack against WPS", isCask: false, category: "CLI Security"),
    Tool(name: "recon-ng", description: "Web reconnaissance framework", isCask: false, category: "CLI Security"),
    Tool(name: "rkhunter", description: "Rootkit hunter", isCask: false, category: "CLI Security"),
    Tool(name: "siege", description: "HTTP load testing and benchmarking tool", isCask: false, category: "CLI Security"),
    Tool(name: "sipp", description: "SIP protocol test tool", isCask: false, category: "CLI Security"),
    Tool(name: "sipsak", description: "SIP swiss army knife", isCask: false, category: "CLI Security"),
    Tool(name: "sleuthkit", description: "Forensic toolkit", isCask: false, category: "CLI Security"),
    Tool(name: "slowhttptest", description: "Application layer DoS attack simulator", isCask: false, category: "CLI Security"),
    Tool(name: "smali", description: "Assembler/disassembler for Android's dex format", isCask: false, category: "CLI Security"),
    Tool(name: "sqlmap", description: "Automatic SQL injection tool", isCask: false, category: "CLI Security"),
    Tool(name: "ssdeep", description: "Fuzzy hashing tool", isCask: false, category: "CLI Security"),
    Tool(name: "ssldump", description: "SSLv3/TLS network protocol analyzer", isCask: false, category: "CLI Security"),
    Tool(name: "sslh", description: "SSL/SSH multiplexer", isCask: false, category: "CLI Security"),
    Tool(name: "sslscan", description: "Tests SSL/TLS services", isCask: false, category: "CLI Security"),
    Tool(name: "sslsplit", description: "Transparent SSL/TLS interception", isCask: false, category: "CLI Security"),
    Tool(name: "sslyze", description: "SSL configuration scanner", isCask: false, category: "CLI Security"),
    Tool(name: "stunnel", description: "SSL tunneling program", isCask: false, category: "CLI Security"),
    Tool(name: "swaks", description: "Swiss Army Knife for SMTP", isCask: false, category: "CLI Security"),
    Tool(name: "tcpdump", description: "Command-line packet analyzer", isCask: false, category: "CLI Security"),
    Tool(name: "tcpflow", description: "TCP flow recorder", isCask: false, category: "CLI Security"),
    Tool(name: "tcpreplay", description: "Replay network traffic", isCask: false, category: "CLI Security"),
    Tool(name: "theharvester", description: "Information gathering tool", isCask: false, category: "CLI Security"),
    Tool(name: "truecrack", description: "Password cracker for TrueCrypt volumes", isCask: false, category: "CLI Security"),
    Tool(name: "udptunnel", description: "Tunnel UDP packets over TCP", isCask: false, category: "CLI Security"),
    Tool(name: "util-linux", description: "Collection of Linux utilities", isCask: false, category: "CLI Security"),
    Tool(name: "volatility", description: "Memory forensics framework", isCask: false, category: "CLI Security"),
    Tool(name: "yara", description: "Malware identification and classification tool", isCask: false, category: "CLI Security"),
    Tool(name: "testssl", description: "Tool to check SSL/TLS configurations", isCask: false, category: "CLI Security"),
    Tool(name: "sshtrix", description: "SSH login cracker", isCask: false, category: "CLI Security"),
    Tool(name: "gobuster", description: "Directory/file & DNS busting tool", isCask: false, category: "CLI Security"),
    Tool(name: "pwntools", description: "CTF framework and exploit development library", isCask: false, category: "CLI Security"),
    Tool(name: "snort", description: "Network intrusion detection system", isCask: false, category: "CLI Security"),
    Tool(name: "osquery", description: "SQL-powered operating system instrumentation", isCask: false, category: "CLI Security"),
    Tool(name: "zeek", description: "Network security monitor", isCask: false, category: "CLI Security"),
    Tool(name: "cowpatty", description: "WPA2-PSK cracker", isCask: false, category: "CLI Security"),
    Tool(name: "amass", description: "In-depth attack surface mapping", isCask: false, category: "CLI Security"),
    Tool(name: "ffuf", description: "Fast web fuzzer", isCask: false, category: "CLI Security"),
    Tool(name: "dirsearch", description: "Web path scanner", isCask: false, category: "CLI Security"),
    Tool(name: "subfinder", description: "Subdomain discovery tool", isCask: false, category: "CLI Security"),
    Tool(name: "nuclei", description: "Fast vulnerability scanner", isCask: false, category: "CLI Security"),
    Tool(name: "trufflehog", description: "Searches for secrets in code", isCask: false, category: "CLI Security"),
    Tool(name: "semgrep", description: "Static analysis for security", isCask: false, category: "CLI Security"),
    Tool(name: "bandit", description: "Python static analysis for security", isCask: false, category: "CLI Security"),
    Tool(name: "wpscan", description: "WordPress vulnerability scanner", isCask: false, category: "CLI Security"),
    Tool(name: "whatweb", description: "Web technology identifier", isCask: false, category: "CLI Security"),
    Tool(name: "wafw00f", description: "Web application firewall detector", isCask: false, category: "CLI Security"),
    Tool(name: "netcat", description: "Networking utility for reading/writing via TCP/UDP", isCask: false, category: "CLI Security"),
    Tool(name: "socat", description: "Multipurpose relay for bidirectional data transfer", isCask: false, category: "CLI Security"),
    Tool(name: "feroxbuster", description: "Fast, recursive content discovery tool", isCask: false, category: "CLI Security"),
    Tool(name: "rustscan", description: "Modern, high-speed port scanner", isCask: false, category: "CLI Security"),
    Tool(name: "dnsrecon", description: "DNS enumeration tool", isCask: false, category: "CLI Security"),
    Tool(name: "impacket", description: "Collection of Python classes for working with network protocols", isCask: false, category: "CLI Security"),
    Tool(name: "responder", description: "LLMNR, NBT-NS, and MDNS poisoner", isCask: false, category: "CLI Security"),

    // GUI Security Tools
    Tool(name: "armitage", description: "Cyber attack management tool", isCask: true, category: "GUI Security"),
    Tool(name: "burp-suite", description: "Web vulnerability scanner", isCask: true, category: "GUI Security"),
    Tool(name: "cutter", description: "Reverse engineering platform", isCask: true, category: "GUI Security"),
    Tool(name: "jad", description: "Java decompiler", isCask: true, category: "GUI Security"),
    Tool(name: "jd-gui", description: "Java decompiler GUI", isCask: true, category: "GUI Security"),
    Tool(name: "maltego", description: "Open source intelligence and forensics tool", isCask: true, category: "GUI Security"),
    Tool(name: "metasploit", description: "Penetration testing framework", isCask: true, category: "GUI Security"),
    Tool(name: "wireshark", description: "Network protocol analyzer", isCask: true, category: "GUI Security"),
    Tool(name: "zenmap", description: "GUI for Nmap", isCask: true, category: "GUI Security"),
    Tool(name: "ghidra", description: "Software reverse engineering suite", isCask: true, category: "GUI Security"),
    Tool(name: "owasp-zap", description: "Web application security scanner", isCask: true, category: "GUI Security"),

    // CLI Programming Tools
    Tool(name: "python", description: "High-level programming language", isCask: false, category: "CLI Programming"),
    Tool(name: "ruby", description: "Dynamic, open-source programming language", isCask: false, category: "CLI Programming"),
    Tool(name: "go", description: "Statically typed, compiled programming language", isCask: false, category: "CLI Programming"),
    Tool(name: "node", description: "JavaScript runtime built on Chrome's V8 engine", isCask: false, category: "CLI Programming"),
    Tool(name: "rust", description: "Systems programming language", isCask: false, category: "CLI Programming"),
    Tool(name: "cmake", description: "Cross-platform build system", isCask: false, category: "CLI Programming"),
    Tool(name: "make", description: "Build automation tool", isCask: false, category: "CLI Programming"),
    Tool(name: "gcc", description: "GNU Compiler Collection", isCask: false, category: "CLI Programming"),
    Tool(name: "clang", description: "C, C++, and Objective-C compiler", isCask: false, category: "CLI Programming"),
    Tool(name: "git", description: "Version control system", isCask: false, category: "CLI Programming"),
    Tool(name: "git-lfs", description: "Git extension for versioning large files", isCask: false, category: "CLI Programming"),
    Tool(name: "maven", description: "Build automation tool for Java projects", isCask: false, category: "CLI Programming"),
    Tool(name: "gradle", description: "Build automation tool", isCask: false, category: "CLI Programming"),
    Tool(name: "ant", description: "Java library and command-line tool", isCask: false, category: "CLI Programming"),
    Tool(name: "sbt", description: "Build tool for Scala and Java projects", isCask: false, category: "CLI Programming"),
    Tool(name: "ninja", description: "Small build system", isCask: false, category: "CLI Programming"),
    Tool(name: "jq", description: "Command-line JSON processor", isCask: false, category: "CLI Programming"),
    Tool(name: "shellcheck", description: "Static analysis tool for shell scripts", isCask: false, category: "CLI Programming"),
    Tool(name: "shfmt", description: "Shell script formatter", isCask: false, category: "CLI Programming"),
    Tool(name: "bats-core", description: "Bash Automated Testing System", isCask: false, category: "CLI Programming"),
    Tool(name: "checkstyle", description: "Static code analysis tool for Java", isCask: false, category: "CLI Programming"),
    Tool(name: "hadolint", description: "Dockerfile linter", isCask: false, category: "CLI Programming"),
    Tool(name: "yamllint", description: "YAML linter", isCask: false, category: "CLI Programming"),
    Tool(name: "docker", description: "Containerization platform", isCask: false, category: "CLI Programming"),
    Tool(name: "kubectl", description: "Kubernetes command-line tool", isCask: false, category: "CLI Programming"),
    Tool(name: "terraform", description: "Infrastructure as code tool", isCask: false, category: "CLI Programming"),
    Tool(name: "ansible", description: "Automation tool", isCask: false, category: "CLI Programming"),
    Tool(name: "vagrant", description: "Development environment management tool", isCask: false, category: "CLI Programming"),
    Tool(name: "jenv", description: "Java environment manager", isCask: false, category: "CLI Programming"),
    Tool(name: "java", description: "Java Development Kit (JDK) and Runtime Environment (JRE)", isCask: false, category: "CLI Programming"),

    // GUI Programming Tools
    Tool(name: "pycharm-ce", description: "Python IDE", isCask: true, category: "GUI Programming"),
    Tool(name: "visual-studio-code", description: "Code editor", isCask: true, category: "GUI Programming"),
    Tool(name: "bbedit", description: "Text editor", isCask: true, category: "GUI Programming"),
    Tool(name: "sublime-text", description: "Text editor", isCask: true, category: "GUI Programming"),
    Tool(name: "intellij-idea-ce", description: "Java IDE", isCask: true, category: "GUI Programming"),
    Tool(name: "eclipse-ide", description: "Java IDE", isCask: true, category: "GUI Programming"),
    Tool(name: "netbeans", description: "Java IDE", isCask: true, category: "GUI Programming"),
    Tool(name: "android-studio", description: "Android development IDE", isCask: true, category: "GUI Programming"),
    Tool(name: "xcode", description: "Apple's IDE for macOS and iOS development", isCask: true, category: "GUI Programming"),
    Tool(name: "postman", description: "API development tool", isCask: true, category: "GUI Programming"),
    Tool(name: "dbeaver-community", description: "Database management tool", isCask: true, category: "GUI Programming"),
    Tool(name: "gitkraken", description: "Git GUI client", isCask: true, category: "GUI Programming"),

    // Virtualization Tools
    Tool(name: "utm", description: "Virtualization tool for macOS", isCask: true, category: "Virtualization"),
    Tool(name: "virtualbox", description: "Virtualization tool (Intel only)", isCask: true, category: "Virtualization"),

    // Networking Tools
    Tool(name: "openvpn", description: "Open-source VPN solution", isCask: false, category: "Networking"),
    Tool(name: "tor", description: "Anonymity network", isCask: false, category: "Networking"),

    // Miscellaneous Tools
    Tool(name: "htop", description: "Interactive process viewer", isCask: false, category: "Miscellaneous"),
    Tool(name: "tree", description: "Display directories as trees", isCask: false, category: "Miscellaneous"),
    Tool(name: "wget", description: "Non-interactive network downloader", isCask: false, category: "Miscellaneous"),
    Tool(name: "tmux", description: "Terminal multiplexer", isCask: false, category: "Miscellaneous")
]
// Preview for development
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}





