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
    
    var members: [User] = []
    var isOn = false
    let ref = Database.database().reference()
    var user: User!
    var memberStrings: Set<String> = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.eventDescription.delegate = self
        
        // Query organiser's data from database.
        if let uid = Auth.auth().currentUser?.uid {
            
            self.queryOrganiserData(uid)
        }
        
        // Prepare defult event date.
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.eventDate.text = dateformatter.string(from: Date())
        self.eventDatePicker.minimumDate = Date()
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
            self.isOn = true
            self.eventDatePicker.isHidden = false
            
        }else if self.isOn == true {
            self.isOn = false
            self.eventDatePicker.isHidden = true
            
        }
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
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
        
        if self.eventDescription.text?.isEmpty == true || self.eventDescription.textColor == UIColor.lightGray {
            
            self.showAlert("描述", message: "等等，還沒輸入描述呢！")
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
        
        
        // Upload event's data to firebasedatabase.
        self.uploadEventData()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func eventDatePicker(_ sender: Any) {
        
        self.eventDatePicker.addTarget(self, action: #selector(dateChanged(sender:)), for: UIControlEvents.valueChanged)
    }
    
    
    @objc func dateChanged(sender:UIDatePicker){
        becomeFirstResponder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.eventDate.text = dateFormatter.string(from: self.eventDatePicker.date)
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.row {
        case 0:
            return UITableViewAutomaticDimension
        case 1:
            return 44
        case 2:
            return 70
        case 3:
            return 80
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
    
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return UITableViewAutomaticDimension
        case 1:
            return 44
        case 2:
            return 70
        case 3:
            return 80
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
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "location" {
            
            let locationVC = segue.destination as! LocationVC
            locationVC.delegate = self
        }
        
        if segue.identifier == "memberSearch" {
            
            let memberSearchVC = segue.destination as! MemberSearchVC
            memberSearchVC.delegate = self
        }
    }
    
    
    // Upload event's data to database.
    func uploadEventData() {
        
        
        let imageName = UUID().uuidString
        let imageRef = Storage.storage().reference().child("eventImage").child(imageName)
        
        guard let image = self.eventImageView.image else {
            print("Fail to get event's image")
            return
        }
        
        guard let thumbnailImage = FirebaseManager.shared.thumbnail(image, widthSize: Int(image.size.width / 4), heightSize: Int(image.size.height / 4)) else {
            print("Fail to get thumbnailImage")
            return
        }
        
        
        FirebaseManager.shared.uploadImage(imageRef, image: thumbnailImage) { (url) in
            
            if let user = Auth.auth().currentUser {
                let childRef = self.ref.childByAutoId()
                
                let event = Event(eventID:childRef.key, organiserID: user.uid, title: self.eventTitle.text!, date: self.eventDate.text!, location: self.eventLocation.text!, description: self.eventDescription.text, eventImageURL: String(describing: url))
                
                self.ref.child("event").child(childRef.key).setValue(event.uploadedEventData())
                
                for member in self.members {
                    
                    // Upload data to notification.
                    self.ref.child("notification").child(member.userID).child(childRef.key).setValue(self.uploadedMemberListData(childRef.key, userName: self.user.name, eventName: event.title))
                    
                }
            }
        }
    }
    
    
    func uploadedMemberListData(_ ref:String, userName: String, eventName: String) -> Dictionary<String, Any> {
        
        return ["eventID": ref,
                "message": "\"\(userName)\" 邀請您加入 「\(eventName)」"]
    }
    
    
    // Query organiser's data from database.
    func queryOrganiserData(_ uid: String) {
        
        let ref = Database.database().reference().child("user").child(uid)
        
        FirebaseManager.shared.getDataBySingleEvent(ref, type: .value) { (allObject, dict) in
            guard let dict = dict else {
                return
            }
            self.user = User(userID: uid, email: dict["email"] as! String,
                             name: dict["name"] as! String,
                             profileImageURL: dict["profileImageURL"] as! String)
            
            let urlString = self.user.profileImageURL
            FirebaseManager.shared.getImage(urlString: urlString) { (image) in
                
                self.organiserProfileImage.image = image
                self.organiserName.text = self.user.name
                
            }
        }
    }
    
}


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


extension AddEventVC: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.eventDescription.text == "為你的活動添加一點描述吧！" {
            self.eventDescription.text = ""
            self.eventDescription.textColor = UIColor.black
        }
        self.eventDescription.becomeFirstResponder()
    }
}


extension AddEventVC: UICollectionViewDataSource, MemberCollectionViewCellDelegate {
    
    func deleteData(cell: MemberCollectionViewCell) {
        if let indexPath = self.collectionView.indexPath(for: cell) {
            self.members.remove(at: indexPath.item)
            
            self.collectionView.deleteItems(at: [indexPath])
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.members.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let memberCell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! MemberCollectionViewCell
        let member = members[indexPath.item]
        let urlString = member.profileImageURL
        memberCell.delegate = self
        
        FirebaseManager.shared.getImage(urlString: urlString) { (image) in
            member.image = image
            DispatchQueue.main.async {
                memberCell.memberName.text = member.name
                memberCell.memberProfileImage.image = member.image
            }
        }
        return memberCell
    }
}

extension AddEventVC: LoginVCDelegate {
    
    func getCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            // Check if error occured.
            if let error = error {
                print("geocodeAddressString Error: \(error)")
                return
            }
            guard let placemarks = placemarks, placemarks.count > 0 else {
                print("No any result!")
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
            self.mapView.setRegion(region, animated: true)
        }
    }
}


extension AddEventVC: MemberSearchVCDelegate {
    
    func didUpdateMember(_ updatedMember: User) {
        
        guard let currentUser = Auth.auth().currentUser else {
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
