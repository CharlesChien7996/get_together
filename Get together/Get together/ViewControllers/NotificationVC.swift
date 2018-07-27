import UIKit
import Firebase


class NotificationVC: UITableViewController {
    
    var joinedEventData: [Event] = []
    var notificationData: [Notifacation] = []
    
    var user: GUser!
    var eventIDs: Set<String> = []
    let ref = FirebaseManager.shared.databaseReference
    var spinner: UIActivityIndicatorView!
    var refresher: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.setUpRefreshView()
        self.setUpActivityUndicatorView()
        self.queryNotification()
    }
    
    @objc func queryNotification() {
        
        self.spinner.startAnimating()
        if self.notificationData.count == 0 {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.spinner.stopAnimating()
            }
        }
        self.tableView.separatorStyle = .none

        
        guard let currentUser = Auth.auth().currentUser else {
            print("Fail to get current user")
            return
        }
        
        let notificationRef = FirebaseManager.shared.databaseReference.child("notification").child(currentUser.uid)
        
        FirebaseManager.shared.getData(notificationRef, type: .value) { (allObjects, dict) in
            
            self.notificationData.removeAll()
            
            for snap in allObjects {
                
                let dict = snap.value as! [String : Any]
                
                let notification = Notifacation(notifacationID: dict["notifacationID"] as! String,
                                                eventID: dict["eventID"] as! String,
                                                message: dict["message"] as! String,
                                                remark: dict["remark"] as! String,
                                                isRead: dict["isRead"] as! Bool,
                                                isNew: dict["isNew"] as! Bool,
                                                isRemoved: dict["isRemoved"] as! Bool)
                
                self.notificationData.insert(notification, at: 0)

            }
            self.joinedEventData.removeAll()

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
                    
                    self.joinedEventData.append(event)
                        self.spinner.stopAnimating()
                        self.tableView.separatorStyle = .singleLine
                        self.tableView.reloadData()
                }

            }
            self.refresher.endRefreshing()

        }
    }
    
//    // Query joined data from database.
//    func queryEventData() {
//
//        for event in self.notificationData {
//            let ref = Database.database().reference().child("event").child(event.eventID)
//            ref.observe(.value) { (snapshot) in
//
//                guard let dict = snapshot.value as? [String : Any] else {
//                    print("Fail to get data")
//                    return
//                }
//                let event = Event(eventID: dict["eventID"] as! String,
//                                  organiserID: dict["organiserID"] as! String,
//                                  title: dict["title"] as! String,
//                                  date: dict["date"] as! String,
//                                  location: dict["location"] as! String,
//                                  description: dict["description"] as! String,
//                                  eventImageURL: dict["eventImageURL"] as! String)
//
//                let urlString = event.eventImageURL
//
//
//                guard let imageURL = URL(string: urlString) else {
//                    print("Fail to get imageURL")
//                    return
//                }
//
//                // Download image from firebase storage.
//                let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
//                    if let error = error {
//                        print("Download image task fail: \(error.localizedDescription)")
//                        return
//                    }
//
//                    guard let imageData = data else {
//                        print("Fail to get imageData")
//                        return
//                    }
//
//                    let image = UIImage(data: imageData)
//                    event.image = image!
//                }
//                task.resume()
//
//                self.joinedEventData.append(event)
//                self.tableView.reloadData()
//            }
//        }
//
//    }
    
    
    // Set up refresh view.
    func setUpRefreshView() {
        
        self.refresher = UIRefreshControl()
        self.refresher.tintColor = UIColor.darkGray
        self.refresher.addTarget(self, action: #selector(queryNotification), for: .valueChanged)
        self.refresher.addTarget(self, action: #selector(queryNotification), for: .valueChanged)
        
        self.tableView.addSubview(self.refresher)
    }
    
    
    // Set up UIActivityUndicatorView.
    func setUpActivityUndicatorView() {
        
        self.spinner = UIActivityIndicatorView()
        self.spinner.activityIndicatorViewStyle = .gray
        self.spinner.center = self.view.center
        self.spinner.hidesWhenStopped = true
        self.view.addSubview(self.spinner)
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
        
        if !notification.isRead {
            cell.backgroundColor = UIColor.magenta
        }else {
            cell.backgroundColor = UIColor.white
        }
        
            cell.textLabel?.text = notification.message
            cell.detailTextLabel?.text = notification.remark
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = self.notificationData[indexPath.row]
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        self.ref.child("notification").child(uid).child(notification.notifacationID).updateChildValues(["isRead" : true])

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
