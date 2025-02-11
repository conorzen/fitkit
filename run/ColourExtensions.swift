//
//  ColourExtensions.swift
//  run
//
//  Created by Conor Reid Admin on 10/02/2025.
//

import SwiftUI

extension Color {
    static let customColors = CustomColors()
    
    // Add semantic naming for common use cases
    static let primaryBackground = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    
    // Add dynamic colors that adapt to light/dark mode
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
}

struct CustomColors {
    // Group colors by purpose
    struct Brand {
        static let primary = Color(hex: "8B5CF6")    // purple
        static let secondary = Color(hex: "3B82F6")   // blue
        static let accent = Color(hex: "10B981")      // emerald
    }
    
    struct Semantic {
        static let success = Color(hex: "10B981")     // emerald
        static let warning = Color(hex: "F97316")     // orange
        static let error = Color(hex: "EF4444")       // red
        static let info = Color(hex: "3B82F6")        // blue
    }
    
    struct Gradient {
        static let primary = [Brand.primary, Brand.secondary]
        static let accent = [Brand.accent, Brand.secondary]
        static let warning = [Semantic.warning, Semantic.error]
    }
    
    // System adaptable colors
    let background = Color(uiColor: .systemBackground)
    let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    let gray100 = Color(uiColor: .systemGray6)
    
    // Keep existing color definitions but organize them better
    let purple = Brand.primary
    let blue = Brand.secondary
    let emerald = Semantic.success
    let pink = Color(hex: "EC4899")    // Deep pink
    let rose = Color(hex: "F43F5E")    // Vibrant rose
    let orange = Color(hex: "F97316")  // Bright orange
    let red = Color(hex: "EF4444")     // Vivid red
    let teal = Color(hex: "14B8A6")    // Deep teal
    let violet = Color(hex: "8B5CF6")  // Rich violet
    let indigo = Color(hex: "6366F1")  // Deep indigo
}

// Add convenience initializers for color
extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity * Double(a) / 255
        )
    }
}
