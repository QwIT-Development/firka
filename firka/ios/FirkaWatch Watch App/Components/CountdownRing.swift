import SwiftUI

struct CountdownRing: View {
    let totalMinutes: Int
    let remainingMinutes: Int
    let label: String
    var size: CGFloat = 80
    var lineWidth: CGFloat = 8
    var displayOffset: Int = 0  // Add to displayed minutes (e.g., +1)

    private var clampedRemainingMinutes: Int {
        guard totalMinutes > 0 else { return 0 }
        return max(0, min(remainingMinutes, totalMinutes))
    }

    var progress: Double {
        guard totalMinutes > 0 else { return 0 }
        return Double(totalMinutes - clampedRemainingMinutes) / Double(totalMinutes)
    }

    var displayedMinutes: Int {
        max(0, remainingMinutes + displayOffset)
    }

    var ringColor: Color {
        if clampedRemainingMinutes < 5 { return .red }
        if clampedRemainingMinutes < 10 { return .yellow }
        return .green
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(white: 0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            VStack(spacing: 1) {
                Text("\(displayedMinutes)")
                    .font(size > 60 ? .title2 : .headline)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        CountdownRing(totalMinutes: 45, remainingMinutes: 30, label: "min")

        CountdownRing(totalMinutes: 45, remainingMinutes: 8, label: "min")

        CountdownRing(totalMinutes: 45, remainingMinutes: 3, label: "min")
    }
    .padding()
}
