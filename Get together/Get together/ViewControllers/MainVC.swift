import UIKit
import Firebase
import SVProgressHUD

class MainVC: UIViewController {
    
    
    @IBOutlet weak var eventSegmentedControl: UISegmentedControl!
    @IBOutlet var backgroundViewWithoutLogin: UIView!
    var refresher: UIRefreshControl!
    var joinedEventData:[Event] = []
    var hostEventData:[Event] = []
    var imageCache = FirebaseManager.shared.imageCache
    var unreads: [GNotification] = []
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUserLogin), name: NSNotification.Name("login"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUserLogout), name: NSNotification.Name("logout"), object: nil)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        // Show background view if current user is nil.
        guard let currentUser = Auth.auth().currentUser else {
            self.tableView.backgroundView = backgroundViewWithoutLogin
            self.tableView.separatorStyle = .none
            return
        }
        self.setUpRefreshView()

        self.queryHostEventData(currentUser)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    
    @objc func didUserLogin() {
        
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        if self.refresher == nil {
            self.setUpRefreshView()
        }
        
        self.tableView.backgroundView = nil
        self.tableView.separatorStyle = .singleLine
        self.queryHostEventData(currentUser)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.queryNotificationCount(currentUser)
    }
    
    
    @objc func didUserLogout() {
        
        self.hostEventData.removeAll()
        self.joinedEventData.removeAll()
        
        if self.refresher != nil {
            self.refresher.removeFromSuperview()
            self.refresher = nil
        }
        self.tableView.backgroundView = backgroundViewWithoutLogin
        self.tableView.separatorStyle = .none
        self.tableView.reloadData()
    }
    
    
    // Set up refresh view.
    func setUpRefreshView() {
        
        self.refresher = UIRefreshControl()
        self.refresher.tintColor = UIColor.darkGray
        self.refresher.addTarget(self, action: #selector(self.refreshData), for: .valueChanged)
        self.refresher.addTarget(self, action: #selector(self.refreshData), for: .valueChanged)
        
        self.tableView.addSubview(self.refresher)
    }
    
    
    @objc func refreshData() {
        
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        self.queryHostEventData(currentUser)
        self.refresher.endRefreshing()
    }
    
    // Background view's login button be pressed.
    @IBAction func goToLoginVC(_ sender: Any) {
        
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
        self.present(loginVC, animated: true, completion: nil)
    }
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        
        guard Auth.auth().currentUser != nil else {
            return
        }
        self.tableView.reloadData()
    }
    
    
    // Query data host by self from database.
    func queryHostEventData(_ currentUser: User) {
        SVProgressHUD.show(withStatus: "載入中...")
        
        if self.hostEventData.count == 0 && self.joinedEventData.count == 0{
            
                SVProgressHUD.dismiss(withDelay: 1.0)
                self.tableView.reloadData()
            
        }
        let eventRef = FirebaseManager.shared.databaseReference.child("event").queryOrdered(byChild: "date")
        
        FirebaseManager.shared.getData(eventRef, type: .value) { (allObjects, dict)   in
            self.hostEventData.removeAll()
            self.joinedEventData.removeAll()
            
            let myEvent = allObjects.compactMap{ (snap) -> Event? in
                
                let dict = snap.value as! [String: Any]
                let event = Event(eventID: dict["eventID"] as! String,
                                  organiserID: dict["organiserID"] as! String,
                                  title: dict["title"] as! String,
                                  memberIDs: dict["memberIDs"] as! [String],
                                  date: dict["date"] as! String,
                                  location: dict["location"] as! String,
                                  description: dict["description"] as! String,
                                  eventImageURL: dict["eventImageURL"] as! String)
                
                return (event.organiserID == currentUser.uid ? event : nil)
            }
            
            
            let joinedEvent = allObjects.compactMap{ (snap) -> Event? in
                
                let dict = snap.value as! [String: Any]
                let event = Event(eventID: dict["eventID"] as! String,
                                  organiserID: dict["organiserID"] as! String,
                                  title: dict["title"] as! String,
                                  memberIDs: dict["memberIDs"] as! [String],
                                  date: dict["date"] as! String,
                                  location: dict["location"] as! String,
                                  description: dict["description"] as! String,
                                  eventImageURL: dict["eventImageURL"] as! String)
                
                let membersSet = Set(event.memberIDs)
                
                return (membersSet.contains(currentUser.uid) ? event : nil)
            }
            
            self.joinedEventData = joinedEvent.reversed()
            self.hostEventData = myEvent.reversed()

            DispatchQueue.main.async {
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
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
            
            let alert = UIAlertController(title: "尚未登入", message: "登入開始聚聚吧！", preferredStyle: .alert)
            
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
                DispatchQueue.main.async {
                    event.image = image
                    cell.eventImageView?.image = image
                }
                self.imageCache.setObject(image, forKey: event.eventImageURL as NSString)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
