import SwiftUI

struct VoiceOrbView: View {
    let audioLevel: Float
    let isActive: Bool

    private var level: CGFloat { CGFloat(audioLevel) }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(AppColors.accent.opacity(isActive ? 0.08 + Double(level) * 0.06 : 0.04))
                .scaleEffect(isActive ? 1.0 + level * 0.6 : 0.9)

            // Middle ring
            Circle()
                .fill(AppColors.accent.opacity(isActive ? 0.15 + Double(level) * 0.1 : 0.08))
                .scaleEffect(isActive ? 0.7 + level * 0.4 : 0.6)

            // Inner core
            Circle()
                .fill(AppColors.accent.opacity(isActive ? 0.35 + Double(level) * 0.25 : 0.15))
                .scaleEffect(isActive ? 0.4 + level * 0.2 : 0.35)
        }
        .animation(.easeInOut(duration: 0.08), value: audioLevel)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}
