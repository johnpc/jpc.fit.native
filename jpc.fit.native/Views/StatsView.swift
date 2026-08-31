import SwiftUI

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()
    @State private var refreshTrigger = UUID()
    @State private var isVisible = false
    @State private var isStale = false

    var body: some View {
        List {
            HeaderSection()
            streakSection
            weekSummarySection
            weekNavigationSection
            dailyBreakdownSection
        }
        .navigationTitle("Stats")
        .task(id: refreshTrigger) { await vm.refresh(); isStale = false }
        .refreshable { await vm.refresh() }
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
        .overlay { if vm.isLoading { ProgressView() } }
    }

    private var streakSection: some View {
        Section {
            VStack(spacing: 8) {
                if let days = vm.streakDays {
                    let label = days >= StatsViewModel.streakCap ? "\(days)+" : "\(days)"
                    Text("Your streak is \(label) days").font(.headline)
                    Text("Est. \(vm.streakLbs, specifier: "%.1f") lbs \(vm.streakLbs > 0 ? "gained" : "lost")")
                        .font(.subheadline)
                        .foregroundStyle(vm.streakLbs > 0 ? .red : .green)
                } else {
                    HStack(spacing: 8) { ProgressView(); Text("Calculating streak...") }
                }
                HStack(spacing: 16) {
                    ForEach(vm.weekData.suffix(4), id: \.day) { day in
                        VStack { Text(day.tracked ? "🔥" : "❌").font(.title); Text(day.shortDay).font(.caption) }
                    }
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }

    private var weekSummarySection: some View {
        Section("This Week") {
            HStack { Spacer(); Text("Net \(vm.weekNet) cal").foregroundStyle(vm.weekNet > 0 ? .red : .green).fontWeight(.semibold); Spacer() }
            HStack { Spacer(); Text("1 lb of fat ≈ 3500 calories").font(.caption).foregroundStyle(.secondary); Spacer() }
        }
    }

    private var weekNavigationSection: some View {
        Section {
            HStack {
                Button { vm.changeWeek(-7) } label: { Image(systemName: "chevron.left") }.buttonStyle(.borderless)
                Spacer(); Text(vm.weekRangeString).fontWeight(.bold); Spacer()
                Button { vm.changeWeek(7) } label: { Image(systemName: "chevron.right") }.buttonStyle(.borderless)
            }
            if !Calendar.current.isDateInToday(vm.weekStartDate) {
                Button("Today") { vm.weekStartDate = Date(); Task { await vm.fetchWeek() } }.frame(maxWidth: .infinity)
            }
        }
    }

    private var dailyBreakdownSection: some View {
        Section {
            ForEach(vm.weekData, id: \.day) { day in
                HStack {
                    Text(day.shortDay).frame(width: 50, alignment: .leading)
                    Text("\(day.consumed)").frame(width: 60, alignment: .trailing)
                    Text("\(day.burned)").frame(width: 60, alignment: .trailing)
                    Spacer()
                    Text("\(day.net)").foregroundStyle(day.net > 0 ? .red : .green).fontWeight(.medium)
                }
                .font(.callout)
            }
        } header: {
            HStack {
                Text("Day").frame(width: 50, alignment: .leading)
                Text("Food").frame(width: 60, alignment: .trailing)
                Text("Burn").frame(width: 60, alignment: .trailing)
                Spacer(); Text("Net")
            }.font(.caption)
        }
    }
}
