import SwiftUI

struct CountrySelectView: View {
    @EnvironmentObject var appState: AppState
    @State private var query = ""
    @State private var selectedCode: String?

    var filtered: [Country] {
        let q = query.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? demoCountries : demoCountries.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Title
                HStack {
                    Text("Choose a country")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Search
                DarkSearchField(text: $query, placeholder: "Search")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // List
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filtered) { country in
                            Button {
                                selectedCode = country.code
                                appState.setCountry(country)
                            } label: {
                                HStack(spacing: 14) {
                                    RadioDot(selected: selectedCode == country.code)
                                    Text(country.flag)
                                        .font(.system(size: 22))
                                    Text(country.name)
                                        .font(.system(size: 16))
                                        .foregroundColor(.textPrimary)
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

                NavigationLink(destination: PCNSelectView(country: appState.country ?? demoCountries[0])) {
                    Text("Step one")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.buttonDark)
                        .foregroundColor(.textPrimary)
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    if appState.country == nil { appState.setCountry(demoCountries[0]) }
                })
                .padding(16)
            }
        }
        .navigationBarHidden(true)
        .onAppear { selectedCode = appState.country?.code }
    }
}

struct RadioDot: View {
    let selected: Bool
    var body: some View {
        ZStack {
            Circle()
                .stroke(selected ? Color.primaryRed : Color.inputBorder, lineWidth: 1.5)
                .frame(width: 20, height: 20)
            if selected {
                Circle()
                    .fill(Color.primaryRed)
                    .frame(width: 10, height: 10)
            }
        }
    }
}

struct DarkSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.textSecondary)
                }
                .foregroundColor(.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(12)
        .background(Color.inputBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.inputBorder, lineWidth: 1))
        .cornerRadius(8)
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}
