import SwiftUI

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()

    var body: some View {
        List {
            HeaderSection()
            StatsStreakSection(vm: vm)
            weekSummarySection
            weekNavigationSection
            StatsBreakdownSection(weekData: vm.weekData)
        }
        .navigationTitle("Stats")
        .task(id: vm.refreshToken) { await vm.refresh() }
        .refreshable { await vm.refresh() }
        // TabView keeps this view alive in the background, and every food
        // add/edit/delete posts .foodDataChanged. The ViewModel's RefreshGate
        // decides whether that means "refresh now" (on screen) or "refresh
        // once on next appearance" (off screen) — see Models/RefreshGate.swift.
        .onReceive(NotificationCenter.default.publisher(for: .foodDataChanged)) { _ in vm.foodDataChanged() }
        .onAppear { vm.appeared() }
        .onDisappear { vm.disappeared() }
        .overlay { if vm.isLoading && vm.weekData.isEmpty { ProgressView() } }
    }

    private var weekSummarySection: some View {
        Section("Last 7 Days") {
            HStack {
                Spacer()
                Text("Net \(vm.weekNet) cal")
                    .foregroundStyle(vm.weekNet > 0 ? .red : .green).fontWeight(.semibold)
                    .accessibilityLabel("Net \(vm.weekNet) calories, \(vm.weekNet > 0 ? "surplus" : "deficit")")
                Spacer()
            }
            HStack { Spacer(); Text("1 lb of fat ≈ 3500 calories").font(.caption).foregroundStyle(.secondary); Spacer() }
        }
    }

    private var weekNavigationSection: some View {
        Section {
            HStack {
                Button { vm.changeWeek(-7) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Previous 7 days")
                Spacer(); Text(vm.weekRangeString).fontWeight(.bold); Spacer()
                Button { vm.changeWeek(7) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .buttonStyle(.borderless)
                    .disabled(vm.isViewingCurrentWeek)
                    .accessibilityLabel("Next 7 days")
            }
            if !vm.isViewingCurrentWeek {
                Button("Today") { vm.goToToday() }.frame(maxWidth: .infinity)
            }
        }
    }
}
