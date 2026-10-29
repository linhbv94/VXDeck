// VX Settings UI SwiftUI adapter v1.0.0 — presentation only, no app store/job ownership.
import SwiftUI
import AppKit

private let vxAccent = Color(red: 0.02, green: 0.71, blue: 0.83)
private let vxMuted = Color(red: 0.58, green: 0.64, blue: 0.72)
private let vxBorder = Color.white.opacity(0.1)
private let vxCard = Color.black.opacity(0.2)

public struct VXSettingsHeading: View {
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text.uppercased()).font(.system(size: 12, weight: .semibold))
            .tracking(0.6).foregroundStyle(vxAccent).frame(maxWidth: .infinity, alignment: .leading)
    }
}
public struct VXSettingsGeneral: View {
    let language: String
    let theme: String
    let themes: [String]
    let onTheme: (String) -> Void
    let onLanguage: (String) -> Void
    public init(language: String, theme: String, themes: [String], onTheme: @escaping (String)->Void, onLanguage: @escaping (String)->Void) {
        self.language=language; self.theme=theme; self.themes=themes; self.onTheme=onTheme; self.onLanguage=onLanguage
    }
    private func c(_ key: String) -> String { VXSettingsCopy.text(key, language: language) }
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                VXSettingsHeading(c("theme"))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(themes, id: \.self) { mode in
                        Button { onTheme(mode) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: theme == mode ? "largecircle.fill.circle" : "circle")
                                Text(c(mode)).font(.system(size: 12, weight: .medium))
                                Spacer(minLength: 0)
                            }.padding(10).foregroundStyle(theme == mode ? Color(red:0.65,green:0.95,blue:0.99) : Color.white.opacity(0.83))
                                .background(theme == mode ? vxAccent.opacity(0.2) : vxCard, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme == mode ? vxAccent : vxBorder))
                        }.buttonStyle(.plain).accessibilityLabel(c(mode)).accessibilityAddTraits(theme == mode ? .isSelected : [])
                    }
                }
            }
            Divider().overlay(vxBorder)
            VStack(alignment: .leading, spacing: 12) {
                VXSettingsHeading(c("language"))
                HStack(spacing: 24) {
                    ForEach(["vi", "en"], id: \.self) { code in
                        Button { onLanguage(code) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: language == code ? "largecircle.fill.circle" : "circle")
                                Text(code == "vi" ? "Tiếng Việt" : "English")
                            }
                        }.buttonStyle(.plain).accessibilityAddTraits(language == code ? .isSelected : [])
                    }
                }
            }
        }.font(.system(size: 12))
    }
}
private struct VXSettingsVersion: View {
    let value: String
    var body: some View {
        Text("v\(value)").font(.system(size:11,weight:.semibold,design:.monospaced))
            .padding(.horizontal,8).padding(.vertical,2).foregroundStyle(vxAccent)
            .background(vxAccent.opacity(0.2),in:Capsule()).overlay(Capsule().stroke(vxAccent.opacity(0.3)))
    }
}
private struct VXSettingsBanner<Content:View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content().padding(16).frame(maxWidth:.infinity,alignment:.leading)
            .background(LinearGradient(colors:[vxAccent.opacity(0.1),vxAccent.opacity(0.05),.clear],startPoint:.leading,endPoint:.trailing),in:RoundedRectangle(cornerRadius:16))
            .overlay(RoundedRectangle(cornerRadius:16).stroke(vxAccent.opacity(0.2)))
    }
}
public struct VXSettingsUpdates<Content: View>: View {
    let language: String
    let version: String
    @ViewBuilder let content: () -> Content
    public init(language: String, version: String, @ViewBuilder content: @escaping () -> Content) {self.language=language;self.version=version;self.content=content}
    public var body: some View {
        VStack(alignment:.leading,spacing:16) {
            VXSettingsBanner {
                HStack(spacing:12) {
                    VStack(alignment:.leading,spacing:4) {
                        Label(VXSettingsCopy.text("updates",language:language),systemImage:"sparkles").font(.system(size:14,weight:.bold))
                        Text(VXSettingsCopy.text("updateDescription",language:language)).font(.system(size:12)).foregroundStyle(vxMuted)
                    }
                    Spacer(minLength:0)
                    VXSettingsVersion(value:version)
                }
            }
            content()
        }
    }
}
public struct VXSettingsAbout: View {
    let language: String, appName: String, version: String, tagline: String, description: String, repository: URL, systemIcon: String
    public init(language: String, appName: String, version: String, tagline: String, description: String, repository: URL, systemIcon: String) {
        self.language=language;self.appName=appName;self.version=version;self.tagline=tagline;self.description=description;self.repository=repository;self.systemIcon=systemIcon
    }
    public var body: some View {
        VStack(alignment:.leading,spacing:16) {
            VXSettingsBanner {
                HStack(spacing:16) {
                    Image(systemName:systemIcon).font(.system(size:28)).foregroundStyle(.white).frame(width:56,height:56)
                        .background(LinearGradient(colors:[vxAccent,.blue],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:16))
                    VStack(alignment:.leading,spacing:4) {
                        HStack(spacing:8) {Text(appName).font(.system(size:16,weight:.bold));VXSettingsVersion(value:version)}
                        Text(tagline).foregroundStyle(vxMuted)
                        ViewThatFits(in:.horizontal) {
                            HStack(spacing:12) {Text("Bùi Việt Linh").fontWeight(.semibold);Text("•");repositoryLink}
                            VStack(alignment:.leading,spacing:4) {Text("Bùi Việt Linh").fontWeight(.semibold);repositoryLink}
                        }.foregroundStyle(vxAccent)
                    }
                }
            }
            VStack(alignment:.leading,spacing:8) {
                VXSettingsHeading(VXSettingsCopy.text("highlights",language:language))
                Text(description).lineSpacing(2)
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(vxCard,in:RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(Color.white.opacity(0.05)))
        }.font(.system(size:12))
    }
    private var repositoryLink: some View {Link(destination:repository) {Label(repository.absoluteString.replacingOccurrences(of:"https://",with:""),systemImage:"arrow.up.right.square").font(.system(size:11,design:.monospaced))}}
}
public struct VXSettingsSupport: View {
    let language: String
    let qrImage: NSImage?
    public init(language: String, qrImage: NSImage?) {self.language=language;self.qrImage=qrImage}
    private func c(_ key: String) -> String {VXSettingsCopy.text(key,language:language)}
    public var body: some View {
        VStack(alignment:.leading,spacing:16) {
            HStack(alignment:.top,spacing:14) {
                Image(systemName:"cup.and.saucer").font(.system(size:20)).foregroundStyle(.white).frame(width:40,height:40).background(Color.orange,in:RoundedRectangle(cornerRadius:12))
                VStack(alignment:.leading,spacing:4) {
                    HStack(spacing:6) {Text(c("supportTitle")).font(.system(size:14,weight:.bold));Image(systemName:"heart.fill").foregroundStyle(.pink)}
                    Text(c("supportNote")).lineSpacing(2).foregroundStyle(Color.white.opacity(0.83))
                }
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading)
                .background(LinearGradient(colors:[Color.orange.opacity(0.15),Color.orange.opacity(0.1),.clear],startPoint:.leading,endPoint:.trailing),in:RoundedRectangle(cornerRadius:16))
                .overlay(RoundedRectangle(cornerRadius:16).stroke(Color.orange.opacity(0.3)))
            VStack(spacing:16) {
                VStack(spacing:8) {
                    if let qrImage, qrImage.size.width > 0 {
                        Image(nsImage:qrImage).resizable().scaledToFit().frame(width:208,height:208 * qrImage.size.height / qrImage.size.width).accessibilityLabel(c("qrAlt"))
                    } else {Text(c("qrMissing")).foregroundStyle(.secondary).frame(width:208,height:208)}
                    Text("VietQR • Napas247").font(.system(size:11,weight:.semibold,design:.monospaced)).foregroundStyle(Color(red:0.02,green:0.37,blue:0.27))
                }.padding(12).background(.white,in:RoundedRectangle(cornerRadius:16))
                Text(c("supportHint")).foregroundStyle(vxMuted).multilineTextAlignment(.center).lineSpacing(2)
            }.padding(24).frame(maxWidth:.infinity).background(vxCard,in:RoundedRectangle(cornerRadius:16)).overlay(RoundedRectangle(cornerRadius:16).stroke(vxBorder))
        }.font(.system(size:12))
    }
}
