import UIKit
import Firebase
import FirebaseStorage
import MapKit
import SVProgressHUD

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
    
    
    var event: Event!
    var imageCache = FirebaseManager.shared.imageCache
    var region: MKCoordinateRegion!
    var annotation: MKPointAnnotation!
    var memberData: [GUser] = []
    var eventListData: [EventList] = []
    var notification: GNotification!
    var user: GUser?
    
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
        self.memberCollectionView.dataSource = self

    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return 0
        }
        
        if Set(self.event.memberIDs).contains(currentUser.uid) {
            
            return 9
        }else {
            
            return 8
        }
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
        
        return 50
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


        let ref = FirebaseManager.shared.databaseReference
        let eventListRef = ref.child("invitingEventList").child(currentUser.uid)
        
        FirebaseManager.shared.getDataBySingleEvent(eventListRef, type: .value) { (allObjects, dict) in
            
            for snap in allObjects {
                
                let dict = snap.value as! [String : Any]
                
                let eventList = EventList(eventID: dict["eventID"] as! String,
                                          isReply: dict["isReply"] as! Bool,
                                          isMember: dict["isMember"] as! Bool)
                let userRef = FirebaseManager.shared.databaseReference.child("user").child(currentUser.uid)
                
                FirebaseManager.shared.getDataBySingleEvent(userRef, type: .value){ (allObjects, dict) in
                    
                    guard let dict = dict else{
                        return
                    }
                    
                    let user = GUser(userID: dict["userID"] as! String,
                                     email: dict["email"] as! String,
                                     name: dict["name"] as! String,
                                     profileImageURL: dict["profileImageURL"] as! String)
                    
                    self.user = user
                    
                    if eventList.eventID == self.event.eventID && eventList.isReply == false {
                        
                        self.showAnwserSelector(currentUser, user: user)
                        return
                    }else if eventList.eventID == self.event.eventID && eventList.isMember == false {
                        self.showAlert()
                    }
                    
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                    }
                }
            }
        }
    }
    
    
    @IBAction func editPressed(_ sender: Any) {
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return
        }
        
        let memberSet = Set(self.event.memberIDs)
        
        guard memberSet.contains(currentUser.uid) else{
            print("Current user is not member")
            return
        }
        
        let alert = UIAlertController(title: "", message: "退出活動後需再次受邀才可以重新加入，是否確認退出？", preferredStyle: .alert)
        let ok = UIAlertAction(title: "確定", style: .default){ (action) in
            
            let newMembers = self.event.memberIDs.filter{$0 != currentUser.uid}
            let ref = FirebaseManager.shared.databaseReference
            ref.child("event").child(self.event.eventID).child("memberIDs").setValue(newMembers)
            
            let autoID = FirebaseManager.shared.databaseReference.childByAutoId().key
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let time = dateformatter.string(from: Date())
            
            let notification = GNotification(notificationID: autoID, userID: self.event.organiserID, eventID: self.event.eventID, message: "\"\(self.user?.name ?? "")\" 退出了 「\(self.event.title)」", remark: "", isRead: false, time: time, isRemoved: false)
            
            ref.child("invitingEventList").child(currentUser.uid).child(self.event.eventID).updateChildValues(["isMember" : false])
            ref.child("notification").child(autoID).setValue(notification.uploadNotification())
            
            
            self.navigationController?.popViewController(animated: true)
        }
        
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func showAnwserSelector(_ currentUser: User, user: GUser) {
        
        let ref = FirebaseManager.shared.databaseReference
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = dateformatter.string(from: Date())
        
        let alert = UIAlertController(title: "提示", message: "是否同意加入\(self.event.title)?", preferredStyle: .alert)
        
        let notificationID = ref.childByAutoId().key
        
        let agree = UIAlertAction(title: "同意", style: .default) { (action) in
            SVProgressHUD.show(withStatus: "請稍候...")
            
            let notification = GNotification(notificationID: notificationID, userID: self.event.organiserID, eventID: self.event.eventID,message: "\"\(user.name)\" 同意加入 「\(self.event.title)」", remark: "" ,isRead: false,time: time,isRemoved: false)
            
            ref.child("notification").child(notificationID).setValue(notification.uploadNotification())
            ref.child("invitingEventList").child(currentUser.uid).child(self.event.eventID).updateChildValues(["isReply" : true])
            ref.child("invitingMemberList").child(self.event.eventID).child(currentUser.uid).removeValue()
            self.event.memberIDs.append(currentUser.uid)
            ref.child("event").child(self.event.eventID).updateChildValues(["memberIDs" : self.event.memberIDs])
            
            self.navigationController?.popViewController(animated: true)
        }
        
        let reject = UIAlertAction(title: "拒絕", style: .cancel) { (action) in
            SVProgressHUD.show(withStatus: "請稍候...")
            let notificationRef = ref.child("notification")
            
            notificationRef.child(self.notification.notificationID).updateChildValues(["isRemoved" : true])
            notificationRef.child(self.notification.notificationID).updateChildValues(["remark" : "已拒絕邀請"])
            ref.child("invitingEventList").child(currentUser.uid).child(self.event.eventID).updateChildValues(["isReply" : true])
            ref.child("invitingEventList").child(currentUser.uid).child(self.event.eventID).updateChildValues(["isMember" : false])

            ref.child("invitingMemberList").child(self.event.eventID).child(currentUser.uid).removeValue()
            let newNotification = GNotification(notificationID: notificationID, userID: self.event.organiserID,eventID: self.event.eventID, message: "\"\(user.name)\" 拒絕了 「\(self.event.title)」 的加入邀請", remark: "", isRead: false, time: time, isRemoved: false)
            
            notificationRef.child(notificationID).setValue(newNotification.uploadNotification())
            
            self.navigationController?.popViewController(animated: true)
        }
        
        alert.addAction(agree)
        alert.addAction(reject)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func showAlert() {
        
            let alert = UIAlertController(title: "Oops!", message: "你已經不是此聚的成員囉！", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .cancel){ (action) in
                self.navigationController?.popViewController(animated: true)
            }
        
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    
    
    func queryUserData() {
        
        SVProgressHUD.show(withStatus: "載入中...")

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
                    
                    DispatchQueue.main.async {
                        self.organiserProfileImage.image = image
                    }
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
            DispatchQueue.main.async {
                self.memberCollectionView.reloadData()
                SVProgressHUD.dismiss()
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
            editEventVC.originalMemers = self.memberData
            editEventVC.annotation = self.annotation
            editEventVC.region = self.region
            editEventVC.delegate = self
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
                DispatchQueue.main.async {
                    memberCell.memberProfileImage.image = image
                    member.image = image
                }
            }
        }
        
        return memberCell
    }
}

extension EventContentVC: AddEventVCDelegate {
    func didUpdatedEvent(_ updatedEvent: Event) {

        self.event = updatedEvent
        self.queryUserData()
        self.eventTitle.text = self.event.title
        self.eventDate.text = self.event.date
        self.eventLocation.text = self.event.location
        self.eventDescription.text = self.event.description
        self.eventImageView.image = self.event.image
        self.setLocationAnnotation()
        
    }
}

