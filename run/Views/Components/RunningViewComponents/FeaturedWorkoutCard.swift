import SwiftUI
import HealthKit



struct FeaturedWorkoutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FITNESS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CustomColors.Brand.primary)
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Training Run")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Starting 5km Run")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image("running_illustration") // You'll need to add this asset
                    .resizable()
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

#Preview {
    FeaturedWorkoutCard()
}