import UIKit
import Firebase
import SVProgressHUD

class CommentVC: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    
    var originalFrame: CGRect?
    var event: Event!
    var user: GUser!
    var commentData:[Comment] = []
    var memberData: [GUser] = []
    var imageCache = FirebaseManager.shared.imageCache

    @IBOutlet weak var inpitBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.inpitBtn.isEnabled = false
        self.inpitBtn.backgroundColor = UIColor.lightGray
        self.textView.textColor = UIColor.lightGray
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.textView.delegate = self
        self.queryCommentData()
    }
    
    
    // 送出留言
    @IBAction func inputPressed(_ sender: Any) {
        
        guard let currentUser = Auth.auth().currentUser else {
            print("Fail to get current user")
            return
        }
                
        var commentID = FirebaseManager.shared.databaseReference.childByAutoId().key
        let ref = FirebaseManager.shared.databaseReference
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = dateformatter.string(from: Date())
        
        
        let comment = Comment(eventID: self.event.eventID, commentID: commentID, userID: currentUser.uid, content: self.textView.text, time: time)
        ref.child("comment").child(self.event.eventID).child(commentID).setValue(comment.uploadedCommentData())
        
        let userRef = ref.child("user").child(currentUser.uid)
        FirebaseManager.shared.getDataBySingleEvent(userRef, type: .value) { (allObjects, dict) in
            
            guard let dict = dict else{
                return
            }
            
            let user = GUser(userID: dict["userID"] as! String,
                             email: dict["email"] as! String,
                             name: dict["name"] as! String,
                             profileImageURL: dict["profileImageURL"] as! String)
            
            if currentUser.uid == self.event.organiserID {
                
                if self.memberData.count > 0 {
                    for member in self.memberData {
                        commentID = FirebaseManager.shared.databaseReference.childByAutoId().key
                        let notification = GNotification(notificationID: commentID, userID: member.userID,eventID: self.event.eventID,message: "\"\(user.name)\" 在 「\(self.event.title)」 中留言",remark: "",isRead: false,time: time,isRemoved: false)
                        
                        ref.child("notification").child(commentID).setValue(notification.uploadNotification())
                        commentID = ""
                    }
                }
                
            }else {
                
                let memberData1 = self.memberData.compactMap { (user) -> GUser? in
                    return (currentUser.uid != user.userID ? user : nil)
                }
                
                let notification = GNotification(notificationID: commentID, userID: self.event.organiserID, eventID: self.event.eventID,message: "\"\(user.name)\" 在 「\(self.event.title)」 中留言",remark: "",isRead: false,time: time,isRemoved: false)
                ref.child("notification").child(commentID).setValue(notification.uploadNotification())
                if memberData1.count > 0 {
                    commentID = ""

                    for member in memberData1 {
                        commentID = FirebaseManager.shared.databaseReference.childByAutoId().key

                        let notification = GNotification(notificationID: commentID, userID: member.userID,eventID: self.event.eventID,message: "\"\(user.name)\" 在 「\(self.event.title)」 中留言",remark: "",isRead: false,time: time,isRemoved: false)
                        
                        ref.child("notification").child(commentID).setValue(notification.uploadNotification())
                        commentID = ""
                    }
                }
            }
        }
        
        self.view.endEditing(true)
        self.inpitBtn.isEnabled = false
        self.inpitBtn.backgroundColor = UIColor.lightGray
        self.textView.text = "留言......"
        self.textView.textColor = UIColor.lightGray
    }
    
    
    // 查詢留言
    func queryCommentData() {
        
        SVProgressHUD.show(withStatus: "載入中...")
        
        if self.commentData.count == 0 {
            
            SVProgressHUD.dismiss(withDelay: 1.0)
            self.tableView.reloadData()
        }
        
        let commentRef = FirebaseManager.shared.databaseReference.child("comment").child(self.event.eventID).queryOrdered(byChild: "time")
        FirebaseManager.shared.getData(commentRef, type: .value) { (allObjects, dict) in
            
            self.commentData.removeAll()
            
            for snap in allObjects {
                
                let dict = snap.value as! [String:Any]
                
                let comment = Comment(eventID: dict["eventID"] as! String,
                                      commentID: dict["commentID"] as! String,
                                      userID: dict["userID"] as! String,
                                      content: dict["content"] as! String,
                                      time: dict["time"] as! String)
                
                self.commentData.append(comment)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    
    func getTimeDifferentWith(date: String) -> String {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(identifier: "Asia/Taipei")
        
        let dateModel = dateFormatter.date(from: date)
        let dateNow = Date()
        
        //計算傳入時間的時間戳
        let timeModel = NSString.init(format: "%ld", Int(dateModel!.timeIntervalSince1970))
        
        //計算當前時間的時間戳
        let timeNow = NSString.init(format: "%ld", Int(dateNow.timeIntervalSince1970))
        
        // 計算時差
        let time = (timeNow.integerValue - timeModel.integerValue) / 60
        
        // 取得輸入時間到目前時間的分鐘差
        var returnMinDiff = false
        var returnHourDiff = false
        var returnDayDiff = false
        var returnWeekDiff = false
        
        if time <= 60 {
            returnMinDiff = true
        }
        
        if time > 60 && time <= 60 * 24 {
            returnHourDiff = true
        }
        
        if time > 60 * 24 && time <= 60 * 24 * 7{
            returnDayDiff = true
        }
        
        if time > 60 * 24 * 7{
            returnWeekDiff = true
        }
        
        if returnMinDiff {
            return "\(time)分鐘前"
        } else if returnHourDiff {
            return "\(time / 60)小時前"
        } else if returnDayDiff {
            return "\(time / 60 / 24)天前"
        } else if returnWeekDiff {
            return "\(time / 60 / 24 / 7)週前"
        } else {
            return ""
        }
        
        
    }
    
    
    // 鍵盤升起畫面調整
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func keyboardWillAppear(notification : Notification)  {
        
        let info = notification.userInfo!
        let currentKeyboardFrame = info[UIKeyboardFrameEndUserInfoKey] as! CGRect
        let duration = info[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        
        let textFrame = self.view.window!.convert(self.textView.frame, from: self.view)
        var visibleRect = self.view.frame;
        self.originalFrame = visibleRect
        
        guard textFrame.maxY > currentKeyboardFrame.minY else{
            
            return
        }
        
        let difference = textFrame.maxY - currentKeyboardFrame.minY
        visibleRect.origin.y = visibleRect.origin.y - (difference+8)
        UIView.animate(withDuration: duration) {
            self.view.frame = visibleRect
        }
    }
    
    
    @objc func keyboardWillHide(notification : Notification)  {
        
        UIView.animate(withDuration: 0.5) {
            self.view.frame.origin.y = 0
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
        self.tableView.endEditing(true)
    }
}

extension CommentVC: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if self.textView.text == "留言......" || self.textView.text.isEmpty{
            self.inpitBtn.isEnabled = false
            self.inpitBtn.backgroundColor = UIColor.lightGray
            self.textView.text = ""
            self.textView.textColor = UIColor.black
        }
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if self.textView.text.isEmpty {
            self.textView.text = "留言......"
            self.textView.textColor = UIColor.lightGray
            self.inpitBtn.isEnabled = false
            self.inpitBtn.backgroundColor = UIColor.lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if !self.textView.text.isEmpty && self.textView.textColor != UIColor.lightGray {
            self.inpitBtn.isEnabled = true
            self.inpitBtn.backgroundColor = UIColor.init(red: 0, green: 0.6, blue: 1, alpha: 1)
        }else {
            self.inpitBtn.isEnabled = false
            self.inpitBtn.backgroundColor = UIColor.lightGray
        }
    }
}

extension CommentVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }else {
            return self.commentData.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let eventCell = self.tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! CommentEventCell
            
            eventCell.eventImageView.image = self.event.image
            eventCell.eventTitle.text = self.event.title
            
            return eventCell
        }
        
        let commentCell = self.tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
        let comment = self.commentData[indexPath.row]
        
        commentCell.commentContent.text = comment.content
        commentCell.userProfileImageView.image = nil
        
        
        let userRef = FirebaseManager.shared.databaseReference.child("user").child(comment.userID)
        
        FirebaseManager.shared.getDataBySingleEvent(userRef, type: .value) { (allObjects, dict) in
            
            guard let dict = dict else{
                return
            }
            
            
            let user = GUser(userID: dict["userID"] as! String,
                             email: dict["email"] as! String,
                             name: dict["name"] as! String,
                             profileImageURL: dict["profileImageURL"] as! String)
            
            if let image = self.imageCache.object(forKey: user.profileImageURL as NSString) as? UIImage {
                commentCell.userProfileImageView.image = image
                commentCell.userName.text = user.name
                commentCell.timeInterval.text = self.getTimeDifferentWith(date: comment.time)
            }else {
                
                FirebaseManager.shared.getImage(urlString: user.profileImageURL){ (image) in
                    
                    guard let image = image else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        commentCell.userProfileImageView.image = image
                        commentCell.userName.text = user.name
                        commentCell.timeInterval.text = self.getTimeDifferentWith(date: comment.time)
                    }
                    self.imageCache.setObject(image, forKey: user.profileImageURL as NSString)
                }
            }
        }
        return commentCell
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        

        if indexPath.section == 0 {
            return false
        }else {
            
            let comment = self.commentData[indexPath.row]
            
            guard let currentUser = Auth.auth().currentUser else {
                print("Fail to get current user")
                return false
            }
            
            guard comment.userID == currentUser.uid else {
                return false
            }
        }
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let comment = self.commentData[indexPath.row]
        let commentRef = FirebaseManager.shared.databaseReference.child("comment").child(self.event.eventID).child(comment.commentID)
        
        if editingStyle == .delete {
            
            self.commentData.remove(at: indexPath.row)
            commentRef.removeValue()
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
        }
    }
}
