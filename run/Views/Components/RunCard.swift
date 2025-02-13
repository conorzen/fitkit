 import SwiftUI

 struct RunCard: View {
    let run: RunItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(run.title)
                    .font(.headline)
                Text(run.date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(run.distance)
                    .font(.headline)
                Text(run.duration)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: run.gradient),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 4)
                .clipped(),
            alignment: .leading
        )
    }
}