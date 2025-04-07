import SwiftUI

struct ContentView: View {
    @State private var scriptOutput = ""
    @State private var userInput = ""
    
    // The Process and pipes to interact with the bash script
    @State private var process: Process?
    @State private var outputPipe = Pipe()
    @State private var inputPipe = Pipe()
    
    // List of menu options matching the bash script
    let menuOptions: [(number: String, title: String)] = [
        ("1", "System Information"),
        ("2", "Analyze Disk Usage"),
        ("3", "Clean User Cache"),
        ("4", "Clean Temporary Files"),
        ("5", "Clean Trash/Recycle Bin"),
        ("6", "Clean Logs"),
        ("7", "Wi-Fi Diagnostics"),
        // macOS-specific options:
        ("8", "Clean Time Machine Snapshots"),
        ("9", "Clean macOS System Data"),
        ("10", "Clean Browser Caches"),
        ("11", "Clean Package Manager Caches"),
        ("12", "Clean Mail Attachments"),
        ("13", "Clean System Caches"),
        ("14", "Clean iMessage Attachments"),
        ("15", "Clean Quick Look Cache"),
        ("16", "Rebuild Spotlight Index"),
        ("17", "Clean System Update Files"),
        ("0", "Exit")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar Menu
            List(menuOptions, id: \.number) { option in
                Button(action: {
                    sendInput(option.number + "\n")
                }) {
                    Text("\(option.number). \(option.title)")
                        .padding(4)
                }
            }
            .frame(width: 250)
            .listStyle(SidebarListStyle())
            
            Divider()
            
            // Main output view
            VStack {
                ScrollView {
                    Text(scriptOutput)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                .border(Color.gray)
                
                // Input field for interactive prompts
                HStack {
                    TextField("Type your input...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send") {
                        sendInput(userInput + "\n")
                        userInput = ""
                    }
                }
                .padding()
            }
        }
        .onAppear(perform: launchScript)
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // Launch the bash script as a Process
    func launchScript() {
        let bashPath = "/bin/bash"
        // Ensure the script file is in your app bundle or a known path:
        let scriptPath = Bundle.main.path(forResource: "cleanup", ofType: "sh") ?? "/path/to/cleanup.sh"
        
        process = Process()
        process?.executableURL = URL(fileURLWithPath: bashPath)
        process?.arguments = [scriptPath]
        
        // Connect standard output
        process?.standardOutput = outputPipe
        process?.standardError = outputPipe
        
        // Connect standard input
        process?.standardInput = inputPipe
        
        // Read the output asynchronously
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            if let line = String(data: fileHandle.availableData, encoding: .utf8), !line.isEmpty {
                DispatchQueue.main.async {
                    self.scriptOutput.append(line)
                }
            }
        }
        
        do {
            try process?.run()
        } catch {
            scriptOutput.append("Failed to launch script: \(error.localizedDescription)")
        }
    }
    
    // Send user input to the bash script
    func sendInput(_ input: String) {
        if let data = input.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
