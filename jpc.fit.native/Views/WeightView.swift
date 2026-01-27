import SwiftUI
import Amplify

struct WeightView: View {
    let user: AuthUser
    @State private var weights: [Weight] = []
    @State private var heights: [Height] = []
    @State private var isLoading = true
    @State private var showWeightAlert = false
    @State private var showHeightAlert = false
    @State private var newValue = ""
    
    private var currentWeight: Int { weights.first?.currentWeight ?? 180 }
    private var currentHeight: Int { heights.first?.currentHeight ?? 70 }
    private var bmi: Double { Double(currentWeight) / Double(currentHeight * currentHeight) * 703 }
    private var bmiLabel: String {
        if bmi < 18.5 { return "underweight" }
        if bmi < 25 { return "healthy" }
        if bmi < 30 { return "overweight" }
        return "obese"
    }
    
    private var maxUnderweight: Double { 18.5 / 703 * Double(currentHeight * currentHeight) }
    private var maxHealthy: Double { 25.0 / 703 * Double(currentHeight * currentHeight) }
    private var maxOverweight: Double { 30.0 / 703 * Double(currentHeight * currentHeight) }
    
    var body: some View {
        List {
            HeaderSection()
            
            Section("Health Data") {
                HStack {
                    Text("Weight")
                    Spacer()
                    Text("\(currentWeight) lbs")
                    Button { showWeightAlert = true } label: {
                        Image(systemName: "scalemass")
                    }
                    .buttonStyle(.borderless)
                }
                HStack {
                    Text("Height")
                    Spacer()
                    Text("\(currentHeight) inches")
                    Button { showHeightAlert = true } label: {
                        Image(systemName: "ruler")
                    }
                    .buttonStyle(.borderless)
                }
                HStack {
                    Text("BMI")
                    Spacer()
                    Text("\(bmi, specifier: "%.1f") (\(bmiLabel))")
                }
            }
            
            Section("BMI Range for Your Height") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Underweight")
                        Text("BMI < 18.5").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("0 - \(maxUnderweight, specifier: "%.1f") lbs")
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Healthy")
                        Text("BMI 18.5 - 25").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(maxUnderweight, specifier: "%.1f") - \(maxHealthy, specifier: "%.1f") lbs")
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Overweight")
                        Text("BMI 25 - 30").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(maxHealthy, specifier: "%.1f") - \(maxOverweight, specifier: "%.1f") lbs")
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Obese")
                        Text("BMI 30+").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(maxOverweight, specifier: "%.1f")+ lbs")
                }
            }
            
            Section {
                DisclosureGroup("Why BMI?") {
                    Text("BMI is often criticized as a blunt instrument - it only considers weight and height, ignoring gender, genetics, and muscle mass. **Fun fact: Arnold Schwarzenegger in his prime was considered obese by BMI (30.2)!**")
                        .font(.callout)
                        .padding(.vertical, 4)
                    Text("However, the Arnies of the world are extreme outliers. **BMI's bluntness is not a \"get out of dieting free\" card.** Olympic athletes average BMI 24 (male) and 21.6 (female), both healthy.")
                        .font(.callout)
                        .padding(.vertical, 4)
                    Text("For typical people without elite training regimens, **BMI remains a practical tool to set healthy goals**.")
                        .font(.callout)
                        .padding(.vertical, 4)
                }
                
                DisclosureGroup("BMI Chart") {
                    Image("bmi-chart")
                        .resizable()
                        .scaledToFit()
                }
                
                DisclosureGroup("Male Body Fat % Eye Test") {
                    Image("male-bf")
                        .resizable()
                        .scaledToFit()
                }
                
                DisclosureGroup("Female Body Fat % Eye Test") {
                    Image("female-bf")
                        .resizable()
                        .scaledToFit()
                }
                
                DisclosureGroup("Body Fat % Chart") {
                    Image("bf-chart")
                        .resizable()
                        .scaledToFit()
                }
            }
        }
        .navigationTitle("Weight")
        .alert("Enter Weight (lbs)", isPresented: $showWeightAlert) {
            TextField("Weight", text: $newValue).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { newValue = "" }
            Button("Save") { saveWeight() }
        }
        .alert("Enter Height (inches)", isPresented: $showHeightAlert) {
            TextField("Height", text: $newValue).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { newValue = "" }
            Button("Save") { saveHeight() }
        }
        .task { await fetchData() }
        .refreshable { await fetchData() }
        .overlay { if isLoading { ProgressView() } }
    }
    
    private func fetchData() async {
        isLoading = true
        async let w = fetchWeights()
        async let h = fetchHeights()
        weights = await w
        heights = await h
        isLoading = false
    }
    
    private func fetchWeights() async -> [Weight] {
        let request = GraphQLRequest<JSONValue>(
            document: "query ListWeights { listWeights { items { id currentWeight createdAt } } }",
            responseType: JSONValue.self
        )
        do {
            let result = try await Amplify.API.query(request: request)
            if case .success(let json) = result {
                guard let listWeights = json["listWeights"],
                      let items = listWeights["items"]?.asArray else { return [] }
                return items.compactMap { item -> Weight? in
                    guard let id = item["id"]?.stringValue,
                          let cw = item["currentWeight"]?.intValue else { return nil }
                    let createdAt = item["createdAt"]?.stringValue ?? ""
                    return Weight(id: id, currentWeight: cw, createdAt: try? Temporal.DateTime(iso8601String: createdAt))
                }.sorted { ($0.createdAt?.foundationDate ?? .distantPast) > ($1.createdAt?.foundationDate ?? .distantPast) }
            }
        } catch {}
        return []
    }
    
    private func fetchHeights() async -> [Height] {
        let request = GraphQLRequest<JSONValue>(
            document: "query ListHeights { listHeights { items { id currentHeight createdAt } } }",
            responseType: JSONValue.self
        )
        do {
            let result = try await Amplify.API.query(request: request)
            if case .success(let json) = result {
                guard let listHeights = json["listHeights"],
                      let items = listHeights["items"]?.asArray else { return [] }
                return items.compactMap { item -> Height? in
                    guard let id = item["id"]?.stringValue,
                          let ch = item["currentHeight"]?.intValue else { return nil }
                    let createdAt = item["createdAt"]?.stringValue ?? ""
                    return Height(id: id, currentHeight: ch, createdAt: try? Temporal.DateTime(iso8601String: createdAt))
                }.sorted { ($0.createdAt?.foundationDate ?? .distantPast) > ($1.createdAt?.foundationDate ?? .distantPast) }
            }
        } catch {}
        return []
    }
    
    private func saveWeight() {
        guard let val = Int(newValue), val > 0 else { newValue = ""; return }
        Task {
            let request = GraphQLRequest<JSONValue>(
                document: "mutation CreateWeight($input: CreateWeightInput!) { createWeight(input: $input) { id } }",
                variables: ["input": ["currentWeight": val]],
                responseType: JSONValue.self
            )
            _ = try? await Amplify.API.mutate(request: request)
            await fetchData()
        }
        newValue = ""
    }
    
    private func saveHeight() {
        guard let val = Int(newValue), val > 0 else { newValue = ""; return }
        Task {
            let request = GraphQLRequest<JSONValue>(
                document: "mutation CreateHeight($input: CreateHeightInput!) { createHeight(input: $input) { id } }",
                variables: ["input": ["currentHeight": val]],
                responseType: JSONValue.self
            )
            _ = try? await Amplify.API.mutate(request: request)
            await fetchData()
        }
        newValue = ""
    }
}
