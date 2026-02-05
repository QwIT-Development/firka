import SwiftUI

struct GradeRow: View {
    let grade: WidgetGrade

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(grade.displayValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(grade.gradeColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                if let topic = grade.topic {
                    Text(topic)
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                HStack(spacing: 4) {
                    Text(grade.type.name)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    if let weight = grade.weightPercentage, weight != 100 {
                        Text("(\(weight)%)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(white: 0.15))
        .cornerRadius(6)
    }
}
