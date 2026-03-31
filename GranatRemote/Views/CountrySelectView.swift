import SwiftUI

struct CountrySelectView: View {
    @EnvironmentObject var appState: AppState
    @State private var query = ""

    var filtered: [Country] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return demoCountries
        }
        return demoCountries.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search countries", text: $query)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            List(filtered) { country in
                NavigationLink(destination: PCNSelectView(country: country)) {
                    Text(country.name)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    appState.setCountry(country)
                })
            }
            .listStyle(.plain)

            Divider()

            NavigationLink(destination: PCNSelectView(country: appState.country ?? demoCountries[0])) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "222222"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .simultaneousGesture(TapGesture().onEnded {
                if appState.country == nil {
                    appState.setCountry(demoCountries[0])
                }
            })
            .padding()
        }
        .navigationTitle("Select country")
        .navigationBarTitleDisplayMode(.inline)
    }
}
