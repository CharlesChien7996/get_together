import UIKit
import Firebase

class MainVC: UITableViewController {
    
    @IBOutlet weak var eventSegmentedControl: UISegmentedControl!
    var ActivityIndicator: UIActivityIndicatorView!

    var joinedEventData:[Event] = []
    var hostEventData:[Event] = []
    let ref = FirebaseManager.shared.databaseReference

    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        // ActivityIndicatorを作成＆中央に配置
        ActivityIndicator = UIActivityIndicatorView()
        ActivityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        ActivityIndicator.center = self.view.center
        
        // クルクルをストップした時に非表示する
        ActivityIndicator.hidesWhenStopped = true
        
        // 色を設定
        ActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        
        //Viewに追加
        self.view.addSubview(ActivityIndicator)
        */
        self.queryJoinedEventData()
        self.queryHostEventData()

        self.tableView.rowHeight = 100
    }
    
    

    // Query data host by self from database.
    func queryHostEventData() {
        
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
            
            
            
            // 在viewDidLoad就先下載圖片
            let task = FirebaseManager.shared.getImage(urlString: event.eventImageURL) { (image) in
                let smallImage = FirebaseManager.shared.thumbnail(image)
                event.image = smallImage
                if uid == event.organiserID {
                    self.hostEventData.insert(event, at: 0)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
            task.resume()// 在viewDidLoad就先下載圖片

        }
        
        /* old.
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        
        let ref = Database.database().reference().child("event").queryOrdered(byChild: "date")
        ref.observe(.childAdded) { (snapshot) in
            
            guard let dict = snapshot.value as? [String : Any] else {
                print("Fail to get data")
                return
            }
            
            let event = Event(eventID: dict["eventID"] as! String,
                              organiserID: dict["organiserID"] as! String,
                              title: dict["title"] as! String,
                              date: dict["date"] as! String,
                              description: dict["description"] as! String,
                              eventImageURL: dict["imageURL"] as! String)
            
            if uid == event.organiserID {
                self.hostEventData.insert(event, at: 0)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }*/
    }
    
    // Query joined data from database.
    func queryJoinedEventData() {
        
//        ActivityIndicator.startAnimating()

        
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
                
                // 在viewDidLoad就先下載圖片
                let task = FirebaseManager.shared.getImage(urlString: event.eventImageURL) { (image) in
                    let smallImage = FirebaseManager.shared.thumbnail(image)
                    event.image = smallImage
                    self.joinedEventData.insert(event, at: 0)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
//                        self.ActivityIndicator.stopAnimating()
                        
                    }
                }
                task.resume()// 在viewDidLoad就先下載圖片

                
            }
    
        }
        
        /* old
        let ref = Database.database().reference().child("eventList").child(uid)
        ref.observe(.childAdded) { (snapshot) in
            
            guard let dict = snapshot.value as? [String : Any] else {
                print("Fail to get data")
                return
            }
            var events: [String] = []
            let eventID = dict["eventID"] as! String
            events.append(eventID)
            

                let ref = Database.database().reference().child("event").child(events[0])
                ref.observe(.value) { (snapshot) in
                    
                    guard let dict = snapshot.value as? [String : Any] else {
                        print("Fail to get data")
                        return
                    }
                    let event = Event(eventID: dict["eventID"] as! String,
                                      organiserID: dict["organiserID"] as! String,
                                      title: dict["title"] as! String,
                                      date: dict["date"] as! String,
                                      description: dict["description"] as! String,
                                      eventImageURL: dict["imageURL"] as! String)
                    
                    self.joinedEventData.insert(event, at: 0)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                }
        }*/
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        cell.eventTitle.text = event.title
        cell.eventImageView.image = event.image
        
        /* 在cellForRow才下載圖片
//        // Download image from firebase storage.
//        let task = FirebaseManager.shared.getImage(urlString: event.eventImageURL) { (image) in
//            let smallImage = FirebaseManager.shared.thumbnail(image)
//            event.image = image
//            DispatchQueue.main.async {
//                cell.eventTitle?.textColor = UIColor.black
//                cell.eventDate?.textColor = UIColor.blue
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
//                if let eventDate = dateFormatter.date(from: event.date) {
//                    let now = Date()
//                    if eventDate < now {
//                        cell.eventDate?.text = "已過期"
//                    }else {
//                        cell.eventDate?.text = event.date
//
//                    }
//                }
//                cell.eventTitle?.text = event.title
//                cell.eventImageView?.image = smallImage
//            }
//        }
//        task.resume()
 */
        return cell

        
        
        /* old
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
            let smallImage = self.thumbnail(image)
            event.image = image
            DispatchQueue.main.async {
                cell.eventTitle?.textColor = UIColor.black
                cell.eventDate?.textColor = UIColor.blue
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
                if let eventDate = dateFormatter.date(from: event.date) {
                    let now = Date()
                    if eventDate < now {
                        cell.eventDate?.text = "已過期"
                    }else {
                        cell.eventDate?.text = event.date

                    }
                }
                cell.eventTitle?.text = event.title
                cell.eventImageView?.image = smallImage
            }
        }
        task.resume()*/
    }
    

    @IBAction func segmentedControlChanged(_ sender: Any) {
        self.tableView.reloadData()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
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
            default:
                break
            }
            
        }
    }
}
