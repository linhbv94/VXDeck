import Foundation
import CryptoKit
import VXDeckCore

enum UpdateSecurityTests {
    static func run() throws {
        let key = Curve25519.Signing.PrivateKey()
        let publicKey = key.publicKey.rawRepresentation.base64EncodedString()
        let entry: [String: Any] = ["url": "https://github.com/linhbv94/VXDeck/releases/download/v2.0.0/vxdeck_2.0.0_macos_silicon.dmg", "size": 4, "sha256": String(repeating: "a", count: 64)]
        var payload: [String: Any] = ["app_id": "com.ztools.vxdeck", "version": "2.0.0", "platforms": ["macos_silicon": entry]]
        func envelope(_ payload: [String: Any]) throws -> Data {
            let bytes = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys, .withoutEscapingSlashes])
            return try JSONSerialization.data(withJSONObject: ["signed_payload": bytes.base64EncodedString(), "signature": key.signature(for: bytes).base64EncodedString()])
        }
        let good = try envelope(payload)
        let verified = try DeckUpdateValidation.verify(good, publicKey: publicKey, platform: "macos_silicon")
        let newer = try DeckUpdateValidation.newer("1.0.10", than: "1.0.9")
        let older = try DeckUpdateValidation.newer("1.0.9", than: "1.0.10")
        assert(verified.version == "2.0.0" && newer && !older)
        func rejected(_ check: () throws -> Void) {
            do { try check(); fatalError("Unsafe update accepted") } catch { }
        }
        rejected { _ = try DeckUpdateValidation.verify(good, publicKey: Curve25519.Signing.PrivateKey().publicKey.rawRepresentation.base64EncodedString(), platform: "macos_silicon") }
        rejected { _ = try DeckUpdateValidation.verify(good, publicKey: publicKey, platform: "macos_intel") }
        rejected { _ = try DeckUpdateValidation.verify(Data("{}".utf8), publicKey: publicKey, platform: "macos_silicon") }
        for version in ["2.0.0-beta.1", "2..0", "v2.0.0", "02.0.0"] {
            rejected { _ = try DeckUpdateValidation.version(version) }
        }
        payload["app_id"] = "other.app"
        rejected { _ = try DeckUpdateValidation.verify(envelope(payload), publicKey: publicKey, platform: "macos_silicon") }
        payload["app_id"] = "com.ztools.vxdeck"
        var malicious = entry; malicious["url"] = "https://example.invalid/app.dmg"
        payload["platforms"] = ["macos_silicon": malicious]
        rejected { _ = try DeckUpdateValidation.verify(envelope(payload), publicKey: publicKey, platform: "macos_silicon") }
        var tampered = try JSONSerialization.jsonObject(with: good) as! [String: String]
        tampered["signed_payload"] = Data("tampered bytes".utf8).base64EncodedString()
        rejected { _ = try DeckUpdateValidation.verify(JSONSerialization.data(withJSONObject: tampered), publicKey: publicKey, platform: "macos_silicon") }
        assert(AppUpdater.helperScript.contains("helper_ready"))
        assert(AppUpdater.helperScript.contains("parent_exit_timeout"))
        assert(AppUpdater.helperScript.contains("install_failed_rolled_back"))
        assert(!AppUpdater.helperScript.contains("rm -rf"))
        if let fixturePath = ProcessInfo.processInfo.environment["VXDECK_TEST_MANIFEST"],
           let publicKey = ProcessInfo.processInfo.environment["VXDECK_TEST_PUBLIC_KEY"] {
            let data = try Data(contentsOf: URL(fileURLWithPath: fixturePath))
            let verified = try DeckUpdateValidation.verify(data, publicKey: publicKey, platform: "macos_silicon")
            assert(verified.version == "9.9.9")
            print("  ✓ Python signer → Swift CryptoKit verifier interoperability: PASS")
        }
        print("  ✓ signed manifest/tamper/wrong key/URL/arch/identity/stable version: PASS")
    }
}
