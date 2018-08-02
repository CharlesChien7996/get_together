import Foundation

class GNotification {
    
    var notificationID: String
    var userID: String
    var eventID: String
    var isRead: Bool
    var time: String
    var isRemoved: Bool
    var message: String
    var remark: String

    
    init(notificationID: String, userID: String, eventID: String, message: String, remark: String, isRead: Bool, time: String, isRemoved: Bool) {
        
        self.notificationID = notificationID
        self.userID = userID
        self.eventID = eventID
        self.message = message
        self.remark = remark
        self.isRead = isRead
        self.time = time
        self.isRemoved = isRemoved
    }
    
    func uploadNotification() -> Any{
        
        return ["notificationID": self.notificationID,
                "userID": self.userID,
                "eventID": self.eventID,
                "message": self.message,
                "remark": self.remark,
                "isRead": self.isRead,
                "time": self.time,
                "isRemoved": self.isRemoved]
        
    }
    
}
