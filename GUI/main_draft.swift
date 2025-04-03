import SwiftUI

// Define a Tool struct to hold tool data
struct Tool: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let isCask: Bool // True for GUI tools installed with `brew install --cask`
    let category: String
}

// Sample tool list (replace with your Bash script's tools)
let tools = [
    Tool(name: "nmap", description: "Network exploration tool", isCask: false, category: "CLI Security"),
    Tool(name: "wireshark", description: "Network protocol analyzer", isCask: true, category: "GUI Security"),
    Tool(name: "python", description: "Programming language", isCask: false, category: "CLI Programming"),
    Tool(name: "pycharm-ce", description: "Python IDE", isCask: true, category: "GUI Programming"),
    Tool(name: "utm", description: "Virtualization tool", isCask: true, category: "Virtualization"),
    Tool(name: "virtualbox", description: "Virtualization tool (Intel only)", isCask: true, category: "Virtualization")
]

// Main content view with sidebar navigation
struct ContentView: View {
    @State private var selectedTools = Set<UUID>()
    @State private var selectedCategory = "CLI Security"
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            // Sidebar with categories
            List {
                Section(header: Text("Categories")) {
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(destination: ToolListView(tools: filteredTools(category: category), selectedTools: $selectedTools)) {
                            Text(category)
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())

            // Default view: Tool list for the selected category
            ToolListView(tools: filteredTools(category: selectedCategory), selectedTools: $selectedTools)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: installSelected) {
                    Text("Install Selected")
                }
            }
            ToolbarItem(placement: .navigation) {
                Button(action: installAll) {
                    Text("Install All")
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Installation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    // Computed properties and functions
    private var categories: [String] {
        Array(Set(tools.map { $0.category }))
    }

    private func filteredTools(category: String) -> [Tool] {
        tools.filter { $0.category == category }
    }

    private func installSelected() {
        let selected = tools.filter { selectedTools.contains($0.id) }
        installTools(selected)
    }

    private func installAll() {
        installTools(tools)
    }

    private func installTools(_ toolsToInstall: [Tool]) {
        for tool in toolsToInstall {
            let command = tool.isCask ? "brew install --cask \(tool.name)" : "brew install \(tool.name)"
            // Special condition for VirtualBox (Intel-only)
            if tool.name == "virtualbox" && !isIntel() {
                alertMessage = "VirtualBox is not fully supported on Apple Silicon. Skipping."
                showingAlert = true
                continue
            }
            runCommand(command)
        }
    }

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

    private func runCommand(_ command: String) {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]
        process.launch()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            alertMessage = "Installed \(command.split(separator: " ").last ?? "") successfully."
        } else {
            alertMessage = "Failed to install \(command.split(separator: " ").last ?? "")."
        }
        showingAlert = true
    }
}

// View for displaying and selecting tools
struct ToolListView: View {
    let tools: [Tool]
    @Binding var selectedTools: Set<UUID>

    var body: some View {
        List {
            ForEach(tools) { tool in
                HStack {
                    // Icon to indicate CLI or GUI tool
                    if tool.isCask {
                        Image(systemName: "display")
                    } else {
                        Image(systemName: "terminal")
                    }
                    VStack(alignment: .leading) {
                        Text(tool.name)
                            .font(.headline)
                        Text(tool.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    // Toggle for selection, disabled for VirtualBox on Apple Silicon
                    if tool.category != "Virtualization" || (tool.name != "virtualbox" || isIntel()) {
                        Toggle("", isOn: Binding(
                            get: { selectedTools.contains(tool.id) },
                            set: { if $0 { selectedTools.insert(tool.id) } else { selectedTools.remove(tool.id) } }
                        ))
                        .labelsHidden()
                    }
                }
            }
        }
        .navigationTitle("Install Tools")
    }

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

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
