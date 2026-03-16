import SwiftUI

var lastKnownPlaylistURI: String? {
    get { UserDefaults.standard.string(forKey: "com.trueshuffle.lastPlaylistURI") }
    set { UserDefaults.standard.set(newValue, forKey: "com.trueshuffle.lastPlaylistURI") }
}

struct TrueShuffleSettingsView: View {
    @State private var isEnabled = UserDefaults.standard.object(forKey: "com.trueshuffle.enabled") as? Bool ?? true
    @State private var isLoading = false

    var body: some View {
        List {
            Section(footer: Text("Blocks Spotify's smart shuffle recommendations.")) {
                Toggle("Block Smart Shuffle", isOn: $isEnabled)
                    .onChange(of: isEnabled) { value in
                        UserDefaults.standard.set(value, forKey: "com.trueshuffle.enabled")
                    }
            }

            Section(footer: Text("Fetches your current playlist, shuffles it randomly on-device, and plays it. Open a playlist and start playing before tapping this.")) {
                Button {
                    guard let uri = lastKnownPlaylistURI else {
                        PopUpHelper.showPopUp(message: "No playlist detected. Open a playlist and play a song first.", buttonText: "OK")
                        return
                    }
                    isLoading = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        playTrueShuffle(playlistURI: uri)
                        DispatchQueue.main.async {
                            isLoading = false
                        }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "shuffle")
                                .foregroundColor(.green)
                        }
                        Text(isLoading ? "Shuffling..." : "Play True Shuffle")
                            .foregroundColor(isLoading ? .gray : .primary)
                    }
                }
                .disabled(isLoading)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("True Shuffle")
    }
}
