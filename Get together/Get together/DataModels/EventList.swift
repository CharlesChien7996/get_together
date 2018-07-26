import Foundation

class EventList {
    
    var eventID: String
    var isReply: Bool
    
    init(eventID: String, isReply: Bool) {
        self.eventID = eventID
        self.isReply = isReply
    }
    
    func uploadedEventListData() -> Any {
        
        return ["eventID": eventID,
                "isReply": isReply,
                ]
    }
}
