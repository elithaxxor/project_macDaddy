# macOS Tool Installer

A beautiful, native macOS application that makes discovering, organizing, and installing security tools, programming environments, and utilities a seamless experience.

![Tool Installer Screenshot](screenshots/main_view.png)

## 🌟 Features

- **Category-Based Organization**: Browse tools organized into intuitive categories
- **Search Functionality**: Quickly find tools by name or description
- **Asynchronous Installation**: Install multiple tools without freezing the UI
- **Real-Time Feedback**: Track installation progress with visual indicators
- **Detailed Tool Information**: View comprehensive details about each tool
- **Intel/Apple Silicon Compatibility**: Automatic detection of your Mac's architecture
- **Clean, Native Interface**: Feels right at home on macOS

## 🛠 Installation

### Requirements
- macOS 12.0 or later
- Xcode 13.0 or later (for development)
- Homebrew (will be installed automatically if not present)

### Installing from Release
1. Download the latest release from the [Releases page](https://github.com/yourusername/tool-installer/releases)
2. Drag `Tool Installer.app` to your Applications folder
3. When opening for the first time, right-click and select "Open" to bypass Gatekeeper

### Building from Source
1. Clone this repository
   ```bash
   git clone https://github.com/yourusername/tool-installer.git
   cd tool-installer
   ```
2. Open the project in Xcode
   ```bash
   open ToolInstaller.xcodeproj
   ```
3. Build the project (⌘+B) and run (⌘+R)

## 💻 Usage

### Installing Tools
1. Browse categories in the sidebar or use the search bar to find tools
2. Select individual tools using the checkboxes, or prepare to install all tools in a category
3. Click "Install Selected" or "Install All" to begin the installation process
4. Watch the progress indicators as tools are installed
5. When complete, you're ready to use your new tools!

### Getting Tool Details
- Click on any tool name to view detailed information about it
- The detail view includes installation type, category, and comprehensive description

### Managing Installations
- Successfully installed tools are marked with a green checkmark
- Failed installations show a red exclamation mark (hover for error details)
- In-progress installations display a progress indicator

## 🏗 Architecture

This application is built with Swift and SwiftUI, using modern concurrency patterns:

- **Model**: Tool struct defines the core data structure
- **View**: SwiftUI views for presenting the interface
- **ViewModel**: InstallationManager class manages the asynchronous installation process
- **Utilities**: Shell script integration for executing Homebrew commands

Key technical features:
- Swift concurrency with async/await pattern
- ObservableObject for reactive UI updates
- Process handling for shell script execution
- Error handling with detailed error messages

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Adding New Tools**: Edit the `tools` array in `ContentView.swift`
2. **Improving UI**: Enhance the user interface and experience
3. **Bug Fixes**: Address issues in the installation process
4. **Documentation**: Improve this README or add code comments

Please follow these steps for contributing:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 Roadmap

Future improvements planned:
- Tool update checking and management
- User favorites and custom tool collections
- Installation history and logs
- Dependency visualization
- Export/import tool selections for team sharing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- [Homebrew](https://brew.sh/) - The missing package manager for macOS
- All the amazing tool creators who make these security and development tools available
- The SwiftUI community for inspiration and examples

---

We all face the challenge of setting up and maintaining our development environments. This tool aims to make that process a little more joyful and a lot less time-consuming. Happy installing!
