import Foundation

class AlertOptionItem : NSObject, Codable {
    
    var text = ""
    var eventID = ""
    var checked = false
    
    func toggleChecked() {
        self.checked = !self.checked
    }
}
