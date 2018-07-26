import Foundation
import UIKit

class User: Hashable {
    
    var hashValue : Int {
        get {
            return "\(self.userID)".hashValue
        }
    }
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    
    var userID: String
    var email: String
    var name: String
    var profileImageURL: String
    var image: UIImage?
    
    init(userID: String, email: String, name: String, profileImageURL: String) {
        self.userID = userID
        self.email = email
        self.name = name
        self.profileImageURL = profileImageURL
    }
    
    func uploadedUserData() -> Any {
        
        return ["userID": userID,
                "email": email,
                "name": name,
                "profileImageURL": profileImageURL]
    }
}
