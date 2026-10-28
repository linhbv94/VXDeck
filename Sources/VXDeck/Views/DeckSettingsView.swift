import SwiftUI
import AppKit
import VXDeckCore

public struct DeckSettingsView: View {
    @EnvironmentObject var store: DeckStore
    let onClose: () -> Void

    @LocalState private var selectedTab = "general"
    @LocalState private var isCheckingUpdate = false
    @LocalState private var isApplyingUpdate = false
    @LocalState private var updateStatusMessage = "Chưa kiểm tra"
    @LocalState private var hasNewUpdate = false
    @LocalState private var latestReleaseURL: URL? = nil
    @LocalState private var latestDmgURL: URL? = nil
    @LocalState private var releaseNotes: String? = nil

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.3"
    }

    private var qrImage: NSImage? {
        if let bundleURL = Bundle.main.url(forResource: "qr", withExtension: "png"),
           let img = NSImage(contentsOf: bundleURL) {
            return img
        }
        let fallbackPath = NSString(string: "~/_Work/VXUtilities/_summary/qr.png").expandingTildeInPath
        return NSImage(contentsOfFile: fallbackPath)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("Cài Đặt & Giới Thiệu")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    Text("v\(currentVersion)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.18)))
                        .foregroundColor(.cyan)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.8))
                        .padding(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Color(red: 0.08, green: 0.09, blue: 0.13))
            .overlay(
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1),
                alignment: .bottom
            )

            // Body: Sidebar + Detail Content
            HStack(spacing: 0) {
                // Left Sidebar (170pt)
                VStack(alignment: .leading, spacing: 4) {
                    sidebarButton(id: "general", title: "Cài đặt chung", icon: "gearshape")
                    sidebarButton(id: "updates", title: "Cập nhật", icon: "arrow.triangle.2.circlepath", showDot: store.hasUpdateAvailable)

                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.vertical, 4)

                    sidebarButton(id: "about", title: "Giới thiệu", icon: "info.circle")
                    sidebarButton(id: "support", title: "Ủng hộ tác giả", icon: "cup.and.saucer.fill", isAmber: true)

                    Spacer()
                }
                .padding(10)
                .frame(width: 170)
                .background(Color(red: 0.065, green: 0.075, blue: 0.105))
                .overlay(
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1),
                    alignment: .trailing
                )

                // Right Content Area
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            if selectedTab == "general" {
                                generalTabContent
                            } else if selectedTab == "updates" {
                                updatesTabContent
                            } else if selectedTab == "about" {
                                aboutTabContent
                            } else if selectedTab == "support" {
                                supportTabContent
                            }
                        }
                        .padding(20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.059, green: 0.067, blue: 0.09))
            }

            // Footer
            HStack {
                Button("Khôi phục mặc định") {
                    store.resetSettingsToDefaults()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))

                Spacer()

                Button("Đóng") {
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Color(red: 0.08, green: 0.09, blue: 0.13))
            .overlay(
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1),
                alignment: .top
            )
        }
        .frame(width: 580, height: 420)
        .background(Color(red: 0.059, green: 0.067, blue: 0.09))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func sidebarButton(id: String, title: String, icon: String, isAmber: Bool = false, showDot: Bool = false) -> some View {
        let isSelected = selectedTab == id
        return Button(action: { selectedTab = id }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isAmber ? .orange : (isSelected ? .cyan : Color(red: 0.6, green: 0.65, blue: 0.72)))
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color(red: 0.75, green: 0.8, blue: 0.85))

                Spacer()

                if showDot {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - General Tab
    private var generalTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Cài Đặt Chung")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { store.settings.autoHideOnLaunch },
                    set: { store.updateSettings(autoHideOnLaunch: $0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tự động đóng popup sau khi mở app")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Khi bật, click mở 1 ứng dụng sẽ tự động đóng và thoát sạch popup.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                }
                .toggleStyle(.checkbox)

                Divider().background(Color.white.opacity(0.08))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Độ rộng cửa sổ (Popup Width)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Kéo viền mép trái hoặc phải của popup để tuỳ chỉnh độ rộng tự do. Số cột sẽ tự động dàn đều theo không gian hiển thị.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }

                    Spacer()

                    Text("\(Int(store.settings.windowWidth)) pt")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                }

                Divider().background(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tệp cấu hình dữ liệu")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)

                    Text("~/Library/Application Support/VXDeck/deck_config.json")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)))

                    Button("Hiện thư mục cấu hình trong Finder") {
                        let path = NSString(string: "~/Library/Application Support/VXDeck").expandingTildeInPath
                        let url = URL(fileURLWithPath: path)
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.link)
                }
            }
        }
    }

    // MARK: - Updates Tab
    private var updatesTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quản Lý Phiên Bản & Cập Nhật")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Phiên bản hiện tại:")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.8))
                    Text("v\(currentVersion)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }

                HStack {
                    Text("Kênh phát hành:")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.8))
                    Text("GitHub Releases (Stable)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }

                Divider().background(Color.white.opacity(0.08))

                if hasNewUpdate {
                    // Trạng thái: Phát hiện bản cập nhật mới
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cyan)
                                .font(.system(size: 13, weight: .bold))
                            Text(updateStatusMessage)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.cyan)
                        }

                        // Nút hành động chính 1-chạm (Full width, không wrap chữ)
                        Button(action: applyUpdateNow) {
                            HStack(spacing: 8) {
                                if isApplyingUpdate {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Đang tải & cài đặt bản cập nhật...")
                                        .font(.system(size: 12, weight: .semibold))
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Cập nhật & Khởi động lại ngay")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Color.cyan))
                            .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .disabled(isApplyingUpdate)

                        // Dòng hành động phụ: Kiểm tra lại + Xem trên GitHub
                        HStack {
                            Button(action: checkForUpdates) {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Kiểm tra lại")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.82))
                            }
                            .buttonStyle(.plain)
                            .disabled(isCheckingUpdate || isApplyingUpdate)

                            Spacer()

                            if let url = latestReleaseURL {
                                Button(action: {
                                    NSWorkspace.shared.open(url)
                                }) {
                                    HStack(spacing: 4) {
                                        Text("Xem chi tiết trên GitHub")
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.cyan)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.cyan.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.25), lineWidth: 1))
                } else {
                    // Trạng thái: Đang là bản mới nhất hoặc chưa kiểm tra
                    HStack(spacing: 12) {
                        Button(action: checkForUpdates) {
                            HStack(spacing: 6) {
                                if isCheckingUpdate {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(isCheckingUpdate ? "Đang kiểm tra..." : "Kiểm tra bản cập nhật")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(isCheckingUpdate)

                        if let url = latestReleaseURL {
                            Button(action: {
                                NSWorkspace.shared.open(url)
                            }) {
                                HStack(spacing: 4) {
                                    Text("Xem trên GitHub")
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.82))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green.opacity(0.8))
                            .font(.system(size: 11))
                        Text(updateStatusMessage)
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                    }
                }

                if let notes = releaseNotes, hasNewUpdate {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ghi chú phát hành:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.75, green: 0.8, blue: 0.85))

                        ScrollView(.vertical) {
                            Text(notes)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color(red: 0.8, green: 0.85, blue: 0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .frame(maxHeight: 110)
                        .background(Color.black.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func checkForUpdates() {
        isCheckingUpdate = true
        updateStatusMessage = "Đang kết nối kiểm tra bản phát hành..."
        releaseNotes = nil

        Task {
            // Kênh 1: Kiểm tra qua file latest.json (tránh triệt để rate limit của GitHub API)
            let latestJsonURL = URL(string: "https://github.com/linhbv94/VXDeck/releases/latest/download/latest.json")!
            var req = URLRequest(url: latestJsonURL)
            req.timeoutInterval = 7

            if let (data, response) = try? await URLSession.shared.data(for: req),
               let http = response as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let remoteVer = (json["version"] as? String) ?? (json["tag_name"] as? String)?.replacingOccurrences(of: "v", with: "") {

                await MainActor.run {
                    self.isCheckingUpdate = false
                    if DeckStore.isNewerVersion(remoteVer, than: self.currentVersion) {
                        self.hasNewUpdate = true
                        self.store.hasUpdateAvailable = true
                        self.updateStatusMessage = "Phát hiện bản phát hành mới: v\(remoteVer)!"
                        if let html = json["html_url"] as? String, let u = URL(string: html) {
                            self.latestReleaseURL = u
                        } else {
                            self.latestReleaseURL = URL(string: "https://github.com/linhbv94/VXDeck/releases/tag/v\(remoteVer)")
                        }
                        if let dmg = json["download_url"] as? String, let u = URL(string: dmg) {
                            self.latestDmgURL = u
                        } else {
                            self.latestDmgURL = URL(string: "https://github.com/linhbv94/VXDeck/releases/download/v\(remoteVer)/vxdeck_\(remoteVer)_macos_silicon.dmg")
                        }
                        self.releaseNotes = json["notes"] as? String
                    } else {
                        self.hasNewUpdate = false
                        self.store.hasUpdateAvailable = false
                        self.updateStatusMessage = "Bạn đang sử dụng phiên bản mới nhất (v\(self.currentVersion))."
                    }
                }
                return
            }

            // Kênh 2: Dự phòng kiểm tra qua GitHub Releases API
            guard let apiURL = URL(string: "https://api.github.com/repos/linhbv94/VXDeck/releases/latest") else {
                await MainActor.run {
                    self.isCheckingUpdate = false
                    self.updateStatusMessage = "URL kho lưu trữ không hợp lệ."
                }
                return
            }

            var apiReq = URLRequest(url: apiURL)
            apiReq.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            apiReq.setValue("VXDeck-App", forHTTPHeaderField: "User-Agent")
            apiReq.timeoutInterval = 8

            do {
                let (data, response) = try await URLSession.shared.data(for: apiReq)
                guard let http = response as? HTTPURLResponse else {
                    await MainActor.run {
                        self.isCheckingUpdate = false
                        self.updateStatusMessage = "Không nhận được phản hồi từ máy chủ."
                    }
                    return
                }

                if http.statusCode == 404 {
                    // Chưa có bản release nào
                    await MainActor.run {
                        self.isCheckingUpdate = false
                        self.hasNewUpdate = false
                        self.store.hasUpdateAvailable = false
                        self.updateStatusMessage = "Bạn đang sử dụng phiên bản mới nhất (v\(self.currentVersion))."
                    }
                    return
                }

                if http.statusCode == 403 {
                    // Bị rate limit bởi GitHub API
                    await MainActor.run {
                        self.isCheckingUpdate = false
                        self.updateStatusMessage = "Chạm giới hạn GitHub API. Bấm xem trực tiếp trên GitHub."
                        self.latestReleaseURL = URL(string: "https://github.com/linhbv94/VXDeck/releases")
                        self.hasNewUpdate = true
                    }
                    return
                }

                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    await MainActor.run {
                        self.isCheckingUpdate = false
                        self.hasNewUpdate = false
                        self.store.hasUpdateAvailable = false
                        self.updateStatusMessage = "Bạn đang sử dụng phiên bản mới nhất (v\(self.currentVersion))."
                    }
                    return
                }

                let cleanTag = tagName.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespaces)
                await MainActor.run {
                    self.isCheckingUpdate = false
                    if DeckStore.isNewerVersion(cleanTag, than: self.currentVersion) {
                        self.hasNewUpdate = true
                        self.store.hasUpdateAvailable = true
                        self.updateStatusMessage = "Phát hiện bản phát hành mới: \(tagName)!"
                        if let html = json["html_url"] as? String, let u = URL(string: html) {
                            self.latestReleaseURL = u
                        }
                        if let body = json["body"] as? String, !body.trimmingCharacters(in: .whitespaces).isEmpty {
                            self.releaseNotes = body
                        }
                        if let assets = json["assets"] as? [[String: Any]] {
                            for asset in assets {
                                if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                                   let downloadUrlStr = asset["browser_download_url"] as? String,
                                   let downloadUrl = URL(string: downloadUrlStr) {
                                    self.latestDmgURL = downloadUrl
                                    break
                                }
                            }
                        }
                    } else {
                        self.hasNewUpdate = false
                        self.store.hasUpdateAvailable = false
                        self.updateStatusMessage = "Bạn đang sử dụng phiên bản mới nhất (v\(self.currentVersion))."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isCheckingUpdate = false
                    self.updateStatusMessage = "Không thể kiểm tra cập nhật: \(error.localizedDescription)"
                }
            }
        }
    }

    private func applyUpdateNow() {
        guard let dmgURL = latestDmgURL else { return }
        isApplyingUpdate = true
        updateStatusMessage = "Đang tải gói cập nhật từ GitHub..."

        Task {
            do {
                let currentBundle = Bundle.main.bundleURL
                let targetURL = currentBundle.path.hasSuffix(".app") ? currentBundle : URL(fileURLWithPath: "/Applications/VXDeck.app")

                await MainActor.run {
                    self.updateStatusMessage = "Đang cài đặt và khởi động lại..."
                }

                try await AppUpdater.shared.applyUpdate(dmgURL: dmgURL, targetAppURL: targetURL)

                // Flush store state before exiting
                await DeckStore.shared.flush()
                await MainActor.run {
                    NSApp.terminate(nil)
                    exit(0)
                }
            } catch {
                await MainActor.run {
                    self.isApplyingUpdate = false
                    self.updateStatusMessage = "Lỗi cập nhật tự động: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - About Tab
    private var aboutTabContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 52, height: 52)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("VXDeck")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("v\(currentVersion)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }

                    Text("Bộ phóng ứng dụng nổi (Transient App Launcher) siêu nhẹ cho macOS.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.8))
                }
            }

            Divider().background(Color.white.opacity(0.08))

            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "Tác giả", value: "Bùi Việt Linh")
                infoRow(label: "Kiến trúc", value: "Apple Silicon (arm64) • Native Swift 6.0")
                infoRow(label: "Baseline SDK", value: "macOS SDK 27.0")
                infoRow(label: "Mã nguồn", value: "github.com/linhbv94/VXDeck")
            }

            Button("Xem kho lưu trữ trên GitHub") {
                if let url = URL(string: "https://github.com/linhbv94/VXDeck") {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(.system(size: 11, weight: .medium))
            .buttonStyle(.link)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
        }
    }

    // MARK: - Support Author Tab
    private var supportTabContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundColor(.orange)
                Text("Ủng Hộ Tác Giả")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
            }

            Text("Nếu bạn thấy VXDeck giúp trải nghiệm khởi chạy app trên macOS tiện lợi hơn, hãy gửi một ly cà phê ủng hộ tác giả nhé!")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.75, green: 0.8, blue: 0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            if let qr = qrImage {
                VStack(spacing: 6) {
                    Image(nsImage: qr)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)

                    Text("Quét VietQR từ bất kỳ ứng dụng ngân hàng nào")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
