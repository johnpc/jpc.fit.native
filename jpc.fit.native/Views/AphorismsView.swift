import SwiftUI

struct AphorismsView: View {
    private let aphorisms = Aphorisms.all
    /// Which quotes have been shown this cycle — see `QuoteBag`.
    @State private var bag = QuoteBag(count: Aphorisms.all.count)

    private var currentQuote: String {
        aphorisms[bag.current ?? 0]
    }

    var body: some View {
        VStack(spacing: 24) {
            AppHeaderRow()
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
                bag.draw()
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
            if bag.current == nil { bag.draw() }
        }
    }
}
