import Foundation
import UIKit

// Fetches an anonymous Spotify Web API token using the public client credentials flow
// This works for reading any public playlist without needing the user's token
private func fetchAnonymousToken(completion: @escaping (String?) -> Void) {
    // Spotify's public client ID used by the web player — valid for read-only public data
    let clientId = "d8a5ed958d274c2e8ee717e6a4b0971d"
    
    guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
        completion(nil)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = "grant_type=client_credentials&client_id=\(clientId)".data(using: .utf8)
    
    URLSession.shared.dataTask(with: request) { data, _, _ in
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else {
            completion(nil)
            return
        }
        completion(token)
    }.resume()
}

func playTrueShuffle(playlistURI: String) {
    let parts = playlistURI.components(separatedBy: ":")
    guard parts.count >= 3, parts[1] == "playlist" else {
        DispatchQueue.main.async {
            PopUpHelper.showPopUp(message: "Could not find current playlist. Make sure you are playing from a playlist.", buttonText: "OK")
        }
        return
    }
    let playlistId = parts[2]

    DispatchQueue.global(qos: .userInitiated).async {
        fetchAnonymousToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    PopUpHelper.showPopUp(message: "Could not get Spotify token. Check your internet connection.", buttonText: "OK")
                }
                return
            }

            fetchAllTracks(playlistId: playlistId, token: token) { trackURIs in
                guard !trackURIs.isEmpty else {
                    DispatchQueue.main.async {
                        PopUpHelper.showPopUp(message: "Could not fetch playlist tracks. Try again.", buttonText: "OK")
                    }
                    return
                }

                let shuffled = fisherYatesShuffle(trackURIs)
                let joined = shuffled.joined(separator: ",")
                let tracksetURI = "spotify:trackset:TrueShuffle:\(joined)"

                DispatchQueue.main.async {
                    if let url = URL(string: tracksetURI) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
}

private func fetchAllTracks(playlistId: String, token: String, completion: @escaping ([String]) -> Void) {
    var allURIs: [String] = []
    var offset = 0
    let limit = 100

    func fetch() {
        var components = URLComponents(string: "https://api.spotify.com/v1/playlists/\(playlistId)/tracks")!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "items(track(uri)),next"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        guard let url = components.url else { completion(allURIs); return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion(allURIs)
                return
            }

            for item in items {
                if let track = item["track"] as? [String: Any],
                   let uri = track["uri"] as? String,
                   uri.hasPrefix("spotify:track:") {
                    allURIs.append(uri)
                }
            }

            if let next = json["next"] as? String, !next.isEmpty {
                offset += limit
                fetch()
            } else {
                completion(allURIs)
            }
        }.resume()
    }

    fetch()
}

private func fisherYatesShuffle(_ array: [String]) -> [String] {
    var arr = array
    var i = arr.count - 1
    while i > 0 {
        let j = Int(arc4random_uniform(UInt32(i + 1)))
        arr.swapAt(i, j)
        i -= 1
    }
    return arr
}
