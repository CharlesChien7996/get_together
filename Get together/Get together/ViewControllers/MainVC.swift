import UIKit
import Firebase

class MainVC: UIViewController {
    
    @IBOutlet weak var eventSegmentedControl: UISegmentedControl!
    @IBOutlet var backgroundViewWithoutLogin: UIView!
    var spinner: UIActivityIndicatorView!
    var refresher: UIRefreshControl!
    
    var joinedEventData:[Event] = []
    var hostEventData:[Event] = []
    var imageCache = FirebaseManager.shared.imageCache
    var eventIDs: Set<String> = []
    var notificationData: [Notifacation] = []
    var unreads: [Notifacation] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        // Show background view if current user is nil.
        guard Auth.auth().currentUser != nil else {
            self.tableView.backgroundView = backgroundViewWithoutLogin
            self.tableView.separatorStyle = .none
            return
        }
        
        self.setUpRefreshView()
        self.setUpActivityUndicatorView()
    
        self.queryHostEventData()
        self.queryNotification()
    }
    
    
    // Set up refresh view.
    func setUpRefreshView() {
        
        self.refresher = UIRefreshControl()
        self.refresher.tintColor = UIColor.darkGray
        self.refresher.addTarget(self, action: #selector(queryHostEventData), for: .valueChanged)
                self.refresher.addTarget(self, action: #selector(queryJoinedEventData), for: .valueChanged)
        
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

    // Background view's login button be pressed.
    @IBAction func goToLoginVC(_ sender: Any) {
        
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
        self.present(loginVC, animated: true, completion: nil)
    }
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        
        switch self.eventSegmentedControl.selectedSegmentIndex {
            
        case 0:
            guard Auth.auth().currentUser != nil else {
                
//                self.tableView.backgroundView = backgroundViewWithoutLogin
                self.tableView.separatorStyle = .none
                return
            }
            self.queryHostEventData()
            
        case 1:
            // Show background view if current user is nil.
            guard Auth.auth().currentUser != nil else {
                
//                self.tableView.backgroundView = backgroundViewWithoutLogin
                self.tableView.separatorStyle = .none
                return
            }
            
            self.queryJoinedEventData()
            
        default:
            break
        }
        
        self.tableView.reloadData()
    }
    
    
    // Query data host by self from database.
    @objc func queryHostEventData() {
        
        self.spinner.startAnimating()
        if self.hostEventData.count == 0{
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.spinner.stopAnimating()
            }
        }
        
        self.tableView.separatorStyle = .none
        
        let eventRef = FirebaseManager.shared.databaseReference.child("event").queryOrdered(byChild: "date")
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return
        }
        
        FirebaseManager.shared.getData(eventRef, type: .value) { (allObjects, dict)   in
            
            
            self.hostEventData.removeAll()
            
            for snap in allObjects {
                
                let dict = snap.value as! [String: Any]
                
                
                
                let event = Event(eventID: dict["eventID"] as! String,
                                  organiserID: dict["organiserID"] as! String,
                                  title: dict["title"] as! String,
                                  date: dict["date"] as! String,
                                  location: dict["location"] as! String,
                                  description: dict["description"] as! String,
                                  eventImageURL: dict["eventImageURL"] as! String)
                
                
                if currentUser.uid == event.organiserID {
                    self.hostEventData.insert(event, at: 0)
                    self.spinner.stopAnimating()
                    self.tableView.separatorStyle = .singleLine
                    self.refresher.endRefreshing()
                    self.tableView.reloadData()
                    
                }
            }
        }
        
        self.refresher.endRefreshing()
    }
    
    
    // Query joined data from database.
    @objc func queryJoinedEventData() {
        
        self.spinner.startAnimating()
        if self.joinedEventData.count == 0 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.spinner.stopAnimating()
            }
        }
        
        self.tableView.separatorStyle = .none
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return
        }
        
        let eventListRef = FirebaseManager.shared.databaseReference.child("eventList").child(currentUser.uid)
        
        FirebaseManager.shared.getData(eventListRef, type: .value) { (allObjects, dict)   in
            
            self.joinedEventData.removeAll()

            for snap in allObjects {
                
                
            
                let dict = snap.value as! [String: Any]
                
            
            let eventID = dict["eventID"] as! String
            
            let ref = Database.database().reference().child("event").child(eventID)
            
            FirebaseManager.shared.getData(ref, type: .value) { (allObject, dict)  in
                
                guard let dict = dict else{
                    
                    print("Fail to get dict")
                    return
                }
                
                let event = Event(eventID: dict["eventID"] as! String,
                                  organiserID: dict["organiserID"] as! String,
                                  title: dict["title"] as! String,
                                  date: dict["date"] as! String,
                                  location: dict["location"] as! String,
                                  description: dict["description"] as! String,
                                  eventImageURL: dict["eventImageURL"] as! String)
                
                self.joinedEventData.insert(event, at: 0)
                self.spinner.stopAnimating()
                self.tableView.separatorStyle = .singleLine
                self.tableView.reloadData()
                self.refresher.endRefreshing()
            }
            }
        }
    }
    
    
    func queryNotification() {
        self.notificationData.removeAll()
        
        guard let currentUser = Auth.auth().currentUser else {
            print("Fail to get current user")
            return
        }
        
        let notificationRef = FirebaseManager.shared.databaseReference.child("notification").child(currentUser.uid)
        
        FirebaseManager.shared.getData(notificationRef, type: .value) { (allObjects, dict) in
            
            self.unreads.removeAll()
            
            for snap in allObjects {
                
                let dict = snap.value as! [String : Any]
                
                let notification = Notifacation(notifacationID: dict["notifacationID"] as! String,
                                                eventID: dict["eventID"] as! String,
                                                message: dict["message"] as! String,
                                                remark: dict["remark"] as! String,
                                                isRead: dict["isRead"] as! Bool,
                                                isNew: dict["isNew"] as! Bool,
                                                isRemoved: dict["isRemoved"] as! Bool)
                
                if !notification.isRead {
                    
                    self.unreads.insert(notification, at: 0)
                }
                
                let item = self.tabBarController?.tabBar.items![1]
                item?.badgeValue = String(self.unreads.count)
                
                if item?.badgeValue == "0" {
                    item?.badgeValue = nil
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "eventContent" {
            
            let eventContentVC = segue.destination as! EventContentVC
            
            guard let indexPath = self.tableView.indexPathForSelectedRow else{
                return
            }
            
            var selectedEvent: Event!
            
            switch self.eventSegmentedControl.selectedSegmentIndex {
                
            case 0:
                selectedEvent = self.hostEventData[indexPath.row]
                eventContentVC.event = selectedEvent
                
            case 1:
                selectedEvent = self.joinedEventData[indexPath.row]
                eventContentVC.event = selectedEvent
                
            default:
                break
            }
        }
    }
    
    
    // Check current user.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        guard Auth.auth().currentUser != nil else {
            
            let alert = UIAlertController(title: "尚未登入", message: "登入來開始你的第一個聚吧！", preferredStyle: .alert)
            
            let agree = UIAlertAction(title: "登入", style: .default) { (action) in
                
                let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
                self.present(loginVC, animated: true, completion: nil)
            }
            
            let reject = UIAlertAction(title: "取消", style: .cancel)
            
            alert.addAction(agree)
            alert.addAction(reject)
            self.present(alert, animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
    
}


extension MainVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var returnValue = 0
        
        switch self.eventSegmentedControl.selectedSegmentIndex {
            
        case 0:
            returnValue = self.hostEventData.count
            break
            
        case 1:
            returnValue = self.joinedEventData.count
            break
            
        default:
            break
            
        }
        
        return returnValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyEventCell", for: indexPath) as! MyEventCell
        
        var event: Event!
        
        switch self.eventSegmentedControl.selectedSegmentIndex {
        case 0:
            event = self.hostEventData[indexPath.row]
            
        case 1:
            event = self.joinedEventData[indexPath.row]
            
        default:
            break
        }
        
        cell.eventTitle?.textColor = UIColor.black
        cell.eventDate?.textColor = UIColor.blue
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let eventDate = dateFormatter.date(from: event.date) {
            
            let now = Date()
            
            if eventDate < now {
                
                cell.eventDate?.text = "已過期"
            }else {
                
                cell.eventDate?.text = event.date
            }
        }
        
        cell.eventTitle?.text = event.title
        
        // Show image from cache if that has been stored in there.
        if let image = self.imageCache.object(forKey: event.eventImageURL as NSString) as? UIImage {
            
            event.image = image
            cell.eventImageView.image = image
        }else {
            
            // Download image from firebase storage.
            FirebaseManager.shared.getImage(urlString: event.eventImageURL) { (image) in
                
                guard let image = image else {
                    print("Fail to get image")
                    return
                }
                
                event.image = image
                cell.eventImageView?.image = image
                self.imageCache.setObject(image, forKey: event.eventImageURL as NSString)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)

    }
}
