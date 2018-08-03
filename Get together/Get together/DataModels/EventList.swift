import Foundation

class EventList {
    
    var eventID: String
    var isReply: Bool
    var isMember: Bool
    
    init(eventID: String, isReply: Bool, isMember: Bool) {
        self.eventID = eventID
        self.isReply = isReply
        self.isMember = isMember
    }
    
    func uploadedEventListData() -> Any {
        
        return ["eventID": eventID,
                "isReply": isReply,
                "isMember": isMember
                ]
    }
}
