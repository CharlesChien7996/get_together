import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import MapKit

class EventContentVC: UITableViewController {
    
    @IBOutlet weak var organiserName: UILabel!
    @IBOutlet weak var organiserProfileImage: UIImageView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var memberCollectionView: UICollectionView!
    @IBOutlet weak var eventLocation: UILabel!
    @IBOutlet weak var eventLocationMap: MKMapView!
    @IBOutlet weak var eventDescription: UILabel!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    
    var user: GUser!
    var event: Event!
    var imageCache = FirebaseManager.shared.imageCache
    var region: MKCoordinateRegion!
    var annotation: MKPointAnnotation!
    var memberData: [GUser] = []
    var eventListData: [EventList] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.editBtn.title = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        
        self.eventTitle.text = self.event.title
        self.eventDate.text = self.event.date
        self.eventLocation.text = self.event.location
        self.eventDescription.text = self.event.description
        self.eventImageView.image = self.event.image
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return
        }
        
        if currentUser.uid == self.event.organiserID {
            
            self.editBtn.title = "編輯"
            self.editBtn.isEnabled = true
        }
        
        self.setLocationAnnotation()
        self.queryEventList()
        self.queryUserData()
        self.queryOrganiserData()
        self.queryMemberData()
        self.memberCollectionView.dataSource = self
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        switch indexPath.row {
//        case 0 :
//            return UITableViewAutomaticDimension
//            
//        case 1:
//            return UITableViewAutomaticDimension
//            
//        case 2:
//            return 100
//            
//        case 3:
//            return 110
//            
//        case 4 :
//            return 44
//            
//        case 5:
//            return 177
//            
//        case 6:
//            return UITableViewAutomaticDimension
//            
//        default:
//            break
//        }
        
        return UITableViewAutomaticDimension
    }
    
    
    func setLocationAnnotation() {
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(self.event.location) { (placemarks, error) in
            
            if let error = error {
                
                print(error.localizedDescription)
                return
            }
            
            guard let placemarks = placemarks else {
                
                print("Fail to get placemarks")
                return
            }
            
            let annotation = MKPointAnnotation()
            
            guard let location = placemarks[0].location else {
                
                print("Fail to get placemarks[0].location")
                return
            }
            
            annotation.coordinate = location.coordinate
            annotation.title = self.event.location
            self.annotation = annotation
            self.eventLocationMap.addAnnotation(annotation)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
            self.region = region
            self.eventLocationMap.setRegion(region, animated: false)
        }
    }
    
    
    func queryEventList() {
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return
        }
        
        let ref = FirebaseManager.shared.databaseReference
        let eventListRef = ref.child("eventList").child(currentUser.uid)
        
        FirebaseManager.shared.getData(eventListRef, type: .value) { (allObjects, dict) in
            
            for snap in allObjects {
                
                let dict = snap.value as! [String : Any]
                
                let eventList = EventList(eventID: dict["eventID"] as! String,
                                          isReply: dict["isReply"] as! Bool)
                
                if (eventList.eventID == self.event.eventID && eventList.isReply == false) || self.event.organiserID == currentUser.uid {
                    
                    let alert = UIAlertController(title: "提示", message: "是否同意加入\(self.event.title)?", preferredStyle: .alert)
                    
                    let notificationID = ref.childByAutoId().key
                    
                    let agree = UIAlertAction(title: "同意", style: .default) { (action) in
                        
                        let notification = Notifacation(notifacationID: notificationID,
                                                        eventID: self.event.eventID,
                                                        message: "\"\(self.user.name)\" 同意加入 「\(self.event.title)」",
                                                        remark: "" ,
                                                        isRead: false,
                                                        isNew: true,
                                                        isRemoved: false)
                        
                        ref.child("notification").child(self.event.organiserID).child(notificationID).setValue(notification.uploadNotification())
                        ref.child("eventList").child(currentUser.uid).child(self.event.eventID).updateChildValues(["isReply" : true])
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                    let reject = UIAlertAction(title: "拒絕", style: .cancel) { (action) in
                        
                        let notificationRef = ref.child("notification")
                        
                        FirebaseManager.shared.getData(notificationRef.child(self.user.userID), type: .childAdded) { (allObjects, dict) in
                            
                            guard let dict = dict else {
                                
                                print("fail to get dict")
                                return
                            }
                            
                            let notification = Notifacation(notifacationID: dict["notifacationID"] as! String,
                                                            eventID: dict["eventID"] as! String,
                                                            message: dict["message"] as! String,
                                                            remark: dict["remark"] as! String,
                                                            isRead: dict["isRead"] as! Bool,
                                                            isNew: dict["isNew"] as! Bool,
                                                            isRemoved: dict["isRemoved"] as! Bool)
                            
                            if self.event.eventID == notification.eventID {
                                
                                notificationRef.child(self.user.userID).child(notification.notifacationID).updateChildValues(["isRemoved" : true])
                                notificationRef.child(self.user.userID).child(notification.notifacationID).updateChildValues(["remark" : "已不在此聚成員內"])
                            }
                            
                            let newNotification = Notifacation(notifacationID: notificationID,
                                                               eventID: self.event.eventID,
                                                               message: "\"\(self.user.name)\" 拒絕了 「\(self.event.title)」 的加入邀請",
                                                                remark: "",
                                                                isRead: false,
                                                                isNew: true,
                                                                isRemoved: false)
                            
                            notificationRef.child(self.event.organiserID).child(notificationID).setValue(newNotification.uploadNotification())
                            
                        }
                        
                        ref.child("memberList").child(self.event.eventID).child(self.user.userID).removeValue()
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                    alert.addAction(agree)
                    alert.addAction(reject)
                    self.present(alert, animated: true, completion: nil)
                    break
                }
            }
        }
    }
    
    
    // Query organiser's data from database.
    func queryOrganiserData() {
        
        let userRef = FirebaseManager.shared.databaseReference.child("user").child(self.event.organiserID)
        
        FirebaseManager.shared.getDataBySingleEvent(userRef, type: .value) { (allObjects, dict) in
            
            guard let dict = dict else {
                
                print("fail to get dict")
                return
            }
            
            let user = GUser(userID: dict["userID"] as! String,
                            email: dict["email"] as! String,
                            name: dict["name"] as! String,
                            profileImageURL: dict["profileImageURL"] as! String)
            
            self.organiserName.text = user.name
            
            // Show image from cache if that has been stored in there.
            if let image = self.imageCache.object(forKey: user.profileImageURL as NSString) as? UIImage {
                
                self.organiserProfileImage.image = image
            }else {
                
                // Download image from firebase storage.
                FirebaseManager.shared.getImage(urlString: user.profileImageURL) { (image) in
                    
                    guard let image = image else {
                        
                        print("Fail to get image")
                        return
                    }
                    
                    self.imageCache.setObject(image, forKey: user.profileImageURL as NSString)
                    self.organiserProfileImage.image = image
                }
            }
        }
    }
    
    
    func queryUserData() {
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return
        }
        
        let userRef = FirebaseManager.shared.databaseReference.child("user").child(currentUser.uid)
        
        FirebaseManager.shared.getData(userRef, type: .value) { (allObject, dict) in
            
            guard let dict = dict else{
                
                print("Fail to get dict")
                return
            }
            
            self.user = GUser(userID: dict["userID"] as! String,
                             email: dict["email"] as! String,
                             name: dict["name"] as! String,
                             profileImageURL: dict["profileImageURL"] as! String)
            
            
            FirebaseManager.shared.getImage(urlString: self.user.profileImageURL) { (image) in
                
                self.user.image = image
            }
        }
    }
    
    
    func queryMemberData() {
        
        let memberRef = FirebaseManager.shared.databaseReference.child("memberList").child(self.event.eventID)
        
        FirebaseManager.shared.getDataBySingleEvent(memberRef, type: .value) { (allObjects, dict) in
            
            for snap in allObjects {
                
                guard let dict = snap.value as? [String : Any] else {
                    
                    print("Fail to get data")
                    return
                }
                
                let memberID = dict["memberID"] as! String
                let userRef = FirebaseManager.shared.databaseReference.child("user").child(memberID)
                
                FirebaseManager.shared.getDataBySingleEvent(userRef, type: .value){ (allObjects, dict) in
                    
                    guard let dict = dict else {
                        
                        print("Fail to get dict")
                        return
                    }
                    
                    let user = GUser(userID: dict["userID"] as! String,
                                    email: dict["email"] as! String,
                                    name: dict["name"] as! String,
                                    profileImageURL: dict["profileImageURL"] as! String)
                    
                    self.memberData.insert(user, at: 0)
                    self.memberCollectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editEvent" {
            
            let editEventVC = segue.destination as! AddEventVC
            editEventVC.isEdit = true
            editEventVC.event = self.event
            editEventVC.members = self.memberData
            editEventVC.annotation = self.annotation
            editEventVC.region = self.region
        }
    }
    
}

// MARK: - UICollectionViewDataSource
extension EventContentVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.memberData.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let memberCell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! MemberCollectionViewCell
        let member = self.memberData[indexPath.item]
        
        memberCell.deleteButton.isHidden = true
        memberCell.memberName.text = member.name
        memberCell.memberProfileImage.image = nil
        
        // Show image from cache if that has been stored in there.
        if let image = self.imageCache.object(forKey: member.profileImageURL as NSString) as? UIImage {
            
            memberCell.memberProfileImage.image = image
            member.image = image
        }else {
            
            // Download image from firebase storage.
            FirebaseManager.shared.getImage(urlString: member.profileImageURL) { (image) in
                
                guard let image = image else {
                    
                    print("Fail to get image")
                    return
                }
                
                self.imageCache.setObject(image, forKey: member.profileImageURL as NSString)
                memberCell.memberProfileImage.image = image
                member.image = image
            }
        }
        
        return memberCell
    }
}

