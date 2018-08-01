import UIKit
import Firebase


class NotificationVC: UITableViewController {
    
    @IBOutlet var backgroundViewWithoutLogin: UIView!
    var joinedEventData: [Event] = []
    var notificationData: [Notifacation] = []
    
    var user: GUser!
    var eventIDs: Set<String> = []
    let ref = FirebaseManager.shared.databaseReference
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
    var refresher: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        
        // Show background view if current user is nil.
        guard let currentUser = Auth.auth().currentUser else {
            self.tableView.backgroundView = backgroundViewWithoutLogin
            self.tableView.separatorStyle = .none
            return
        }
        
        self.setUpRefreshView()
        FirebaseManager.shared.setUpActivityUndicatorView(self.view, activityIndicatorView: self.spinner)
        self.queryNotification(currentUser)
    }
    
    @objc func refreshData() {
        
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        self.queryNotification(currentUser)
        
        self.refresher.endRefreshing()
        
    }
    
    func queryNotification(_ currentUser: User) {
        
        self.tableView.separatorStyle = .none
        self.spinner.startAnimating()
        
        if self.notificationData.count == 0 {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.spinner.stopAnimating()
                self.tableView.separatorStyle = .singleLine
                self.tableView.reloadData()
            }
        }
        
        
        let notificationRef = FirebaseManager.shared.databaseReference.child("notification").child(currentUser.uid).queryOrdered(byChild: "time")
        
        FirebaseManager.shared.getData(notificationRef, type: .value) { (allObjects, dict) in
            
            
            for snap in allObjects {
                self.notificationData.removeAll()
                self.joinedEventData.removeAll()

                let dict = snap.value as! [String : Any]
                
                let notification = Notifacation(notifacationID: dict["notifacationID"] as! String,
                                                eventID: dict["eventID"] as! String,
                                                message: dict["message"] as! String,
                                                remark: dict["remark"] as! String,
                                                isRead: dict["isRead"] as! Bool,
                                                time: dict["time"] as! String,
                                                isRemoved: dict["isRemoved"] as! Bool)
                
                let ref = Database.database().reference().child("event").child(notification.eventID)
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
                    
                    // Download image from firebase storage.
                    FirebaseManager.shared.getImage(urlString: urlString){ (image) in
                        event.image = image
                        
                    }
                    self.notificationData.insert(notification, at: 0)
                    self.joinedEventData.insert(event, at: 0)
                    self.spinner.stopAnimating()
                    self.tableView.separatorStyle = .singleLine
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    // Set up refresh view.
    func setUpRefreshView() {
        
        self.refresher = UIRefreshControl()
        self.refresher.tintColor = UIColor.darkGray
        self.refresher.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        self.tableView.addSubview(self.refresher)
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
    
    
    @IBAction func loginPressed(_ sender: Any) {
        
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
        self.present(loginVC, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noticeCell", for: indexPath)
        let notification = self.notificationData[indexPath.row]
        
        if !notification.isRead {
            cell.backgroundColor = UIColor.orange.withAlphaComponent(0.1)
            cell.textLabel?.backgroundColor = UIColor.clear
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
            let selectedNotification = self.notificationData[indexPath.row]
            eventContentVC.event = selectedEvent
            eventContentVC.notification = selectedNotification
            
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
