import Foundation
import UIKit

class User {
    
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
