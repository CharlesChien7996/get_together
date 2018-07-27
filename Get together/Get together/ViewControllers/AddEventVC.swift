import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import MapKit

class AddEventVC: UITableViewController {
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UITextField!
    @IBOutlet weak var organiserProfileImage: UIImageView!
    @IBOutlet weak var organiserName: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var eventLocation: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var eventDescription: UITextView!
    
    @IBOutlet weak var selectDateBtn: UIButton!
    
    var isOn = false
    var isEdit = false
    var user: GUser!
    var event: Event!
    var members: [GUser] = []
    var deletedMembers: [GUser] = []
    var editedMembers: [GUser]!
    var region: MKCoordinateRegion!
    var annotation: MKPointAnnotation!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.eventDatePicker.addTarget(self, action: #selector(dateChanged(sender:)), for: UIControlEvents.valueChanged)
        
        self.collectionView.dataSource = self
        self.eventDescription.delegate = self
        self.eventDescription.textColor = UIColor.lightGray

        
        // Prepare defult event date.
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.eventDate.text = dateformatter.string(from: Date())
        self.eventDatePicker.minimumDate = Date()
        
        if self.isEdit == true {
            
            self.eventImageView.image = self.event.image
            self.eventTitle.text = self.event.title
            self.eventTitle.becomeFirstResponder()
            self.eventDate.text = self.event.date
            self.eventLocation.text = self.event.location
            self.mapView.addAnnotation(self.annotation)
            self.mapView.setRegion(self.region, animated: false)
            self.eventDescription.text = self.event.description
            self.eventDescription.textColor = UIColor.black
        }
        
        // Query organiser's data from database.
        if let currentUser = Auth.auth().currentUser {
            
            self.queryOrganiserData(currentUser.uid)
        }
    }
    
    func heightHandle(indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
        case 0 where UIScreen.main.bounds.width == 414:
            return 414
            
        case 0 where UIScreen.main.bounds.width == 375:
            return 375
            
        case 0 where UIScreen.main.bounds.width == 320:
            return 320
            
        case 1:
            return 44
            
        case 2:
            return 100
            
        case 3:
            return 110
            
        case 4 where self.isOn:
            return 144
            
        case 5:
            return 177
            
        case 6:
            return 268
            
        default:
            break
        }
        
        return 44
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
       let height = self.heightHandle(indexPath: indexPath)
        
        return height
    }
    
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
            let height = self.heightHandle(indexPath: indexPath)
            
            return height
    }
    
    
    // Query organiser's data from database.
    func queryOrganiserData(_ uid: String) {
        
        let organiserRef = Database.database().reference().child("user").child(uid)
        
        FirebaseManager.shared.getDataBySingleEvent(organiserRef, type: .value) { (allObjects, dict) in
            
            guard let dict = dict else {
                return
            }
            
            self.user = GUser(userID: uid, email: dict["email"] as! String,
                              name: dict["name"] as! String,
                              profileImageURL: dict["profileImageURL"] as! String)
            
            let urlString = self.user.profileImageURL
            
            FirebaseManager.shared.getImage(urlString: urlString) { (image) in
                
                self.organiserProfileImage.image = image
                self.organiserName.text = self.user.name
            }
        }
    }
    
    
    // Pick event image.
    @IBAction func uploadImagePressed(_ sender: Any) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
    // Pick event date.
    @IBAction func selectDatePressed(_ sender: Any) {
        
        if self.isOn == false {
            
            self.selectDateBtn.setImage(UIImage(named: "color_up"), for: .normal)
            self.isOn = true
            self.eventDatePicker.isHidden = false
            
        }else if self.isOn == true {
            
            self.selectDateBtn.setImage(UIImage(named: "down"), for: .normal)

            self.isOn = false
            self.eventDatePicker.isHidden = true
        }
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    
    @objc func dateChanged(sender:UIDatePicker){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.eventDate.text = dateFormatter.string(from: self.eventDatePicker.date)
    }
    
    
    func showAlert( _ title: String?, message: String?) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default) { (alertAction) in
        }
        alert.addAction(alertAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func done(_ sender: Any) {
        
        // Check if somewhere is empty.
        if self.eventTitle.text?.isEmpty == true {
            
            self.showAlert("標題", message: "等等，還沒輸入標題呢！")
            return
        }
        
        if self.members.count <= 0 {
            
            self.showAlert("描述", message: "等等，還沒邀請成員呢！")
            return
        }
        
        if self.eventLocation.text == "尚未選擇" {
            
            self.showAlert("描述", message: "等等，還沒選擇地點呢！")
            return
        }
        
        if self.eventDescription.text?.isEmpty == true || self.eventDescription.textColor == UIColor.lightGray {
            
            self.showAlert("描述", message: "等等，還沒輸入描述呢！")
            return
        }
        
        
        // Upload event's data to firebasedatabase.
        self.uploadEventData()
        self.navigationController?.popViewController(animated: true)
    }
    

    // Upload event's data to database.
    func uploadEventData() {
        
        let autoID = FirebaseManager.shared.databaseReference.childByAutoId().key
        var eventID: String!
        let ref = FirebaseManager.shared.databaseReference
        let imageRef = Storage.storage().reference().child("eventImage").child(autoID)
        
        guard let image = self.eventImageView.image else {
            print("Fail to get event's image")
            return
        }
        
        guard let thumbnailImage = FirebaseManager.shared.thumbnail(image,
                                                                    widthSize: Int(image.size.width / 4),
                                                                    heightSize: Int(image.size.height / 4)) else{
            print("Fail to get thumbnailImage")
            return
        }
        
        FirebaseManager.shared.uploadImage(imageRef, image: thumbnailImage) { (url) in
            
            var removedMemberSet = Set(self.deletedMembers)
            let memberSet = Set(self.members)
            
            let editedSet = memberSet.subtracting(removedMemberSet)
            self.editedMembers = Array(editedSet)
            removedMemberSet.subtract(memberSet)
            self.deletedMembers = Array(removedMemberSet)
            
            guard let currentUser = Auth.auth().currentUser else{
                
                print("Fail to get current user")
                return
            }
            
            if self.isEdit == true {
                
                eventID = self.event.eventID
                
                if !self.deletedMembers.isEmpty {
                    
                    for member in self.deletedMembers {
                        
                        ref.child("memberList").child(self.event.eventID).child(member.userID).removeValue()
                        ref.child("eventList").child(member.userID).child(self.event.eventID).removeValue()
                        
                        let notification = Notifacation(notifacationID: autoID,
                                                        eventID: self.event.eventID,
                                                        message: "\"\(self.user.name)\" 將您從 「\(self.event.title)」 移出成員",
                                                        remark: "",
                                                        isRead: false,
                                                        isNew: true,
                                                        isRemoved: true)
                        
                        ref.child("notification").child(member.userID).child(autoID).setValue(notification.uploadNotification())
                    }
                }
                
            }else {
                
                eventID = autoID
            }
            
            self.event = Event(eventID:eventID,
                               organiserID: currentUser.uid,
                               title: self.eventTitle.text!,
                               date: self.eventDate.text!,
                               location: self.eventLocation.text!,
                               description: self.eventDescription.text,
                               eventImageURL: String(describing: url))
            
            ref.child("event").child(eventID).setValue(self.event.uploadedEventData())
            
            for member in self.editedMembers {
                
                let eventList = EventList(eventID: self.event.eventID, isReply: false)
                
                ref.child("memberList").child(eventList.eventID).child(member.userID).child("memberID").setValue(member.userID)
                ref.child("eventList").child(member.userID).child(eventList.eventID).setValue(eventList.uploadedEventListData())
                
                // Upload data to notification.
                let notification = Notifacation(notifacationID: autoID,
                                                eventID: self.event.eventID,
                                                message: "\"\(self.user.name)\" 邀請您加入 「\(self.event.title)」",
                                                remark: "",
                                                isRead: false,
                                                isNew: true,
                                                isRemoved: false)
                
                ref.child("notification").child(member.userID).child(autoID).setValue(notification.uploadNotification())
            }
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "location" {
            
            let annotations = self.mapView.annotations
            self.mapView.removeAnnotations(annotations)
            
            let locationVC = segue.destination as! LocationVC
            locationVC.delegate = self
        }
        
        if segue.identifier == "memberSearch" {
            
            let memberSearchVC = segue.destination as! MemberSearchVC
            memberSearchVC.delegate = self
        }
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension AddEventVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        var editedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if editedImage == nil{
            
            editedImage = originalImage
        }
        
        if let image = editedImage {
            
            self.eventImageView.image = image
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}


// MARK: - UITextViewDelegate
extension AddEventVC: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if self.eventDescription.text == "為你的活動添加一點描述吧！" {
            self.eventDescription.text = ""
            self.eventDescription.textColor = UIColor.black
        }
        
//        self.eventDescription.becomeFirstResponder()
    }
}


// MARK: - UICollectionViewDataSource
extension AddEventVC: UICollectionViewDataSource, MemberCollectionViewCellDelegate {
    
    func deleteData(cell: MemberCollectionViewCell) {
        
        guard let indexPath = self.collectionView.indexPath(for: cell) else{
            
            return
        }
        
            let removeItem = self.members.remove(at: indexPath.item)
            if self.isEdit == true {
                
                self.deletedMembers.append(removeItem)
            }
            self.collectionView.deleteItems(at: [indexPath])
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.members.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let memberCell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! MemberCollectionViewCell
        let member = members[indexPath.item]
        memberCell.delegate = self
        
        if self.isEdit == true {
            
            memberCell.memberName.text = member.name
            memberCell.memberProfileImage.image = member.image
        }else {
            
            let urlString = member.profileImageURL
            
            FirebaseManager.shared.getImage(urlString: urlString) { (image) in
                
                member.image = image
                memberCell.memberName.text = member.name
                memberCell.memberProfileImage.image = member.image
            }
        }
        
        return memberCell
    }
}


// MARK: - LoginVCDelegate
extension AddEventVC: LoginVCDelegate {
    
    func getCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            
            
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let placemarks = placemarks, placemarks.count > 0 else {
                
                print("No any result")
                return
            }
            
            let targetPlaceMark = placemarks.first!
            var address = ""
            
            if let city = targetPlaceMark.subAdministrativeArea{
                address.append(city)
                
            }
            
            if let locality = targetPlaceMark.locality {
                address.append(locality)
                
            }
            
            if let name = targetPlaceMark.name {
                address.append(name)
            }
            
            self.eventLocation.text = address
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = address
            self.mapView.addAnnotation(annotation)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            self.mapView.setRegion(region, animated: false)
        }
    }
}


// MARK: - MemberSearchVCDelegate
extension AddEventVC: MemberSearchVCDelegate {
    
    func didUpdateMember(_ updatedMember: GUser) {
        
        guard let currentUser = Auth.auth().currentUser else {
            
            print("Fail to get current user")
            return
        }
        
        if updatedMember.email == currentUser.email {
            
            self.showAlert("錯誤", message: "你已經是成員囉！")
            return
        }
        
        for i in self.members {
            
            if updatedMember.email == i.email {
                
                self.showAlert("錯誤", message: "\(i.name)已經是成員囉！")
                return
            }
        }
        
        self.members.insert(updatedMember, at: 0)
        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
    }
}
