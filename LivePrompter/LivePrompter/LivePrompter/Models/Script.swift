import Foundation

/// 一段直播台词
struct Script: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         title: String = "未命名台词",
         content: String = "",
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
