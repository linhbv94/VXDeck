import Foundation

public actor ConfigManager {
    public static let shared = ConfigManager()

    public private(set) var revision: Int = 0
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var configDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("VXDeck", isDirectory: true)
    }

    private var configFileURL: URL {
        return configDirectoryURL.appendingPathComponent("deck_config.json", isDirectory: false)
    }

    private var backupFileURL: URL {
        return configDirectoryURL.appendingPathComponent("deck_config.json.bak", isDirectory: false)
    }

    public init() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    private func ensureDirectoryExists() throws {
        if !fileManager.fileExists(atPath: configDirectoryURL.path) {
            try fileManager.createDirectory(
                at: configDirectoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o755]
            )
        }
    }

    public func loadConfig() -> DeckConfig {
        do {
            try ensureDirectoryExists()
        } catch {
            print("[VXDeck] Failed to create config directory: \(error)")
            return DeckConfig.defaultSeed()
        }

        let path = configFileURL.path
        if !fileManager.fileExists(atPath: path) {
            let seed = DeckConfig.defaultSeed()
            saveConfigSync(seed)
            return seed
        }

        do {
            let data = try Data(contentsOf: configFileURL)
            let config = try decoder.decode(DeckConfig.self, from: data)
            return config
        } catch {
            print("[VXDeck] Corrupted config file detected: \(error)")
            handleCorruptConfigFile()

            // Try restoring from .bak
            if fileManager.fileExists(atPath: backupFileURL.path) {
                if let backupData = try? Data(contentsOf: backupFileURL),
                   let backupConfig = try? decoder.decode(DeckConfig.self, from: backupData) {
                    print("[VXDeck] Successfully restored config from backup file.")
                    saveConfigSync(backupConfig)
                    return backupConfig
                }
            }

            let seed = DeckConfig.defaultSeed()
            saveConfigSync(seed)
            return seed
        }
    }

    private func handleCorruptConfigFile() {
        guard fileManager.fileExists(atPath: configFileURL.path) else { return }
        let timestamp = Int(Date().timeIntervalSince1970)
        let corruptURL = configDirectoryURL.appendingPathComponent("deck_config.json.corrupt.\(timestamp)")
        try? fileManager.moveItem(at: configFileURL, to: corruptURL)
    }

    public func saveConfig(_ config: DeckConfig) throws {
        try ensureDirectoryExists()
        var updated = config
        updated.updatedAt = Date()

        let data = try encoder.encode(updated)
        let tempFileName = ".deck_config.json.tmp.\(UUID().uuidString)"
        let tempURL = configDirectoryURL.appendingPathComponent(tempFileName)

        // Write to staging file
        try data.write(to: tempURL, options: .atomic)

        // Force fsync on descriptor
        if let fileHandle = try? FileHandle(forWritingTo: tempURL) {
            try? fileHandle.synchronize()
            try? fileHandle.close()
        }

        // Backup existing config if present
        if fileManager.fileExists(atPath: configFileURL.path) {
            _ = try? fileManager.removeItem(at: backupFileURL)
            _ = try? fileManager.copyItem(at: configFileURL, to: backupFileURL)
        }

        // Atomic replace / rename
        if fileManager.fileExists(atPath: configFileURL.path) {
            _ = try fileManager.replaceItemAt(configFileURL, withItemAt: tempURL)
        } else {
            try fileManager.moveItem(at: tempURL, to: configFileURL)
        }

        revision += 1
    }

    private func saveConfigSync(_ config: DeckConfig) {
        do {
            try saveConfig(config)
        } catch {
            print("[VXDeck] Error saving config: \(error)")
        }
    }

    /// Flush any pending write immediately.
    public func flush() {
        // Since calls in actor are serial and synchronous to the actor,
        // calling flush ensures all queued actor executions have completed.
    }
}
