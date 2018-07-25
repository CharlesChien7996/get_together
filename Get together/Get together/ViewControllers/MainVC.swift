import UIKit
import Firebase

class MainVC: UITableViewController {
    
    @IBOutlet weak var eventSegmentedControl: UISegmentedControl!
    var spinner: UIActivityIndicatorView!
    var refresh: UIRefreshControl!
    @IBOutlet var backgroundViewWithoutLogin: UIView!
    
    var joinedEventData:[Event] = []
    var hostEventData:[Event] = []
    let ref = FirebaseManager.shared.databaseReference
    var imageCache = FirebaseManager.shared.imageCache
    var eventIDs: Set<String> = []
    var notificationData: [Notifacation] = []
    var unreads: [Notifacation] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        // Show background view if current user is nil.
        guard Auth.auth().currentUser != nil else {
            self.tableView.backgroundView = backgroundViewWithoutLogin
            self.tableView.separatorStyle = .none
            return
        }
        self.setUpRefreshView()
        self.setUpActivityUndicatorView()
        
        self.queryHostEventData()
        self.queryEventList()
        self.queryNotification()
        self.tableView.rowHeight = 100
    }
    
    
    // Background view's login button be pressed.
    @IBAction func goToLoginVC(_ sender: Any) {
        
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
        self.present(loginVC, animated: true, completion: nil)
    }
    
    // Set up refresh view.
    func setUpRefreshView() {
        
        self.refresh = UIRefreshControl()
        self.refresh.tintColor = UIColor.darkGray
        self.refresh.addTarget(self, action: #selector(queryHostEventData), for: .valueChanged)
        self.refresh.addTarget(self, action: #selector(queryJoinedEventData), for: .valueChanged)
        
        self.tableView.addSubview(self.refresh)
        
    }
    
    // Set up UIActivityUndicatorView.
    func setUpActivityUndicatorView() {
        
        self.spinner = UIActivityIndicatorView()
        self.spinner.activityIndicatorViewStyle = .gray
        self.spinner.center = self.view.center
        self.spinner.hidesWhenStopped = true
        //        self.tableView.separatorStyle = .none
        self.view.addSubview(self.spinner)
        
    }
    
    func queryNotification() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        
        let notificationRef = self.ref.child("notification").child(uid)
        FirebaseManager.shared.getData(notificationRef, type: .value) { (allObjects, dict) in
            self.unreads.removeAll()
            
            for snap in allObjects {
                let dict = snap.value as! [String : Any]
                
                
                let notification = Notifacation(eventID: dict["eventID"] as! String,
                                                message: dict["message"] as! String,
                                                isRead: dict["isRead"] as! Bool,
                                                isRemoved: dict["isRemoved"] as! Bool)
                
                self.notificationData.insert(notification, at: 0)
                if notification.isRead == false {
                    self.unreads.insert(notification, at: 0)
                }
                let item = self.tabBarController?.tabBar.items![1]
                
                item?.badgeValue = String(self.unreads.count)
                if item?.badgeValue == "0" {
                    item?.badgeValue = nil
                }
                
                let navi = self.tabBarController?.viewControllers?[1] as! UINavigationController
                let notificationVC = navi.viewControllers.first as! NotificationVC
                notificationVC.notificationData = self.notificationData
                
            }
        }
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
    
    // Query data host by self from database.
    @objc func queryHostEventData() {
        self.spinner.startAnimating()
        if self.hostEventData.count == 0{
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
                self.spinner.stopAnimating()
            }
        }
        
        self.tableView.separatorStyle = .none
        self.hostEventData.removeAll()
        
        let eventRef = self.ref.child("event").queryOrdered(byChild: "date")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        
        FirebaseManager.shared.getData(eventRef, type: .childAdded) { (allObject, dict)   in
            
            let event = Event(eventID: dict["eventID"] as! String,
                              organiserID: dict["organiserID"] as! String,
                              title: dict["title"] as! String,
                              date: dict["date"] as! String,
                              location: dict["location"] as! String,
                              description: dict["description"] as! String,
                              eventImageURL: dict["eventImageURL"] as! String)
            
            
            if uid == event.organiserID {
                self.hostEventData.insert(event, at: 0)
                self.spinner.stopAnimating()
                self.tableView.separatorStyle = .singleLine
                self.refresh.endRefreshing()
                self.tableView.reloadData()
            }
        }
        
        self.refresh.endRefreshing()
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
        self.joinedEventData.removeAll()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        
        let eventListRef = self.ref.child("eventList").child(uid)
        
        FirebaseManager.shared.getData(eventListRef, type: .childAdded) { (allObject, dict)   in
            
            var events: [String] = []
            let eventID = dict["eventID"] as! String
            events.append(eventID)
            
            let ref = Database.database().reference().child("event").child(events[0])
            
            FirebaseManager.shared.getData(ref, type: .value) { (allObject, dict)  in
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
                self.refresh.endRefreshing()
                
            }
        }
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
    
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        
        switch self.eventSegmentedControl.selectedSegmentIndex {
            //        case 0:
            //
            //            if self.hostEventData.count == 0
            
            // Show background view if current user is nil.
            //            guard Auth.auth().currentUser != nil else {
            //                self.tableView.backgroundView = backgroundViewWithoutLogin
            //                self.tableView.separatorStyle = .none
            //                return
            //            }
            
        case 1:
            
            // Show background view if current user is nil.
            guard Auth.auth().currentUser != nil else {
                self.tableView.backgroundView = backgroundViewWithoutLogin
                self.tableView.separatorStyle = .none
                return
            }
            
            self.queryJoinedEventData()
            
        default:
            break
        }
        self.tableView.reloadData()
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "eventContent" {
            
            let eventContentVC = segue.destination as! EventContentVC
            guard let indexPath = self.tableView.indexPathForSelectedRow else{
                return
            }
            var selectedEvent: Event
            
            switch self.eventSegmentedControl.selectedSegmentIndex {
                
            case 0:
                selectedEvent = self.hostEventData[indexPath.row] 
                eventContentVC.event = selectedEvent
                
            case 1:
                selectedEvent = self.joinedEventData[indexPath.row]
                eventContentVC.event = selectedEvent
                eventContentVC.eventIDs = self.eventIDs
                
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
