import SwiftUI

struct AphorismsView: View {
    private let aphorisms = Aphorisms.all
    @State private var usedIndexes: [Int] = []

    private var currentQuote: String {
        guard let lastIndex = usedIndexes.last else { return aphorisms[0] }
        return aphorisms[lastIndex]
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Image("AppIconImage")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                VStack(alignment: .leading) {
                    Text("fit.jpc.io").font(.headline)
                    Text("Health tracker").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            Spacer()

            Image(systemName: "quote.opening")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(currentQuote)
                .font(.title2)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button {
                randomize()
            } label: {
                Text("Randomize Quote")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Aphorisms")
        .onAppear {
            if usedIndexes.isEmpty { randomize() }
        }
    }

    private func randomize() {
        if usedIndexes.count == aphorisms.count {
            usedIndexes = []
        }
        var randomIndex: Int
        repeat {
            randomIndex = Int.random(in: 0..<aphorisms.count)
        } while usedIndexes.contains(randomIndex)
        usedIndexes.append(randomIndex)
    }
}
