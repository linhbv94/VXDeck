import SwiftUI
import AppKit
import VXDeckCore

public struct DeckSettingsView: View {
    @EnvironmentObject var store: DeckStore
    @ObservedObject private var updater = AppUpdateController.shared
    let onClose: () -> Void
    @LocalState private var selectedTab = "general"
    private var vi: Bool { store.settings.language != "en" }
    private func t(_ vi: String, _ en: String) -> String { self.vi ? vi : en }
    private var currentVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("VXDeck Settings").font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: onClose) { Image(systemName: "xmark") }.buttonStyle(.plain).keyboardShortcut(.cancelAction).help(t("Đóng", "Close"))
            }.padding(.horizontal, 20).frame(height: 56)
            Divider()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    tab("general", t("Chung", "General"), "slider.horizontal.3")
                    tab("popup", t("Cửa sổ & khởi chạy", "Window & launch"), "rectangle")
                    Divider().padding(.vertical, 8)
                    tab("updates", t("Cập nhật", "Updates"), "arrow.triangle.2.circlepath")
                    tab("about", t("Giới thiệu", "About"), "info.circle")
                    tab("support", VXSettingsCopy.text("support", language: store.settings.language), "cup.and.saucer")
                    Spacer()
                }.padding(12).frame(width: 192)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if selectedTab == "general" {
                            VXSettingsGeneral(language: store.settings.language, theme: "dark", themes: ["dark"], onTheme: { _ in }, onLanguage: { store.updateSettings(language: $0) })
                        } else if selectedTab == "popup" {
                            section(t("Cửa sổ & khởi chạy", "Window & launch"))
                            Toggle(t("Ẩn popup sau khi mở ứng dụng", "Hide popup after launching an app"), isOn: Binding(get: {store.settings.autoHideOnLaunch}, set: {store.updateSettings(autoHideOnLaunch: $0)})).toggleStyle(.checkbox)
                            Text(t("Kéo cạnh cửa sổ để thay đổi chiều rộng.", "Drag a window edge to change its width.")).foregroundStyle(.secondary)
                            Text("\(Int(store.settings.windowWidth)) pt").monospaced()
                            Button(t("Hiện thư mục cấu hình", "Reveal configuration folder")) {
                                let path = NSString(string: "~/Library/Application Support/VXDeck").expandingTildeInPath
                                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                            }
                        } else if selectedTab == "updates" {
                            VXSettingsUpdates(language: store.settings.language, version: currentVersion) { DeckUpdateCard(notice: false).environmentObject(store) }
                        } else if selectedTab == "about" {
                            VXSettingsAbout(language: store.settings.language, appName: "VXDeck", version: currentVersion,
                                tagline: t("Bộ sưu tập ứng dụng cá nhân", "Personal application collections"),
                                description: t("Sắp xếp ứng dụng thành bộ sưu tập và mở nhanh từ một popup gọn nhẹ. Click ra ngoài để ẩn, mở lại để tiếp tục.", "Organize applications into collections and launch them from a lightweight popup. Click outside to hide it and reopen to continue."),
                                repository: URL(string: "https://github.com/linhbv94/VXDeck")!, systemIcon: "square.grid.2x2")
                        } else {
                            VXSettingsSupport(language: store.settings.language, qrImage: Bundle.main.url(forResource: "qr", withExtension: "png").flatMap { NSImage(contentsOf: $0) })
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()
            HStack {
                Button(VXSettingsCopy.text("reset", language: store.settings.language)) { store.resetSettingsToDefaults() }.buttonStyle(.plain)
                Spacer()
                Button(t("Đóng", "Close"), action: onClose).buttonStyle(.borderedProminent).tint(.cyan)
            }.padding(.horizontal, 20).frame(height: 56)
        }.font(.system(size: 12)).foregroundStyle(.white).frame(width: 668, height: 500)
        .background(Color(red: 0.078, green: 0.094, blue: 0.129))
        .clipShape(RoundedRectangle(cornerRadius: 16)).onAppear { updater.start() }
    }
    private func section(_ text: String) -> some View { Text(text.uppercased()).font(.system(size: 12, weight: .semibold)).foregroundStyle(.cyan) }
    private func tab(_ id: String, _ title: String, _ icon: String) -> some View {
        Button { selectedTab = id } label: { Label(title, systemImage: icon).frame(maxWidth: .infinity, alignment: .leading).padding(10).background(selectedTab == id ? Color.cyan.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 8)) }.buttonStyle(.plain)
    }
    private func languageButton(_ code: String, _ name: String) -> some View {
        Button { store.updateSettings(language: code) } label: { Label(name, systemImage: store.settings.language == code ? "largecircle.fill.circle" : "circle") }.buttonStyle(.plain)
    }
}

struct DeckUpdateCard: View {
    @EnvironmentObject var store: DeckStore
    @ObservedObject private var updater = AppUpdateController.shared
    let notice: Bool
    private var vi: Bool { store.settings.language != "en" }
    private func t(_ vi: String, _ en: String) -> String { self.vi ? vi : en }
    private var busy: Bool { ["checking", "downloading", "verifying", "installing", "handed_off"].contains(updater.status) }
    private var message: String {
        switch updater.status {
        case "checking": return t("Đang kiểm tra cập nhật…", "Checking for updates…")
        case "available": return t("Có phiên bản mới", "Update available") + " v\(updater.version ?? "")"
        case "downloading": return t("Đang tải cập nhật", "Downloading update") + (updater.progress.map { " \(Int($0))%" } ?? "…")
        case "verifying": return t("Đang xác minh…", "Verifying…")
        case "installing", "handed_off": return t("Đang cài và khởi động lại…", "Installing and restarting…")
        case "current": return t("Bạn đang dùng phiên bản mới nhất.", "You are up to date.")
        case "error": return t("Cập nhật chưa hoàn tất. Hãy thử lại.", "Update failed. Please try again.")
        case "disabled": return t("Cập nhật khả dụng trong bản đã cài.", "Updates are available in installed builds.")
        default: return t("Kiểm tra phiên bản mới.", "Check for a new version.")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text(message); Spacer(); if notice && !busy { Button("×") {updater.dismiss()}.buttonStyle(.plain).help(t("Để sau", "Later")) } }
            if let error = updater.error { DisclosureGroup(t("Chi tiết lỗi", "Error details")) {Text(error).textSelection(.enabled)} }
            if updater.status != "disabled" {
                Button(updater.status == "available" ? t("Cập nhật & khởi động lại", "Update & restart") : t("Kiểm tra cập nhật", "Check for updates")) {
                    Task { if updater.status == "available" { await updater.install(prepare: { try await store.flushForUpdate() }) } else { await updater.check() } }
                }.buttonStyle(.borderedProminent).tint(.cyan).disabled(busy)
            }
        }.font(.system(size: 12)).padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color(red: 0.08, green: 0.09, blue: 0.13), in: RoundedRectangle(cornerRadius: 12)).onAppear {updater.start()}
    }
}
