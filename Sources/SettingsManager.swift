import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var hasCompletedSetup: Bool {
        didSet { UserDefaults.standard.set(hasCompletedSetup, forKey: "hasCompletedSetup") }
    }
    
    @Published var dataFolderPath: String {
        didSet { UserDefaults.standard.set(dataFolderPath, forKey: "dataFolderPath") }
    }
    
    @Published var accentColorIndex: Int {
        didSet { UserDefaults.standard.set(accentColorIndex, forKey: "accentColorIndex") }
    }
    
    let colorPalette: [Color] = [
        Color(red: 0.16, green: 0.65, blue: 0.35), // Green
        Color(red: 0.16, green: 0.50, blue: 0.85), // Blue
        Color(red: 0.55, green: 0.35, blue: 0.85), // Purple
        Color(red: 0.85, green: 0.35, blue: 0.35), // Red
        Color(red: 0.85, green: 0.55, blue: 0.15), // Orange
        Color(red: 0.35, green: 0.75, blue: 0.85)  // Cyan
    ]
    
    var currentAccentColor: Color {
        if accentColorIndex >= 0 && accentColorIndex < colorPalette.count {
            return colorPalette[accentColorIndex]
        }
        return colorPalette[0]
    }
    
    init() {
        self.hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        self.accentColorIndex = UserDefaults.standard.integer(forKey: "accentColorIndex")
        
        let savedPath = UserDefaults.standard.string(forKey: "dataFolderPath")
        if let savedPath = savedPath, !savedPath.isEmpty {
            self.dataFolderPath = savedPath
        } else {
            let defaultPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("sum-time-tracker-data").path
            self.dataFolderPath = defaultPath
        }
    }
    
    var dataFolderURL: URL {
        let url = URL(fileURLWithPath: dataFolderPath)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }
}
