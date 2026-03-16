import Foundation
import UIKit

private let kClientId = "ceab4c6308de4133a70d1fbe643c4b8b"
private let kRefreshToken = "AQBEFV8iMB0faN0Eh7QzwoaqpKoBi7AwSzIJTb2XBsYRulUAZUtLso-mx-H1QkgvvKELJjt5YGqCJRAiQQJ6unW9Z-jAZIryKT28CY7-1VqW4DZxUH0WohMmhnjSnXKOS7I"

private let trueshuffleSession: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 15
    return URLSession(configuration: config)
}()

private func refreshAccessToken(completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
        completion(nil); return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = "grant_type=refresh_token&refresh_token=\(kRefreshToken)&client_id=\(kClientId)".data(using: .utf8)

    trueshuffleSession.dataTask(with: request) { data, response, error in
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let raw = data.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
        writeDebugLog("[TrueShuffle] refreshToken status=\(status) body=\(raw.prefix(200))")
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else {
            completion(nil); return
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
    writeDebugLog("[TrueShuffle] playlistId=\(playlistId)")

    DispatchQueue.global(qos: .userInitiated).async {
        refreshAccessToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    PopUpHelper.showPopUp(message: "Could not get Spotify token. Check your internet connection.", buttonText: "OK")
                }
                return
            }
            writeDebugLog("[TrueShuffle] got token, fetching tracks")

            fetchAllTracks(playlistId: playlistId, token: token) { trackURIs in
                writeDebugLog("[TrueShuffle] got \(trackURIs.count) tracks")
                guard !trackURIs.isEmpty else {
                    DispatchQueue.main.async {
                        PopUpHelper.showPopUp(message: "Could not fetch playlist tracks. Try again.", buttonText: "OK")
                    }
                    return
                }

                let shuffled = fisherYatesShuffle(trackURIs)
                let joined = shuffled.joined(separator: ",")
                let tracksetURI = "spotify:trackset:TrueShuffle:\(joined)"
                writeDebugLog("[TrueShuffle] opening trackset with \(shuffled.count) tracks")

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

        trueshuffleSession.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let raw = data.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
            writeDebugLog("[TrueShuffle] tracks status=\(status) body=\(raw.prefix(200))")

            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                completion(allURIs); return
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
