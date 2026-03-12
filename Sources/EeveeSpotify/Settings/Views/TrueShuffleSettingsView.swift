import SwiftUI

struct TrueShuffleSettingsView: View {
@State var isEnabled = UserDefaults.standard.object(forKey: “com.trueshuffle.enabled”) == nil
? true
: UserDefaults.standard.bool(forKey: “com.trueshuffle.enabled”)

```
var body: some View {
    List {
        Section(
            footer: Text("Blocks Spotify's weighted recommendation shuffle and plays tracks in a purely random order. Takes effect immediately — no restart needed.")
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
```

}
