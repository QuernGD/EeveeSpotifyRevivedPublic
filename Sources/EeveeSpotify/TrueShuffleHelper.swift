import Foundation
import UIKit

func playTrueShuffle(playlistURI: String) {
    guard let token = spotifyAccessToken else {
        DispatchQueue.main.async {
            PopUpHelper.showPopUp(message: "No Spotify token available. Open a playlist first.", buttonText: "OK")
        }
        return
    }

    let parts = playlistURI.components(separatedBy: ":")
    guard parts.count >= 3, parts[1] == "playlist" else {
        DispatchQueue.main.async {
            PopUpHelper.showPopUp(message: "Could not find current playlist. Make sure you are playing from a playlist.", buttonText: "OK")
        }
        return
    }
    let playlistId = parts[2]

    DispatchQueue.global(qos: .userInitiated).async {
        fetchAllTracks(playlistId: playlistId, token: token) { trackURIs, debugMessage in
            guard !trackURIs.isEmpty else {
                DispatchQueue.main.async {
                    PopUpHelper.showPopUp(message: "Could not fetch tracks. Debug: \(debugMessage)", buttonText: "OK")
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

private func fetchAllTracks(playlistId: String, token: String, completion: @escaping ([String], String) -> Void) {
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

        guard let url = components.url else { completion(allURIs, "Bad URL"); return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(allURIs, "Network error: \(error.localizedDescription)")
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard let data = data else {
                completion(allURIs, "No data, status: \(statusCode)")
                return
            }

            // Log raw response for debugging
            let rawString = String(data: data, encoding: .utf8) ?? "unreadable"
            writeDebugLog("[TrueShuffle-API] status=\(statusCode) body=\(rawString.prefix(300))")

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion(allURIs, "Parse error, status: \(statusCode), body: \(rawString.prefix(100))")
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
                completion(allURIs, "OK, \(allURIs.count) tracks")
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
