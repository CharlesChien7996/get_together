import Foundation

class Comment {
    
    var commentID: String
    var eventID: String
    var userID: String
    var content: String
    var time: String
    
    
    
    init(eventID: String, commentID: String, userID: String, content: String, time: String) {
        
        self.eventID = eventID
        self.commentID = commentID
        self.userID = userID
        self.content = content
        self.time = time
    }
    
    func uploadedCommentData() -> Any {
        
        return ["eventID": eventID,
                "commentID": commentID,
                "userID": userID,
                "content": content,
                "time": time]
    }
}


