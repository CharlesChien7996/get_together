import Foundation
import UIKit

class Member {
    var memberID: String
    
    var email: String
    var name: String
    var profileImageURL: String
    var image: UIImage?
    
    init(memberID: String, email: String, name: String, profileImageURL: String) {
        self.memberID = memberID
        self.email = email
        self.name = name
        self.profileImageURL = profileImageURL
    }
    
    func uploadedUserData() -> Any {
        
        return ["memberID": memberID,
                "email": email,
                "name": name,
                "profileImageURL": profileImageURL]
    }
}
