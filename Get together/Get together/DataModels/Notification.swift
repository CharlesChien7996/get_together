import Foundation

class Notifacation {
    
    var notifacationID: String
    var eventID: String
    var isRead: Bool
    var isRemoved: Bool
    var message: String
    var remark: String

    
    init(notifacationID: String, eventID: String, message: String, remark: String, isRead: Bool, isRemoved: Bool) {
        
        self.notifacationID = notifacationID
        self.eventID = eventID
        self.message = message
        self.remark = remark
        self.isRead = isRead
        self.isRemoved = isRemoved
    }
    
    func uploadNotification() -> Any{
        
        return ["notifacationID": self.notifacationID,
                "eventID": self.eventID,
                "message": self.message,
                "remark": self.remark,
                "isRead": self.isRead,
                "isRemoved": self.isRemoved]
        
    }
    
}
