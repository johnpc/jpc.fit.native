import SwiftUI

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()
    @State private var refreshTrigger = UUID()
    @State private var isVisible = false
    @State private var isStale = false

    var body: some View {
        List {
            HeaderSection()
            StatsStreakSection(vm: vm)
            weekSummarySection
            weekNavigationSection
            StatsBreakdownSection(weekData: vm.weekData)
        }
        .navigationTitle("Stats")
        .task(id: refreshTrigger) { await vm.refresh(); isStale = false }
        .refreshable { await vm.refresh(); isStale = false }
        // TabView keeps this view alive in the background, and every food
        // add/edit/delete posts .foodDataChanged. Refreshing immediately would
        // rerun the whole week + streak walk per tap while the tab isn't even
        // on screen — so off-screen we only mark the data stale and refresh
        // once on next appearance.
        .onReceive(NotificationCenter.default.publisher(for: .foodDataChanged)) { _ in
            if isVisible { refreshTrigger = UUID() } else { isStale = true }
        }
        .onAppear {
            isVisible = true
            if isStale { refreshTrigger = UUID() }
        }
        .onDisappear { isVisible = false }
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
