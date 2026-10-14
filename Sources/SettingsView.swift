import SwiftUI
import AppKit

private enum PreferencesStyle {
    static let background = Color(red: 0.969, green: 0.973, blue: 0.957)
    static let text = Color(red: 0.122, green: 0.208, blue: 0.165)
    static let secondary = Color(red: 0.42, green: 0.48, blue: 0.44)
    static let border = Color(red: 0.89, green: 0.92, blue: 0.88)
    static let colorNames = ["Orman yeşili", "Deniz mavisi", "Lavanta", "Kiremit", "Kehribar", "Petrol yeşili"]
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Ayarlar")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(PreferencesStyle.text)
                Text("Çalışma alanına küçük bir kişisel dokunuş.")
                    .font(.system(size: 14))
                    .foregroundColor(PreferencesStyle.secondary)
            }

            PreferencesCard {
                VStack(alignment: .leading, spacing: 20) {
                    preferencesHeading("Rengini seç", subtitle: "Sana en iyi gelen tonla çalış.", icon: "paintpalette")
                    AccentColorPicker(settings: settings)
                }
            }

            PreferencesCard {
                VStack(alignment: .leading, spacing: 20) {
                    preferencesHeading("Kayıtların burada", subtitle: "Çalışma geçmişin ve dışa aktardığın raporlar Mac’inde saklanır.", icon: "folder")
                    Text(settings.dataFolderPath)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(PreferencesStyle.text)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PreferencesStyle.background, in: RoundedRectangle(cornerRadius: 12))

                    HStack(alignment: .center, spacing: 18) {
                        Text("Kayıt bütünlüğünü korumak için kurulumda seçilen klasör kullanılır.")
                            .font(.system(size: 12))
                            .foregroundColor(PreferencesStyle.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Button {
                            NSWorkspace.shared.open(settings.dataFolderURL)
                        } label: {
                            Label("Finder’da aç", systemImage: "arrow.up.right.square")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(settings.currentAccentColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(settings.currentAccentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                    }
                }
            }

            PreferencesCard {
                VStack(alignment: .leading, spacing: 20) {
                    preferencesHeading("Senin ritmine uyum sağlar", subtitle: "Gün içinde bilmen gereken birkaç küçük detay.", icon: "sparkles")
                    helpfulRow(icon: "macwindow", title: "Pencereyi kapat, çalışmaya devam et", detail: "Pencere kapansa da aktif sayaç çalışır. Menü çubuğundan süreyi görebilir ve uygulamayı açabilirsin.")
                    Divider().overlay(PreferencesStyle.border)
                    helpfulRow(icon: "moon.zzz", title: "Mac uyuduğunda sayaç durur", detail: "Geri döndüğünde yeni bir odak oturumu başlatabilirsin.")
                    Divider().overlay(PreferencesStyle.border)
                    helpfulRow(icon: "calendar", title: "Takvimine göre raporlar", detail: "Haftalar Pazartesi–Pazar arasıdır. Aylık süreler ayın ilk gününden son gününe kadar hesaplanır.")
                }
            }

            Text("SUM TIME  ·  Bir seferde bir odak anı.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(PreferencesStyle.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .frame(maxWidth: 820, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PreferencesStyle.background)
    }

    private func preferencesHeading(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(settings.currentAccentColor)
                .frame(width: 40, height: 40)
                .background(settings.currentAccentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PreferencesStyle.text)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(PreferencesStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func helpfulRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(settings.currentAccentColor)
                .frame(width: 24, height: 22)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PreferencesStyle.text)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(PreferencesStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
    }
}

struct SetupView: View {
    @ObservedObject var settings: SettingsManager
    @State private var selectedFolderPath = ""
    @State private var pathError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                VStack(spacing: 13) {
                    Image(systemName: "timer")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(settings.currentAccentColor)
                        .frame(width: 80, height: 80)
                        .background(settings.currentAccentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 25))
                    Text("Zamanına yer aç.")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(PreferencesStyle.text)
                    Text("SUM TIME ile çalışmaya odaklan, gününün ritmini keşfet.\nBaşlamak için birkaç küçük dokunuş yeterli.")
                        .font(.system(size: 14))
                        .foregroundColor(PreferencesStyle.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                PreferencesCard {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("Sana ait bir renk")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(PreferencesStyle.text)
                            AccentColorPicker(settings: settings)
                        }

                        Divider().overlay(PreferencesStyle.border)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kayıtların için bir yer")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(PreferencesStyle.text)
                            Text("Önerilen klasör hazır. İstersen başlamadan önce başka bir klasör seçebilirsin.")
                                .font(.system(size: 12))
                                .foregroundColor(PreferencesStyle.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .foregroundColor(settings.currentAccentColor)
                                Text(selectedFolderPath)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(PreferencesStyle.text)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                    .help(selectedFolderPath)
                                Spacer(minLength: 0)
                                Button("Klasör seç", action: chooseFolder)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(settings.currentAccentColor)
                                    .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(PreferencesStyle.background, in: RoundedRectangle(cornerRadius: 12))

                            if let pathError {
                                Label(pathError, systemImage: "exclamationmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                VStack(spacing: 12) {
                    Button(action: finishSetup) {
                        HStack(spacing: 10) {
                            Text("Çalışma alanını aç")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pathError == nil ? settings.currentAccentColor : PreferencesStyle.secondary, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    .disabled(pathError != nil || selectedFolderPath.isEmpty)

                    Label("Verilerin bu Mac’te saklanır.", systemImage: "lock.shield")
                        .font(.system(size: 12))
                        .foregroundColor(PreferencesStyle.secondary)
                }
            }
            .frame(maxWidth: 560)
            .padding(40)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PreferencesStyle.background)
        .onAppear {
            // The stored default creates its directory lazily before it is validated.
            selectedFolderPath = settings.dataFolderURL.path
            validateSelection()
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "SUM TIME kayıt klasörü"
        panel.message = "Çalışma kayıtlarının saklanacağı klasörü seç."
        panel.prompt = "Bu klasörü kullan"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: selectedFolderPath, isDirectory: true)
        if panel.runModal() == .OK, let url = panel.url {
            selectedFolderPath = url.path
            validateSelection()
        }
    }

    private func validateSelection() {
        var isDirectory: ObjCBool = false
        let manager = FileManager.default
        if selectedFolderPath.isEmpty || !manager.fileExists(atPath: selectedFolderPath, isDirectory: &isDirectory) || !isDirectory.boolValue {
            pathError = "Kayıtlar için mevcut bir klasör seç."
        } else if !manager.isWritableFile(atPath: selectedFolderPath) {
            pathError = "Bu klasöre yazılamıyor. Yazma iznin olan başka bir klasör seç."
        } else {
            pathError = nil
            let dataURL = URL(fileURLWithPath: selectedFolderPath).appendingPathComponent("data.json")
            if manager.fileExists(atPath: dataURL.path) {
                guard let data = try? Data(contentsOf: dataURL) else {
                    pathError = "Bu klasördeki mevcut kayıtlar okunamıyor. Başka bir klasör seç."
                    return
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if (try? decoder.decode([TimeSession].self, from: data)) == nil &&
                    (try? JSONDecoder().decode([TimeSession].self, from: data)) == nil {
                    pathError = "Bu klasördeki kayıt dosyası geçerli değil. Kayıtlarını korumak için başka bir klasör seç."
                }
            }
        }
    }

    private func finishSetup() {
        validateSelection()
        guard pathError == nil else { return }
        settings.dataFolderPath = selectedFolderPath
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.hasCompletedSetup = true
        }
    }
}

private struct AccentColorPicker: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        HStack(spacing: 15) {
            ForEach(settings.colorPalette.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        settings.accentColorIndex = index
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(settings.colorPalette[index])
                            .frame(width: 32, height: 32)
                        if settings.accentColorIndex == index {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(settings.accentColorIndex == index ? settings.colorPalette[index] : .clear, lineWidth: 1.5))
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(PreferencesStyle.colorNames[index])
                .accessibilityLabel(PreferencesStyle.colorNames[index])
                .accessibilityAddTraits(settings.accentColorIndex == index ? .isSelected : [])
            }
        }
    }
}

private struct PreferencesCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(PreferencesStyle.border.opacity(0.7), lineWidth: 1))
    }
}
