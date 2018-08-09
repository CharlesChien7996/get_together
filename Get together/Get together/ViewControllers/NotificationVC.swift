import UIKit
import Firebase
import SVProgressHUD

class NotificationVC: UITableViewController {
    
    @IBOutlet var backgroundViewWithoutLogin: UIView!
    var joinedEventData: [Event] = []
    var notificationData: [GNotification] = []
    
    var user: GUser!
    var eventIDs: Set<String> = []
    let ref = FirebaseManager.shared.databaseReference
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
    var refresher: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(didUserLogin), name: NSNotification.Name("login"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUserLogout), name: NSNotification.Name("logout"), object: nil)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        
        // Show background view if current user is nil.
        guard let currentUser = Auth.auth().currentUser else {
            self.tableView.backgroundView = backgroundViewWithoutLogin
            self.tableView.separatorStyle = .none
            return
        }
        self.setUpRefreshView()

        self.queryNotification(currentUser)
    }
    
    @objc func refreshData() {
        
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        self.queryNotification(currentUser)
        
        self.refresher.endRefreshing()
        
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func didUserLogin() {
        
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        self.tableView.backgroundView = nil
        self.tableView.separatorStyle = .singleLine
        self.queryNotification(currentUser)
    }
    
    
    @objc func didUserLogout() {
        
        self.notificationData.removeAll()
        self.joinedEventData.removeAll()
        self.tableView.backgroundView = backgroundViewWithoutLogin
        self.tableView.separatorStyle = .none
        self.tableView.reloadData()
    }
    
    
    func queryNotification(_ currentUser: User) {

        SVProgressHUD.show(withStatus: "載入中...")

        if self.notificationData.count == 0 {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                
                SVProgressHUD.dismiss()
                self.tableView.reloadData()
            }
        }
        
        
        let notificationRef = FirebaseManager.shared.databaseReference.child("notification").queryOrdered(byChild: "time")
        
        FirebaseManager.shared.getData(notificationRef, type: .value) { (allObjects, dict) in

            SVProgressHUD.show(withStatus: "載入中...")

            self.notificationData.removeAll()
            self.joinedEventData.removeAll()
            
            let myNotification = allObjects.compactMap {(snap) -> GNotification? in
                
                let dict = snap.value as! [String : Any]
                
                let notification = GNotification(notificationID: dict["notificationID"] as! String,
                                                 userID: dict["userID"] as! String,
                                                 eventID: dict["eventID"] as! String,
                                                 message: dict["message"] as! String,
                                                 remark: dict["remark"] as! String,
                                                 isRead: dict["isRead"] as! Bool,
                                                 time: dict["time"] as! String,
                                                 isRemoved: dict["isRemoved"] as! Bool)
                
                return (currentUser.uid == notification.userID ? notification : nil)
            }
            
            
            self.notificationData = myNotification
            self.notificationData.sort() { (GNoti1, GNoti2) -> Bool in
                return GNoti1.time > GNoti2.time
            }
            for notification in self.notificationData {
                
                let ref = Database.database().reference().child("event").child(notification.eventID)
                FirebaseManager.shared.getDataBySingleEvent(ref, type: .value){ (allObjects, dict) in
                    
                    guard let dict = dict else {
                        print("Fail to get data")
                        return
                    }
                    
                    let event = Event(eventID: dict["eventID"] as! String,
                                      organiserID: dict["organiserID"] as! String,
                                      title: dict["title"] as! String,
                                      memberIDs: dict["memberIDs"] as! [String],
                                      date: dict["date"] as! String,
                                      location: dict["location"] as! String,
                                      description: dict["description"] as! String,
                                      eventImageURL: dict["eventImageURL"] as! String)
                    
                    let urlString = event.eventImageURL
                    
                    // Download image from firebase storage.
                    FirebaseManager.shared.getImage(urlString: urlString){ (image) in
                        event.image = image
                        
                    }
                    
                    //                    self.notificationData.insert(notification, at: 0)
                    self.joinedEventData.append(event)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        SVProgressHUD.dismiss()
                    }
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
        self.tableView.deselectRow(at: indexPath, animated: true)
        let notification = self.notificationData[indexPath.row]
        
        
        self.ref.child("notification").child(notification.notificationID).updateChildValues(["isRead" : true])
        
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
