#!/usr/bin/env swift
import Foundation

// MARK: - Config Models

struct Config: Codable {
    let workspaces: [Workspace]
    let defaults: Defaults?
}

struct Workspace: Codable {
    let name: String
    let id: String?  // Optional custom ID; defaults to slugified name
    let description: String?
    let bgColor: String?
    let textColor: String?
    let resolution: String?
    let width: Int?
    let height: Int?
}

struct Defaults: Codable {
    let bgColor: String?
    let textColor: String?
    let resolution: String?
}

// MARK: - Main

func main() -> Int32 {
    let args = Array(CommandLine.arguments.dropFirst())

    // Parse arguments
    var generateOnly = false
    var customWidth: Int?
    var customHeight: Int?

    var i = 0
    while i < args.count {
        let arg = args[i]
        switch arg {
        case "--generate-only":
            generateOnly = true
        case "--width":
            i += 1
            if i < args.count { customWidth = Int(args[i]) }
        case "--height":
            i += 1
            if i < args.count { customHeight = Int(args[i]) }
        case "-h", "--help":
            printUsage()
            return 0
        default:
            break
        }
        i += 1
    }

    // Read config
    let configPath = NSString(string: "~/.config/wallpapers/config.json").expandingTildeInPath
    guard FileManager.default.fileExists(atPath: configPath) else {
        fputs("Error: Config not found at \(configPath)\n", stderr)
        fputs("Run: mise run config:init\n", stderr)
        return 1
    }

    guard let configData = FileManager.default.contents(atPath: configPath) else {
        fputs("Error: Could not read config file\n", stderr)
        return 1
    }

    let config: Config
    do {
        config = try JSONDecoder().decode(Config.self, from: configData)
    } catch {
        fputs("Error: Invalid config JSON - \(error.localizedDescription)\n", stderr)
        return 1
    }

    if config.workspaces.isEmpty {
        fputs("Error: No workspaces defined in config\n", stderr)
        return 1
    }

    // Get script directory for calling generate.swift
    let scriptPath = CommandLine.arguments[0]
    let scriptDir = (scriptPath as NSString).deletingLastPathComponent
    let generateScript = (scriptDir as NSString).appendingPathComponent("generate.swift")

    // Generate wallpapers for each workspace
    var generatedFiles: [String] = []

    for (index, workspace) in config.workspaces.enumerated() {
        print("[\(index + 1)/\(config.workspaces.count)] Generating: \(workspace.name)")

        // Build arguments
        var genArgs = [generateScript, workspace.name]

        if let desc = workspace.description {
            genArgs += ["-d", desc]
        }

        // Colors (workspace -> defaults -> hardcoded)
        let bgColor = workspace.bgColor ?? config.defaults?.bgColor ?? "#000000"
        let textColor = workspace.textColor ?? config.defaults?.textColor ?? "#ffffff"
        genArgs += ["--bg-color", bgColor, "--text-color", textColor]

        // ID and index for filename
        if let id = workspace.id {
            genArgs += ["--id", id]
        }
        genArgs += ["--index", String(index + 1)]  // 1-based index

        // Resolution: CLI args > workspace > defaults
        if let w = customWidth, let h = customHeight {
            genArgs += ["--width", String(w), "--height", String(h)]
        } else if let w = workspace.width, let h = workspace.height {
            genArgs += ["--width", String(w), "--height", String(h)]
        } else if let res = workspace.resolution ?? config.defaults?.resolution {
            genArgs += ["-r", res]
        }
        // If no resolution specified, generate.swift will use its default (1080p)

        // Run generate.swift
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift"] + genArgs
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                fputs("Error generating wallpaper for '\(workspace.name)'\n", stderr)
                return 1
            }

            // Capture output (format: "Generated: path")
            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               output.hasPrefix("Generated: ") {
                let path = String(output.dropFirst("Generated: ".count))
                generatedFiles.append(path)
            }
        } catch {
            fputs("Error running generate.swift: \(error.localizedDescription)\n", stderr)
            return 1
        }
    }

    print("\nGenerated \(generatedFiles.count) wallpaper(s)")

    // Output mode indicator for the bash wrapper
    if generateOnly {
        print("MODE:generate-only")
    } else {
        print("MODE:apply")
        // Output the files in order for the bash script to apply
        for file in generatedFiles {
            print("FILE:\(file)")
        }
    }

    return 0
}

func printUsage() {
    print("""
    Usage: swift setup.swift [options]

    Options:
      --generate-only     Only generate wallpapers, don't apply to spaces
      --width <pixels>    Override width for all wallpapers
      --height <pixels>   Override height for all wallpapers
      -h, --help          Show this help

    Reads config from ~/.config/wallpapers/config.json
    """)
}

exit(main())
