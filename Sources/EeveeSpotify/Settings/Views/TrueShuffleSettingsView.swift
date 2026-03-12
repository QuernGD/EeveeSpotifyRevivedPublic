import SwiftUI

struct TrueShuffleSettingsView: View {
    @State private var isEnabled = UserDefaults.standard.object(forKey: "com.trueshuffle.enabled") as? Bool ?? true
    @State private var isLogging = UserDefaults.standard.bool(forKey: "com.trueshuffle.logurls")

    var body: some View {
        List {
            Section(footer: Text("Blocks Spotify's smart shuffle recommendations and weighted ordering.")) {
                Toggle("True Shuffle", isOn: $isEnabled)
                    .onChange(of: isEnabled) { value in
                        UserDefaults.standard.set(value, forKey: "com.trueshuffle.enabled")
                    }
            }

            Section(
                header: Text("URL Logger"),
                footer: Text("Logs all Spotify network requests to the debug log. Enable this, trigger shuffle in Spotify, then export the debug log from the section below.")
            ) {
                Toggle("Log URLs", isOn: $isLogging)
                    .onChange(of: isLogging) { value in
                        UserDefaults.standard.set(value, forKey: "com.trueshuffle.logurls")
                        writeDebugLog("[TrueShuffle] URL logging \(value ? "enabled" : "disabled")")
                    }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("True Shuffle")
    }
}
