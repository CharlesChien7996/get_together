import UIKit
import Firebase


class NotificationVC: UITableViewController {
    
    var joinedEventData: [Event] = []
    var notificationData: [Notifacation] = []
    
    var user: User!
    var eventIDs: Set<String> = []
    let ref = FirebaseManager.shared.databaseReference
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.queryEventData()
        self.queryEventList()
    }
    
    func queryEventList() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        
        let ref = Database.database().reference().child("eventList").child(uid)
        
        FirebaseManager.shared.getDataBySingleEvent(ref, type: .childAdded) { (allObject, dict) in
            
            guard let dict = dict else {
                print("Fail to get data")
                return
            }
            
            let eventID = dict["eventID"] as! String
            self.eventIDs.insert(eventID)
        }
    }
    
    // Query joined data from database.
    func queryEventData() {
        
        for event in self.notificationData {
            let ref = Database.database().reference().child("event").child(event.eventID)
            ref.observe(.value) { (snapshot) in
                
                guard let dict = snapshot.value as? [String : Any] else {
                    print("Fail to get data")
                    return
                }
                let event = Event(eventID: dict["eventID"] as! String,
                                  organiserID: dict["organiserID"] as! String,
                                  title: dict["title"] as! String,
                                  date: dict["date"] as! String,
                                  location: dict["location"] as! String,
                                  description: dict["description"] as! String,
                                  eventImageURL: dict["eventImageURL"] as! String)
                
                let urlString = event.eventImageURL
                
                
                guard let imageURL = URL(string: urlString) else {
                    print("Fail to get imageURL")
                    return
                }
                
                // Download image from firebase storage.
                let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                    if let error = error {
                        print("Download image task fail: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let imageData = data else {
                        print("Fail to get imageData")
                        return
                    }
                    
                    let image = UIImage(data: imageData)
                    event.image = image!
                }
                task.resume()
                
                
                self.joinedEventData.insert(event, at: 0)
                self.tableView.reloadData()
            }
        }
        
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.notificationData.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noticeCell", for: indexPath)
        let notification = self.notificationData[indexPath.row]
        DispatchQueue.main.async {
            cell.textLabel?.text = notification.message
        }
        return cell
    }
    
    
    // Convert image into thumbnail.
    func thumbnail(_ image: UIImage?) -> UIImage? {
        guard let image = image else {
            print("Fail to get imageData")
            return nil
        }
        
        let thumbnailSize = CGSize(width: 80, height: 80)
        let scale = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, scale)
        
        let widthRatio = thumbnailSize.width / image.size.width
        let heightRatio = thumbnailSize.height / image.size.height
        
        let ratio = max(widthRatio, heightRatio)
        
        let imageSize = CGSize(width: image.size.width*ratio, height: image.size.height*ratio)
        let cgRect = CGRect(x: -(imageSize.width - thumbnailSize.width) / 2, y: -(imageSize.height - thumbnailSize.height) / 2, width: imageSize.width, height: imageSize.height)
        image.draw(in: cgRect)
        
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return smallImage
    }
    
    
    
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = self.notificationData[indexPath.row]
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        self.ref.child("notification").child(uid).child(notification.eventID).updateChildValues(["isRead" : true])
        
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "eventContent" {
            let eventContentVC = segue.destination as! EventContentVC
            guard let indexPath = self.tableView.indexPathForSelectedRow else{
                return
            }
            
            let selectedEvent = self.joinedEventData[indexPath.row]
            
            eventContentVC.event = selectedEvent
            eventContentVC.eventIDs = self.eventIDs
            
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "eventContent" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else{
                return false
            }
            let selectedNotification = self.notificationData[indexPath.row]
            if selectedNotification.isRemoved == true {
                return false
            }
        }
        return true
    }
    
    
}
