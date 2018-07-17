import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
class AddEventVC: UITableViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UITextField!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var eventDescription: UITextView!
    @IBOutlet weak var organiserProfileImage: UIImageView!
    @IBOutlet weak var organiserName: UILabel!
    @IBOutlet weak var addMemberTextFiled: UITextField!
    
    let now = Date()
    var memberData: [Member] = []
    var members: [Member] = []
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
        
        // 將當下時間轉換成設定的時間格式，存入self.eventDate
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.eventDate.text = dateformatter.string(from: Date())
        self.eventDatePicker.minimumDate = Date()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 選擇圖片
    @IBAction func uploadImagePressed(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    // 選擇日期
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
    
    @IBAction func addMemberPressed(_ sender: Any) {
        
        self.queryMemberData()
        
    }
    
    
    @IBAction func done(_ sender: Any) {
        
        // Check if event's title or event's description is empty.
        if self.eventTitle.text?.isEmpty == true{
            let titleAlert = UIAlertController(title: "請輸入標題", message: "等等，還沒輸入標題呢！", preferredStyle: .alert)
            let titleAlertAction = UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            }
            titleAlert.addAction(titleAlertAction)
            self.present(titleAlert, animated: true, completion: nil)
            return
        }
        
        if self.eventTitle.text?.isEmpty == true{
            let descriptionAlert = UIAlertController(title: "請輸入活動描述", message: "等等，還沒輸入描述呢！", preferredStyle: .alert)
            let descriptionAlertAction = UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            }
            descriptionAlert.addAction(descriptionAlertAction)
            self.present(descriptionAlert, animated: true, completion: nil)
            return
        }
        
        
        // Upload event's data to firebasedatabase.
        self.uploadEventData(self.eventImageView.image)
        
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
    
    
    
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.row {
        case 0 :
            return 226
        case 1:
            return 44
        case 2:
            return 70
        case 3:
            return 140
        case 4 where self.isOn:
            return 144
        case 5:
            return 44
        case 6:
            return 268
        default:
            break
        }
        return 44
    }
    
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0 :
            return 226
        case 1:
            return 44
        case 2:
            return 70
        case 3:
            return 140
        case 4 where self.isOn:
            return 144
        case 5:
            return 44
        case 6:
            return 268
        default:
            break
        }
        return 44
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    
    // 縮圖
    func thumbnail(_ image: UIImage?) -> UIImage? {
        guard let image = image else {
            print("There has no image.")
            return nil
        }
        
        let thumbnailSize = CGSize(width: 80, height: 80)
        let scale = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, scale)
        
        let widthRatio = thumbnailSize.width / image.size.width
        let heightRatio = thumbnailSize.height / image.size.height
        
        let ratio = max(widthRatio, heightRatio)
        
        let imageSize = CGSize(width: image.size.width*ratio, height: image.size.height*ratio)
        let cgRect = CGRect(x: -(imageSize.width - thumbnailSize.width) / 2, y: -(imageSize.height - thumbnailSize.height) / 2, width: imageSize.width, height: imageSize.height)
        image.draw(in: cgRect)
        
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return smallImage
    }
    
    
    // 資料上傳
    func uploadEventData(_ image: UIImage?) {
        
        
        let imageName = UUID().uuidString
        let imageRef = Storage.storage().reference().child("eventImage").child(imageName)
        
        FirebaseManager.shared.uploadImage(imageRef, image: image) { (url) in
            
            if let user = Auth.auth().currentUser {
                let childRef = self.ref.childByAutoId()
                
                let event = Event(eventID:childRef.key, organiserID: user.uid, title: self.eventTitle.text!, date: self.eventDate.text!, description: self.eventDescription.text, eventImageURL: String(describing: url) )
                
                self.ref.child("event").child(childRef.key).setValue(event.uploadedEventData())
                
                for member in self.members {
                    
                    // Upload data to Notice
                    self.ref.child("Notice").child(member.memberID).child(childRef.key).setValue(self.uploadedMemberListData(childRef.key, userName: self.user.name, eventName: event.title))
                    
                }
            }
        }
        
        /* old
        guard let imageData = UIImageJPEGRepresentation(image!, 1) else{
            return
        }
        
        let imageName = UUID().uuidString
        let imageRef = Storage.storage().reference().child("eventImage").child(imageName)
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            guard error == nil else{
                print("error: \(error!)")
                return
            }
            
            imageRef.downloadURL() { (url, error) in
                guard let url = url else {
                    print("error: \(error!)")
                    return
                }
                

                
                if let user = Auth.auth().currentUser {
                    let childRef = self.ref.childByAutoId()
                    
                    let event = Event(eventID:childRef.key, organiserID: user.uid, title: self.eventTitle.text!, date: self.eventDate.text!, description: self.eventDescription.text, eventImageURL: "\(url)" )
                    
                    self.ref.child("event").child(childRef.key).setValue(event.uploadedEventData())
                    
                    for member in self.members {
                        
                        // Upload data to Notice
                        self.ref.child("Notice").child(member.memberID).child(childRef.key).setValue(self.uploadedMemberListData(childRef.key, userName: self.user.name, eventName: event.title))
                        
                    }
                }
            }
        }*/
    }
    
    func uploadedMemberListData(_ ref:String, userName: String, eventName: String) -> Dictionary<String, Any> {
        
        return ["eventID": ref,
                "Notice": "\(userName)邀請您加入\(eventName)"]
    }
    
    
    // Query member's data from database.
    func queryMemberData() {
        
        let ref = Database.database().reference().child("user")
        
        FirebaseManager.shared.getData(ref, type: .value) { (allObjects, dict)  in
            
            for snap in allObjects {
                
                guard let dict = snap.value as? [String : Any] else {
                    print("Fail to get data")
                    return
                }
                
                let member = Member(memberID: dict["userID"] as! String,
                                    email: dict["email"] as! String,
                                    name: dict["name"] as! String,
                                    profileImageURL: dict["profileImageURL"] as! String)
                
                self.memberData.insert(member, at: 0)
                self.memberStrings.insert(member.email)
                
            }
            if self.memberStrings.contains(self.addMemberTextFiled.text!) {
                
                guard let currentUser = Auth.auth().currentUser else {
                    return
                }
                
                if self.addMemberTextFiled.text! == currentUser.email {
                    let alert = UIAlertController(title: "錯誤", message: "你已經在成員內了！", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                for i in self.members {
                    if self.addMemberTextFiled.text == i.email {
                        let alert = UIAlertController(title: "錯誤", message: "這個帳號已經是成員了！", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(ok)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                }
                
                for i in self.memberData {
                    if self.addMemberTextFiled.text! == i.email {
                        self.members.insert(i, at: 0)
                        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                        break
                    }
                }
            }else {
                let alert = UIAlertController(title: "錯誤", message: "找不到這個帳號耶！重新輸入看看吧！", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
            
        
        
        
        /* old
        ref.observe(.value) { (snapshot) in
            
            for snap in snapshot.children.allObjects as! [DataSnapshot] {
                
                guard let dict = snap.value as? [String : Any] else {
                    print("Fail to get data")
                    return
                }
                
                let member = Member(memberID: dict["userID"] as! String,
                                    email: dict["email"] as! String,
                                    name: dict["name"] as! String,
                                    profileImageURL: dict["profileImageURL"] as! String)
                
                self.memberData.insert(member, at: 0)
                self.memberStrings.insert(member.email)
            }
            
            
            if self.memberStrings.contains(self.addMemberTextFiled.text!) {
                
                guard let currentUser = Auth.auth().currentUser else {
                    return
                }
                
                if self.addMemberTextFiled.text! == currentUser.email {
                    let alert = UIAlertController(title: "錯誤", message: "你已經在成員內了！", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                for i in self.members {
                    if self.addMemberTextFiled.text == i.email {
                        let alert = UIAlertController(title: "錯誤", message: "這個帳號已經是成員了！", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(ok)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                }
                
                for i in self.memberData {
                    if self.addMemberTextFiled.text! == i.email {
                        self.members.insert(i, at: 0)
                        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                        break
                    }
                }
            }else {
                let alert = UIAlertController(title: "錯誤", message: "找不到這個帳號耶！重新輸入看看吧！", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }*/
            
            /*
            if let newMember = self.addMemberTextFiled.text {

                for i in 0...self.memberData.count-1 {

                    if newMember == self.memberData[i].email {

                        guard let currentUser = Auth.auth().currentUser else {
                            return
                        }

                        if newMember == currentUser.email {
                            let alert = UIAlertController(title: "錯誤", message: "你已經在成員內了！", preferredStyle: .alert)
                            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(ok)
                            self.present(alert, animated: true, completion: nil)
                            return
                        }

                        for i in self.members {
                            if newMember == i.email {
                                let alert = UIAlertController(title: "錯誤", message: "這個帳號已經是成員了！", preferredStyle: .alert)
                                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(ok)
                                self.present(alert, animated: true, completion: nil)
                                return
                            }
                        }

                        self.members.insert(self.memberData[i], at: 0)
                        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                        break
                    }else if i == self.memberData.count-1 {
                        let alert = UIAlertController(title: "錯誤", message: "找不到這個帳號耶！重新輸入看看吧！", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(ok)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
              }*/
            self.addMemberTextFiled.text = ""
            
        }
    }
    
    
    // Query organiser's data from database.
    func queryOrganiserData(_ uid: String) {
        
        let ref = Database.database().reference().child("user").child(uid)
        
        FirebaseManager.shared.getData(ref, type: .value) { (allObjects, dict)  in
            
            self.user = User(userID: uid, email: dict["email"] as! String,
                             name: dict["name"] as! String,
                             profileImageURL: dict["profileImageURL"] as! String)
            
            let urlString = self.user.profileImageURL
            let task = FirebaseManager.shared.getImage(urlString: urlString) { (image) in
                
                let smallImage = self.thumbnail(image)
                DispatchQueue.main.async {
                    self.organiserProfileImage.image = smallImage
                    self.organiserName.text = self.user.name
                }
            }
            task.resume()
            
        }
        
        /* old
        self.ref.child("user").child(uid).observe(.value) { (snapshot) in
            
            guard let dict = snapshot.value as? [String : Any] else {
                print("Fail to get data")
                return
            }
            
            self.user = User(userID: uid, email: dict["email"] as! String,
                             name: dict["name"] as! String,
                             profileImageURL: dict["profileImageURL"] as! String)
            
            
            let urlString = self.user.profileImageURL
            
            guard let imageURL = URL(string: urlString) else {
                print("Fail to get imageURL")
                return
            }
            
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
                DispatchQueue.main.async {
                    self.organiserProfileImage.image = smallImage
                    self.organiserName.text = self.user.name
                }
            }
            task.resume()
        }*/
    }
}


extension AddEventVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
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


extension AddEventVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.members.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let memberCell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! MemberCollectionViewCell
        let member = members[indexPath.item]
        let urlString = member.profileImageURL
        memberCell.delegate = self
        
        let task = FirebaseManager.shared.getImage(urlString: urlString) { (image) in
            member.image = image
            DispatchQueue.main.async {
                memberCell.memberName.text = member.name
                memberCell.memberProfileImage.image = member.image
            }
        }
        task.resume()
        return memberCell

        /* old
        guard let imageURL = URL(string: urlString) else {
            print("Fail to get imageURL")
            return UICollectionViewCell()
        }
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
            //            let smallImage = self.thumbnail(image)
            member.image = image
            DispatchQueue.main.async {
                memberCell.memberName.text = member.name
                memberCell.memberProfileImage.image = member.image
            }
        }
        task.resume()
        return memberCell*/
    }
}


extension AddEventVC: MemberCollectionViewCellDelegate {
    func deleteData(cell: MemberCollectionViewCell) {
        if let indexPath = self.collectionView.indexPath(for: cell) {
            self.members.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
        }
    }
}
