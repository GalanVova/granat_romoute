import SwiftUI

struct PCNSelectView: View {
    @EnvironmentObject var appState: AppState
    let country: Country
    @State private var query = ""
    @State private var selectedID: String?
    @Environment(\.dismiss) var dismiss

    var filtered: [PCN] {
        let byCountry = demoPCNs.filter { $0.countryCode == country.code }
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? byCountry : byCountry.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                HStack {
                    Text("Choosing a security system")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                DarkSearchField(text: $query, placeholder: "Search")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filtered) { pcn in
                            Button {
                                selectedID = pcn.id
                                appState.setPCN(pcn)
                            } label: {
                                HStack(spacing: 14) {
                                    RadioDot(selected: selectedID == pcn.id)
                                    Text(pcn.name)
                                        .font(.system(size: 16))
                                        .foregroundColor(.textPrimary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                            }
                            Divider().background(Color.inputBorder).padding(.leading, 20)
                        }
                    }
                }

                Spacer()

                NavigationLink(destination: LoginView()) {
                    Text("Step two")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.buttonDark)
                        .foregroundColor(.textPrimary)
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    if appState.pcn == nil, let first = filtered.first { appState.setPCN(first) }
                })
                .padding(16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appState.setCountry(country)
            selectedID = appState.pcn?.id ?? filtered.first?.id
            if let first = filtered.first, appState.pcn == nil { appState.setPCN(first); selectedID = first.id }
        }
    }
}
