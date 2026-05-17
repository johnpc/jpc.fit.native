import SwiftUI
import Amplify

struct WeightView: View {
    let user: AuthUser
    @StateObject private var vm = WeightViewModel()
    @State private var showWeightAlert = false
    @State private var showHeightAlert = false
    @State private var newValue = ""

    var body: some View {
        List {
            HeaderSection()
            healthDataSection
            bmiRangeSection
            referenceSection
        }
        .navigationTitle("Weight")
        .alert("Enter Weight (lbs)", isPresented: $showWeightAlert) {
            TextField("Weight", text: $newValue).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { newValue = "" }
            Button("Save") { vm.saveWeight(newValue); newValue = "" }
        }
        .alert("Enter Height (inches)", isPresented: $showHeightAlert) {
            TextField("Height", text: $newValue).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { newValue = "" }
            Button("Save") { vm.saveHeight(newValue); newValue = "" }
        }
        .task { await vm.fetchData() }
        .refreshable { await vm.fetchData() }
        .overlay { if vm.isLoading { ProgressView() } }
        .overlay(alignment: .bottom) {
            if vm.showToast, let msg = vm.toastMessage {
                Text(msg)
                    .font(.callout).padding()
                    .background(.red.opacity(0.9)).foregroundStyle(.white)
                    .cornerRadius(10).padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 4) { withAnimation { vm.showToast = false } } }
            }
        }
        .animation(.easeInOut, value: vm.showToast)
    }

    private var healthDataSection: some View {
        Section("Health Data") {
            HStack {
                Text("Weight"); Spacer(); Text("\(vm.currentWeight) lbs")
                Button { showWeightAlert = true } label: { Image(systemName: "scalemass") }.buttonStyle(.borderless)
            }
            HStack {
                Text("Height"); Spacer(); Text("\(vm.currentHeight) inches")
                Button { showHeightAlert = true } label: { Image(systemName: "ruler") }.buttonStyle(.borderless)
            }
            HStack { Text("BMI"); Spacer(); Text("\(vm.bmi, specifier: "%.1f") (\(vm.bmiLabel))") }
        }
    }

    private var bmiRangeSection: some View {
        Section("BMI Range for Your Height") {
            bmiRow("Underweight", subtitle: "BMI < 18.5", range: "0 - \(String(format: "%.1f", vm.maxUnderweight)) lbs")
            bmiRow("Healthy", subtitle: "BMI 18.5 - 25", range: "\(String(format: "%.1f", vm.maxUnderweight)) - \(String(format: "%.1f", vm.maxHealthy)) lbs")
            bmiRow("Overweight", subtitle: "BMI 25 - 30", range: "\(String(format: "%.1f", vm.maxHealthy)) - \(String(format: "%.1f", vm.maxOverweight)) lbs")
            bmiRow("Obese", subtitle: "BMI 30+", range: "\(String(format: "%.1f", vm.maxOverweight))+ lbs")
        }
    }

    private func bmiRow(_ title: String, subtitle: String, range: String) -> some View {
        HStack {
            VStack(alignment: .leading) { Text(title); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            Spacer(); Text(range)
        }
    }

    private var referenceSection: some View {
        Section {
            DisclosureGroup("Why BMI?") {
                Text("**BMI is often criticized as a blunt instrument** - it only considers weight and height, ignoring gender, genetics, and muscle mass. Arnold Schwarzenegger in his prime was considered obese by BMI (30.2)!").font(.callout).padding(.vertical, 4)
                Text("However, for typical people without elite training regimens, **BMI remains a practical tool to set healthy goals**.").font(.callout).padding(.vertical, 4)
            }
            DisclosureGroup("BMI Chart") { Image("bmi-chart").resizable().scaledToFit() }
            DisclosureGroup("Male Body Fat % Eye Test") { Image("male-bf").resizable().scaledToFit() }
            DisclosureGroup("Female Body Fat % Eye Test") { Image("female-bf").resizable().scaledToFit() }
            DisclosureGroup("Body Fat % Chart") { Image("bf-chart").resizable().scaledToFit() }
        }
    }
}
