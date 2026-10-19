import SwiftUI

/// Shown on every launch for about two and a half seconds, then faded out.
/// A tap anywhere skips ahead. Credits stay pinned to the bottom.
struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var symbolIn = false
    @State private var titleIn = false
    @State private var creditsIn = false
    @State private var glow = false
    @State private var loadProgress: Double = 0
    @State private var hasFinished = false

    let theme = Theme.shared

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            theme.backgroundWash.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                symbol
                    .padding(.bottom, 26)
                title
                    .padding(.bottom, 8)
                tagline
                    .padding(.bottom, 34)
                loadingBar
                Spacer()
                credits
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 32)
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear(perform: animateIn)
    }

    // MARK: - Pieces

    private var symbol: some View {
        ZStack {
            Circle()
                .fill(theme.accentGradient)
                .frame(width: 128, height: 128)
                .opacity(0.20)
                .blur(radius: 22)
                .scaleEffect(glow ? 1.22 : 0.92)

            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .accessibilityHidden(true)
        }
        .frame(height: 140)
        .scaleEffect(symbolIn ? 1 : 0.6)
        .opacity(symbolIn ? 1 : 0)
    }

    private var title: some View {
        HStack(spacing: 0) {
            Text("iAdapt")
                .foregroundStyle(theme.text)
            Text("Ops")
                .foregroundStyle(theme.accentGradient)
        }
        .font(.system(size: 42, weight: .bold, design: .rounded))
        .opacity(titleIn ? 1 : 0)
        .offset(y: titleIn || reduceMotion ? 0 : 8)
    }

    private var tagline: some View {
        Text(t("app.tagline"))
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(theme.textDim)
            .opacity(titleIn ? 1 : 0)
            .offset(y: titleIn || reduceMotion ? 0 : 8)
    }

    private var loadingBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.panel2)
                Capsule()
                    .fill(theme.accentGradient)
                    .frame(width: geometry.size.width * loadProgress)
            }
        }
        .frame(width: 148, height: 4)
        .opacity(titleIn ? 1 : 0)
    }

    private var credits: some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                Text(t("about.developedBy"))
                    .foregroundStyle(theme.textFaint)
                Text(t("about.authorName"))
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.text)
            }
            .font(.caption)

            Text("ividi.dev")
                .font(.caption.bold())
                .foregroundStyle(theme.accent)

            HStack(spacing: 5) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption2)
                Text("github.com/VidiPT89")
                    .font(.caption)
            }
            .foregroundStyle(theme.textDim)
        }
        .opacity(creditsIn ? 1 : 0)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Timing

    private func animateIn() {
        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.4)) {
                symbolIn = true; titleIn = true; creditsIn = true; loadProgress = 1
            }
            scheduleFinish(after: 1.8)
            return
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) { symbolIn = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.5)) { titleIn = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.8)) { creditsIn = true }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.3)) { glow = true }
        withAnimation(.easeInOut(duration: 1.4).delay(0.8)) { loadProgress = 1 }
        scheduleFinish(after: 2.4)
    }

    private func scheduleFinish(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { finish() }
    }

    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        onFinish()
    }
}
