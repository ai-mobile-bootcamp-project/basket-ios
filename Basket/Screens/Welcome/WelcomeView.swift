import SwiftUI

/// First-launch screen shown before Lists. Both buttons set the onboarding flag and the root view
/// replaces this screen, so there is nothing to go back to.
@MainActor struct WelcomeView: View {
    @AppStorage("basket.onboardingDone") private var onboardingDone = false
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let seedSampleData: () -> Void

    init(seedSampleData: @escaping () -> Void) {
        self.seedSampleData = seedSampleData
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                content
                    .padding(.horizontal, BasketSpacing.xl)
                    .padding(.top, topSpacing)
                    .padding(.bottom, BasketSpacing.xl)
            }
            buttons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            BasketColor.surface.ignoresSafeArea()
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            appMark

            Text(L10n.tr("welcome.title", locale))
                .font(BasketFont.displaySmall)
                .foregroundColor(BasketColor.onSurface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 28)

            Text(L10n.tr("welcome.tagline", locale))
                .font(BasketFont.bodyLarge)
                .foregroundColor(BasketColor.onSurfaceVariant)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, BasketSpacing.sm)

            VStack(alignment: .leading, spacing: 20) {
                point(symbol: "checklist", titleKey: "welcome.point1.title", bodyKey: "welcome.point1.body")
                point(symbol: "banknote", titleKey: "welcome.point2.title", bodyKey: "welcome.point2.body")
                point(symbol: "icloud.slash", titleKey: "welcome.point3.title", bodyKey: "welcome.point3.body")
            }
            .padding(.top, 36)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var topSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? BasketSpacing.xl : 96
    }

    private var appMark: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(BasketColor.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.black.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .frame(width: 96, height: 96)
            .overlay(
                Image(systemName: "basket.fill")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(BasketColor.primaryContainer)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .accessibilityHidden(true)
    }

    private func point(symbol: String, titleKey: String, bodyKey: String) -> some View {
        HStack(alignment: .top, spacing: BasketSpacing.lg) {
            Circle()
                .fill(BasketColor.secondaryContainer)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(BasketColor.onSecondaryContainer)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr(titleKey, locale))
                    .font(BasketFont.titleMedium)
                    .foregroundColor(BasketColor.onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.tr(bodyKey, locale))
                    .font(BasketFont.bodyMedium)
                    .foregroundColor(BasketColor.onSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: BasketSpacing.xs) {
            Button {
                getStarted()
            } label: {
                Text(L10n.tr("welcome.getStarted", locale))
                    .font(BasketFont.labelLarge)
                    .foregroundColor(BasketColor.onPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(BasketColor.primary)

            Button {
                startWithoutSamples()
            } label: {
                Text(L10n.tr("welcome.startEmpty", locale))
                    .font(BasketFont.labelLarge)
                    .foregroundColor(BasketColor.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: BasketSpacing.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, BasketSpacing.xl)
        .padding(.top, BasketSpacing.sm)
        .padding(.bottom, BasketSpacing.md)
    }

    // MARK: - Actions

    private func getStarted() {
        guard !onboardingDone else { return }
        seedSampleData()
        onboardingDone = true
    }

    private func startWithoutSamples() {
        guard !onboardingDone else { return }
        onboardingDone = true
    }
}
