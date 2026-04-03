import SwiftUI

struct CoachView: View {
    @StateObject private var viewModel = CoachViewModel()
    @State private var showPaywall = false
    @State private var showRizzDashboard = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    headerSection
                    rizzCoachDashboardLink
                    bioGeneratorSection
                    openingLinesSection
                    hingePromptsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .navigationTitle("Coach").toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .navigationDestination(isPresented: $showRizzDashboard) { RizzCoachDashboardView() }
    }

    private var rizzCoachDashboardLink: some View {
        Button {
            showRizzDashboard = true
            DesignSystem.Haptics.light()
        } label: {
            GRCard {
                HStack(spacing: DesignSystem.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                        Text("Rizz Coach Dashboard")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Your personalized dating advisor")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var headerSection: some View {
        GRCard {
            HStack(spacing: DesignSystem.Spacing.m) {
                Image(systemName: "brain.head.profile").font(.system(size: 32))
                    .foregroundStyle(LinearGradient(colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent], startPoint: .top, endPoint: .bottom))
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) {
                    Text("Rizz Coach").font(DesignSystem.Typography.title).foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("AI-powered dating assistant").font(DesignSystem.Typography.footnote).foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }.padding(.top, DesignSystem.Spacing.m)
    }

    private var bioGeneratorSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Label("Bio Generator", systemImage: "text.quote").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(CoachService.BioTone.allCases) { tone in
                    Button {
                        withAnimation(DesignSystem.Animation.quickSpring) { viewModel.selectedTone = tone }
                        DesignSystem.Haptics.light()
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.micro) {
                            Image(systemName: tone.icon).font(.system(size: 20))
                            Text(tone.rawValue).font(DesignSystem.Typography.caption).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, DesignSystem.Spacing.s)
                        .background(viewModel.selectedTone == tone ? DesignSystem.Colors.flameOrange.opacity(0.15) : DesignSystem.Colors.surface)
                        .foregroundStyle(viewModel.selectedTone == tone ? DesignSystem.Colors.flameOrange : DesignSystem.Colors.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small).strokeBorder(viewModel.selectedTone == tone ? DesignSystem.Colors.flameOrange : .clear, lineWidth: 1.5))
                    }
                }
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(DatingPlatform.allCases) { platform in
                    Button {
                        viewModel.selectedPlatform = platform
                        DesignSystem.Haptics.light()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: platform.icon).font(.system(size: 12))
                            Text(platform.rawValue).font(DesignSystem.Typography.caption)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.s).padding(.vertical, DesignSystem.Spacing.xs)
                        .background(viewModel.selectedPlatform == platform ? platform.color.opacity(0.15) : DesignSystem.Colors.surface)
                        .foregroundStyle(viewModel.selectedPlatform == platform ? platform.color : DesignSystem.Colors.textSecondary)
                        .clipShape(Capsule())
                    }
                }
            }

            GRButton(title: "Generate Bio", icon: "sparkles", isLoading: viewModel.isGeneratingBio) {
                Task { await viewModel.generateBio() }
            }

            if let bio = viewModel.generatedBio {
                GRCard {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text(bio).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary).lineSpacing(4)
                        HStack {
                            Button {
                                UIPasteboard.general.string = bio
                                DesignSystem.Haptics.success()
                                viewModel.copiedBio = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { viewModel.copiedBio = false }
                            } label: {
                                Label(viewModel.copiedBio ? "Copied!" : "Copy", systemImage: viewModel.copiedBio ? "checkmark" : "doc.on.doc")
                                    .font(DesignSystem.Typography.smallButton).foregroundStyle(DesignSystem.Colors.flameOrange)
                            }
                            Spacer()
                            Button { Task { await viewModel.generateBio() } } label: {
                                Label("Regenerate", systemImage: "arrow.counterclockwise").font(DesignSystem.Typography.smallButton).foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var openingLinesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Label("Opening Lines", systemImage: "bubble.left.fill").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                TextField("Match name (optional)", text: $viewModel.matchName)
                    .textFieldStyle(.plain).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.s).background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                GRButton(title: "Go", icon: "paperplane.fill") { Task { await viewModel.generateOpeningLines() } }.frame(width: 80)
            }

            if viewModel.isGeneratingLines { HStack { Spacer(); ProgressView().tint(DesignSystem.Colors.flameOrange); Spacer() }.padding(.vertical, DesignSystem.Spacing.m) }

            ForEach(Array(viewModel.openingLines.enumerated()), id: \.offset) { index, line in
                GRCard {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Text("Option \(index + 1)").font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.flameOrange)
                            Spacer()
                            Button { UIPasteboard.general.string = line; DesignSystem.Haptics.success() } label: {
                                Image(systemName: "doc.on.doc").font(.system(size: 14)).foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                        Text(line).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary).lineSpacing(3)
                    }
                }
            }
        }
    }

    private var hingePromptsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Label("Hinge Prompts", systemImage: "text.badge.star").font(DesignSystem.Typography.callout).foregroundStyle(DesignSystem.Colors.textPrimary)
            GRButton(title: "Generate Prompts", icon: "sparkles", style: .secondary, isLoading: viewModel.isGeneratingPrompts) {
                Task { await viewModel.generateHingePrompts() }
            }
            ForEach(Array(viewModel.hingePrompts.enumerated()), id: \.offset) { _, item in
                GRCard {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(item.prompt).font(DesignSystem.Typography.caption).foregroundStyle(DesignSystem.Colors.hinge)
                        Text(item.answer).font(DesignSystem.Typography.body).foregroundStyle(DesignSystem.Colors.textPrimary).lineSpacing(3)
                    }
                }
            }
        }
    }
}

#Preview { NavigationStack { CoachView() }.environmentObject(SubscriptionManager()).preferredColorScheme(.dark) }
