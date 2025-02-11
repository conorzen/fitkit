import SwiftUI
import UIKit

struct AppIconGenerator: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.run")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(50)
                .frame(width: 1024, height: 1024)
                .foregroundColor(.blue)
                .background(.white)
            
            Button("Generate App Icons") {
                generateIcons()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    func generateIcons() {
        let sizes: [(name: String, size: CGFloat)] = [
            ("iPhone_20pt_2x", 40),
            ("iPhone_20pt_3x", 60),
            ("iPhone_29pt_2x", 58),
            ("iPhone_29pt_3x", 87),
            ("iPhone_40pt_2x", 80),
            ("iPhone_40pt_3x", 120),
            ("iPhone_60pt_2x", 120),
            ("iPhone_60pt_3x", 180),
            ("iPad_20pt_1x", 20),
            ("iPad_20pt_2x", 40),
            ("iPad_29pt_1x", 29),
            ("iPad_29pt_2x", 58),
            ("iPad_40pt_1x", 40),
            ("iPad_40pt_2x", 80),
            ("iPad_76pt_1x", 76),
            ("iPad_76pt_2x", 152),
            ("iPad_83.5pt_2x", 167),
            ("iOS_Marketing_1024pt_1x", 1024)
        ]
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 1024))
        let baseImage = renderer.image { context in
            // Fill background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
            
            // Draw the SF Symbol
            let config = UIImage.SymbolConfiguration(pointSize: 800, weight: .regular)
            let symbol = UIImage(systemName: "figure.run", withConfiguration: config)?
                .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            
            symbol?.draw(in: CGRect(x: 112, y: 112, width: 800, height: 800))
        }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appIconsPath = documentsPath.appendingPathComponent("AppIcons")
        
        try? fileManager.createDirectory(at: appIconsPath, withIntermediateDirectories: true)
        
        for (name, size) in sizes {
            let targetSize = CGSize(width: size, height: size)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            
            let resizedImage = renderer.image { _ in
                baseImage.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            
            if let imageData = resizedImage.pngData() {
                let filename = appIconsPath.appendingPathComponent("\(name).png")
                try? imageData.write(to: filename)
                print("Generated: \(filename.path)")
            }
        }
        
        print("Icons generated at: \(appIconsPath.path)")
    }
}

#Preview {
    AppIconGenerator()
} 