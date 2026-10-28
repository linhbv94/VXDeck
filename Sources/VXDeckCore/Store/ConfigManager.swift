import Foundation

public actor ConfigManager {
    public static let shared = ConfigManager()

    public private(set) var lastSavedRevision: Int = 0
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let customDirectoryURL: URL?

    public var configDirectoryURL: URL {
        if let custom = customDirectoryURL {
            return custom
        }
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("VXDeck", isDirectory: true)
    }

    private var configFileURL: URL {
        return configDirectoryURL.appendingPathComponent("deck_config.json", isDirectory: false)
    }

    private var backupFileURL: URL {
        return configDirectoryURL.appendingPathComponent("deck_config.json.bak", isDirectory: false)
    }

    public init(customDirectoryURL: URL? = nil) {
        self.customDirectoryURL = customDirectoryURL
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

        let mainFileExists = fileManager.fileExists(atPath: configFileURL.path)
        let backupFileExists = fileManager.fileExists(atPath: backupFileURL.path)

        // If neither primary nor backup exists, write default seed and return
        if !mainFileExists && !backupFileExists {
            let seed = DeckConfig.defaultSeed()
            saveConfigSync(seed, revision: 1)
            return seed
        }

        // Try loading from primary config file
        if mainFileExists {
            do {
                let data = try Data(contentsOf: configFileURL)
                let config = try decoder.decode(DeckConfig.self, from: data)
                try config.validate()
                return config
            } catch {
                print("[VXDeck] Corrupted primary config file detected: \(error)")
                handleCorruptConfigFile()
            }
        }

        // Try restoring from .bak if primary was missing or corrupt
        if backupFileExists {
            if let backupData = try? Data(contentsOf: backupFileURL),
               let backupConfig = try? decoder.decode(DeckConfig.self, from: backupData) {
                do {
                    try backupConfig.validate()
                    print("[VXDeck] Successfully restored config from backup file.")
                    saveConfigSync(backupConfig, revision: 1)
                    return backupConfig
                } catch {
                    print("[VXDeck] Backup file also corrupted/unsupported: \(error)")
                }
            }
        }

        // Fallback to default seed if both primary and backup failed
        print("[VXDeck] Both primary and backup config unavailable or invalid. Falling back to default seed.")
        let seed = DeckConfig.defaultSeed()
        saveConfigSync(seed, revision: 1)
        return seed
    }

    private func handleCorruptConfigFile() {
        guard fileManager.fileExists(atPath: configFileURL.path) else { return }
        let timestamp = Int(Date().timeIntervalSince1970)
        let corruptURL = configDirectoryURL.appendingPathComponent("deck_config.json.corrupt.\(timestamp)")
        try? fileManager.moveItem(at: configFileURL, to: corruptURL)
    }

    public func saveConfig(_ config: DeckConfig, revision: Int) throws {
        // Enforce monotonic revision check to guarantee newest snapshot wins
        if revision > 0 && revision < lastSavedRevision {
            print("[VXDeck] Discarding outdated save revision \(revision) < \(lastSavedRevision)")
            return
        }

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
            try fileHandle.synchronize()
            try fileHandle.close()
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

        lastSavedRevision = max(lastSavedRevision, revision)
    }

    private func saveConfigSync(_ config: DeckConfig, revision: Int) {
        do {
            try saveConfig(config, revision: revision)
        } catch {
            print("[VXDeck] Error saving config: \(error)")
        }
    }

    public func flush() {
        // Serial execution inside actor guarantees all prior saveConfig calls completed
    }
}
