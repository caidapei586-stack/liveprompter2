import Foundation

/// 调用兼容 OpenAI Chat Completions 协议的接口，根据主题生成直播台词。
/// 可对接 OpenAI / 阿里通义 / 字节方舟 等任意 OpenAI 兼容端点（在设置里改 endpoint 即可）。
struct AIScriptService {
    var endpoint: String
    var apiKey: String
    var model: String

    func generate(topic: String,
                  style: String = "口语化、适合直播口播的连贯台词",
                  completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "AI", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "API 地址无效"])))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system",
                 "content": "你是一个直播提词助手。请根据主题生成适合口播的连贯台词，直接输出台词正文，不要解释、不要序号、不要 markdown 符号。"],
                ["role": "user",
                 "content": "主题：\(topic)。风格：\(style)。"]
            ],
            "temperature": 0.8
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err { completion(.failure(err)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "AI", code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "无返回数据"])))
                return
            }
            // 解析 OpenAI 标准结构
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let msg = choices.first?["message"] as? [String: Any],
               let content = msg["content"] as? String {
                completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let error = json["error"] as? [String: Any],
                      let message = error["message"] as? String {
                completion(.failure(NSError(domain: "AI", code: -3,
                    userInfo: [NSLocalizedDescriptionKey: message])))
            } else {
                completion(.failure(NSError(domain: "AI", code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "无法解析接口返回"])))
            }
        }
        task.resume()
    }
}
