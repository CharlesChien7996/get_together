import Foundation
import UIKit

class Event {
    
    var eventID: String
    var title: String
    var date: String
    var location: String
    var description: String
    var eventImageURL: String
    var organiserID: String
    var image: UIImage?
    
    init(eventID: String, organiserID: String, title: String, date: String, location: String, description: String, eventImageURL: String) {
        self.eventID = eventID
        self.title = title
        self.organiserID = organiserID
        self.date = date
        self.location = location
        self.description = description
        self.eventImageURL = eventImageURL
        
        
    }
    
    func uploadedEventData() -> Any {
        
        return ["eventID": eventID,
                "organiserID": organiserID,
                "title": title,
                "date": date,
                "location": location,
                "description": description,
                "eventImageURL": eventImageURL]
    }
}


