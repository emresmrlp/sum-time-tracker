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
        Color(red: 0.22, green: 0.45, blue: 0.31), // Forest green
        Color(red: 0.20, green: 0.43, blue: 0.60), // Blue
        Color(red: 0.44, green: 0.32, blue: 0.63), // Purple
        Color(red: 0.67, green: 0.30, blue: 0.28), // Terracotta
        Color(red: 0.61, green: 0.40, blue: 0.12), // Amber
        Color(red: 0.15, green: 0.47, blue: 0.48)  // Teal
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
