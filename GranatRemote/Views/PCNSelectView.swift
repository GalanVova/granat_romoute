import SwiftUI

struct PCNSelectView: View {
    @EnvironmentObject var appState: AppState
    let country: Country
    @State private var query = ""
    @State private var selectedID: String?

    var filtered: [PCN] {
        let byCountry = demoPCNs.filter { $0.countryCode == country.code }
        if query.trimmingCharacters(in: .whitespaces).isEmpty { return byCountry }
        return byCountry.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search monitoring centers", text: $query)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            List(filtered) { pcn in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pcn.name)
                            .lineLimit(2)
                            .font(.body)
                    }
                    Spacer()
                    if selectedID == pcn.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "222222"))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedID = pcn.id
                    appState.setPCN(pcn)
                }
            }
            .listStyle(.plain)

            Divider()

            NavigationLink(destination: LoginView()) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "222222"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .simultaneousGesture(TapGesture().onEnded {
                if appState.pcn == nil, let first = filtered.first {
                    appState.setPCN(first)
                }
            })
            .padding()
        }
        .navigationTitle("Select monitoring center")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appState.setCountry(country)
            selectedID = appState.pcn?.id
        }
    }
}
