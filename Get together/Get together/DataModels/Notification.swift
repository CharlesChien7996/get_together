import Foundation

class Notifacation {
    
    var eventID: String
    var isRead: Bool
    var isRemoved: Bool
    var message: String
    
    init(eventID: String, message: String, isRead: Bool, isRemoved: Bool) {
        self.eventID = eventID
        self.message = message
        self.isRead = isRead
        self.isRemoved = isRemoved
    }
    
    func uploadNotification() -> Any{
        
        return ["eventID": self.eventID,
                "message": self.message,
                "isRead": self.isRead,
                "isRemoved": self.isRemoved]
        
    }
    
}
