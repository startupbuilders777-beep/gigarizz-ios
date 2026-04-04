import SwiftUI

// MARK: - Rizz Coach Dashboard View

/// Main dashboard for the Rizz Coach feature — personal dating profile advisor.
struct RizzCoachDashboardView: View { @StateObject private var viewModel = RizzCoachViewModel()
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showWeeklyReport = false

    var body: some View { ZStack { DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView { VStack(spacing: DesignSystem.Spacing.large) { headerSection
                    rizzScoreSection
                    weeklyReportSection
                    photoPerformanceSection
                    bioStrengthSection
                    responseTimeSection
                    dailyTipSection
                    privacySection
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
            .refreshable { await viewModel.refreshAllData()
            }
        }
        .navigationTitle("Rizz Coach")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showWeeklyReport) { WeeklyRizzReportDetailView(report: viewModel.weeklyReport ?? WeeklyRizzReport.demo)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var headerSection: some View { GRCard { HStack(spacing: DesignSystem.Spacing.medium) { ZStack { Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.flameOrange, DesignSystem.Colors.goldAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) { Text("Your Personal Dating Coach")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("Data-driven advice to boost your matches")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }

    // MARK: - Rizz Score

    private var rizzScoreSection: some View { RizzScoreCard(
            score: viewModel.rizzScore ?? RizzScore.demo,
            isLoading: viewModel.isLoading,
            showAnimation: viewModel.showScoreAnimation,
            onRefresh: { Task { await viewModel.calculateRizzScore() }
        })
    }

    // MARK: - Weekly Report

    private var weeklyReportSection: some View { Button { showWeeklyReport = true
            DesignSystem.Haptics.light()
        } label: { WeeklyRizzReportCard(report: viewModel.weeklyReport ?? WeeklyRizzReport.demo)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photo Performance

    private var photoPerformanceSection: some View { VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) { Label("Photo Performance", systemImage: "photo.stack.fill")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(viewModel.photoPerformances) { performance in
                PhotoPerformanceCard(performance: performance)
            }
        }
    }

    // MARK: - Bio Strength

    private var bioStrengthSection: some View { BioStrengthMeter(bioStrength: viewModel.bioStrength ?? BioStrength.demo)
    }

    // MARK: - Response Time

    private var responseTimeSection: some View { ResponseTimeTrackerView(stats: viewModel.responseTimeStats ?? ResponseTimeStats.demo)
    }

    // MARK: - Daily Tip

    private var dailyTipSection: some View { VStack(spacing: DesignSystem.Spacing.small) { if let tip = viewModel.dailyTip { RizzTipCard(
                    tip: tip,
                    onDismiss: { viewModel.dismissTip()
                    },
                    onAction: { // Navigate to relevant feature
                        DesignSystem.Haptics.medium()
                    },
                    onGetNewTip: { Task { await viewModel.getNewTip() }
                })
            } else { EmptyStateView(
                    icon: "lightbulb.fill",
                    title: "No Tips Today",
                    subtitle: "Check back tomorrow for new dating advice.",
                    ctaTitle: "Get New Tip",
                    ctaAction: { Task { await viewModel.getNewTip() } }
                )
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View { GRCard { VStack(spacing: DesignSystem.Spacing.small) { HStack { Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.success)
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.micro) { Text("Privacy First")
                            .font(DesignSystem.Typography.callout)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("All your data stays on-device. Opt in to sync across devices.")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                }

                if !viewModel.hasOptedInCloudSync { GRButton(
                        title: "Enable Cloud Sync",
                        icon: "icloud.and.arrow.up",
                        style: .secondary
                    ) { viewModel.optInCloudSync()
                    }
                } else { HStack { Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.success)
                        Text("Cloud sync enabled")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview { NavigationStack { RizzCoachDashboardView()
            .environmentObject(SubscriptionManager.shared)
    }
    .preferredColorScheme(.dark)
}
