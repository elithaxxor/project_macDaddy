
# Cleanup Utility for macOS

This SwiftUI application provides a graphical user interface (GUI) for the `cleanup.sh` script, which is designed to perform various system cleanup tasks on macOS. The GUI allows users to interact with the script through a simplified menu and view the script's output in real-time.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a24e3557-31dc-42d5-9f1d-1b3ae8d24306" alt="logo3" width="300"/>
</p>


```

## Features

- **Sidebar Menu**: A list of cleanup options matching the bash script.
- **Script Output View**: Displays the output of the bash script in real-time.
- **User Input Field**: Allows users to send input to the bash script interactively.
- **Process Management**: Manages the execution of the bash script and handles input/output pipes.

## Menu Options

The following cleanup tasks are available through the GUI:

1. System Information
2. Analyze Disk Usage
3. Clean User Cache
4. Clean Temporary Files
5. Clean Trash/Recycle Bin
6. Clean Logs
7. Wi-Fi Diagnostics
8. Clean Time Machine Snapshots (macOS-specific)
9. Clean macOS System Data (macOS-specific)
10. Clean Browser Caches (macOS-specific)
11. Clean Package Manager Caches (macOS-specific)
12. Clean Mail Attachments (macOS-specific)
13. Clean System Caches (macOS-specific)
14. Clean iMessage Attachments (macOS-specific)
15. Clean Quick Look Cache (macOS-specific)
16. Rebuild Spotlight Index (macOS-specific)
17. Clean System Update Files (macOS-specific)
0. Exit

## Usage

### Running the Application

1. Ensure that the `cleanup.sh` script is located in your app bundle or a known path.
2. Build and run the SwiftUI application.
3. Use the sidebar menu to select a cleanup task.
4. View the script's output in the main output view.
5. Provide any necessary input through the text field at the bottom of the window.

### Example

```swift
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
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

Created by [elithaxxor](https://github.com/elithaxxor).

## Contributing


## Contact

For any inquiries, please contact [elithaxxor](https://github.com/elithaxxor).
```
