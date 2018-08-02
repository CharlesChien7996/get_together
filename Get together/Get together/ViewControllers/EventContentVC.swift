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
    var notification: GNotification!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.user = FirebaseManager.shared.user
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
        //        FirebaseManager.shared.setUpLoadingView(self)
        self.setLocationAnnotation()
        self.queryEventList()
        self.queryUserData()
        self.memberCollectionView.dataSource = self
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
        case 0 where UIScreen.main.bounds.width == 414:
            return 414
            
        case 0 where UIScreen.main.bounds.width == 375:
            return 375
            
        case 0 where UIScreen.main.bounds.width == 320:
            return 320
            
        case 1:
            return UITableViewAutomaticDimension
            
        case 2:
            return 100
            
        case 3:
            return 110
            
        case 4:
            return 44
            
        case 5:
            return 177
            
        case 6:
            return UITableViewAutomaticDimension
            
        default:
            break
        }
        
        return 44
        
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
            annotation.title = placemarks[0].locality
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
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = dateformatter.string(from: Date())
        let ref = FirebaseManager.shared.databaseReference
        let eventListRef = ref.child("invitingEventList").child(currentUser.uid)
        
        FirebaseManager.shared.getData(eventListRef, type: .value) { (allObjects, dict) in
            
            for snap in allObjects {
                
                let dict = snap.value as! [String : Any]
                
                let eventList = EventList(eventID: dict["eventID"] as! String,
                                          isReply: dict["isReply"] as! Bool)
                
                if eventList.eventID == self.event.eventID && eventList.isReply == false {
                    
                    let alert = UIAlertController(title: "提示", message: "是否同意加入\(self.event.title)?", preferredStyle: .alert)
                    
                    let notificationID = ref.childByAutoId().key
                    
                    let agree = UIAlertAction(title: "同意", style: .default) { (action) in
                        
                        
                        let notification = GNotification(notificationID: notificationID, userID: self.event.organiserID, eventID: self.event.eventID,message: "\"\(self.user.name)\" 同意加入 「\(self.event.title)」", remark: "" ,isRead: false,time: time,isRemoved: false)
                        
                        ref.child("notification").child(notificationID).setValue(notification.uploadNotification())
                        ref.child("invitingEventList").child(currentUser.uid).child(self.event.eventID).removeValue()
                        ref.child("invitingMemberList").child(self.event.eventID).child(currentUser.uid).removeValue()
                        self.event.memberIDs.append(currentUser.uid)
                        ref.child("event").child(self.event.eventID).updateChildValues(["memberIDs" : self.event.memberIDs])
                        
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                    let reject = UIAlertAction(title: "拒絕", style: .cancel) { (action) in
                        
                        let notificationRef = ref.child("notification")
                        
                        notificationRef.child(self.user.userID).child(self.notification.notificationID).updateChildValues(["isRemoved" : true])
                        notificationRef.child(self.user.userID).child(self.notification.notificationID).updateChildValues(["remark" : "已不在此聚成員內"])
                        ref.child("invitingEventList").child(currentUser.uid).child(self.event.eventID).removeValue()
                        ref.child("invitingMemberList").child(self.event.eventID).child(currentUser.uid).removeValue()
                        let newNotification = GNotification(notificationID: notificationID, userID: self.event.organiserID,eventID: self.event.eventID, message: "\"\(self.user.name)\" 拒絕了 「\(self.event.title)」 的加入邀請", remark: "", isRead: false, time: time, isRemoved: false)
                        
                        notificationRef.child(notificationID).setValue(newNotification.uploadNotification())
                        
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
    
    
    func queryUserData() {
        
        let userRef = FirebaseManager.shared.databaseReference.child("user")
        
        FirebaseManager.shared.getData(userRef, type: .value) { (allObjects, dict) in
            
            let organisers = allObjects.compactMap{ (snap) -> GUser? in
                
                let dict = snap.value as! [String: Any]
                
                let user = GUser(userID: dict["userID"] as! String,
                                 email: dict["email"] as! String,
                                 name: dict["name"] as! String,
                                 profileImageURL: dict["profileImageURL"] as! String)
                
                return (user.userID == self.event.organiserID ? user : nil)
                
            }
            
            guard let organiser = organisers.first else {
                return
            }
            
            self.organiserName.text = organiser.name
            
            // Show image from cache if that has been stored in there.
            if let image = self.imageCache.object(forKey: organiser.profileImageURL as NSString) as? UIImage {
                
                self.organiserProfileImage.image = image
                
            }else {
                
                // Download image from firebase storage.
                FirebaseManager.shared.getImage(urlString: organiser.profileImageURL) { (image) in
                    
                    guard let image = image else {
                        
                        print("Fail to get image")
                        return
                    }
                    
                    self.imageCache.setObject(image, forKey: organiser.profileImageURL as NSString)
                    self.organiserProfileImage.image = image
                    
                }
            }
            
            
            let members = allObjects.compactMap{ (snap) -> GUser? in
                
                let dict = snap.value as! [String: Any]
                
                let user = GUser(userID: dict["userID"] as! String,
                                 email: dict["email"] as! String,
                                 name: dict["name"] as! String,
                                 profileImageURL: dict["profileImageURL"] as! String)
                
                let membersSet = Set(self.event.memberIDs)
                
                return (membersSet.contains(user.userID) ? user : nil)
                
            }
            
            self.memberData = members
            self.memberCollectionView.reloadData()
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editEvent" {
            
            let editEventVC = segue.destination as! AddEventVC
            editEventVC.isEdit = true
            editEventVC.event = self.event
            editEventVC.members = self.memberData
            editEventVC.originalMemers = self.memberData
            editEventVC.annotation = self.annotation
            editEventVC.region = self.region
        }
        
        if segue.identifier == "invitingMemberVC" {
            let invitingMemberVC = segue.destination as! InvitingMemberVC
            invitingMemberVC.event = self.event
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

