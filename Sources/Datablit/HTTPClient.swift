import Foundation

class HTTPClient {
    static func post(url: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let requestURL = URL(string: url) else {
            completion(false)
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            completion(success)
        }.resume()
    }
}

