import Foundation

struct User: Codable {
    let id: UUID
    let email: String?
    var name: String?
    var profileImageUrl: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
    }
} 