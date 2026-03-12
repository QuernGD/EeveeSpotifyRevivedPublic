import SwiftUI

struct TrueShuffleSettingsView: View {
    @State var isEnabled: Bool = {
        let ud = UserDefaults.standard
        if ud.object(forKey: "com.trueshuffle.enabled") == nil {
            return true
        }
        return ud.bool(forKey: "com.trueshuffle.enabled")
    }()

    var body: some View {
        List {
            Section(
                footer: Text("Blocks Spotify's weighted recommendation shuffle and plays tracks in a purely random order. Takes effect immediately.")
            ) {
                Toggle("True Shuffle", isOn: $isEnabled)
            }
            .onChange(of: isEnabled) { value in
                UserDefaults.standard.set(value, forKey: "com.trueshuffle.enabled")
            }

            NonIPadSpacerView()
        }
        .listStyle(GroupedListStyle())
    }
}
