import UIKit
import Firebase
import FirebaseStorage
import SVProgressHUD

class RegisterVC: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var checkPasswordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var emailCheck: UILabel!
    @IBOutlet weak var passwordCheck: UILabel!
    @IBOutlet weak var checkPasswordCheck: UILabel!
    @IBOutlet weak var usernameCheck: UILabel!
    
    @IBOutlet weak var createUserBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    
    var originalFrame: CGRect?
    
    @IBOutlet weak var register: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.checkPasswordTextField.delegate = self
        self.usernameTextField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.width / 2.0
        self.createUserBtn.layer.cornerRadius = self.createUserBtn.frame.height / 5.0
        self.cancelBtn.layer.cornerRadius = self.cancelBtn.frame.height / 5.0
        
    }
    
    
    // USer register.
    @IBAction func registerPressed(_ sender: Any) {
        
        // Check if text is empty.
        if self.emailTextField.text!.isEmpty{
            self.emailCheck.text = "Email不可以空空喔"
        }
        
        if self.passwordTextField.text!.isEmpty {
            self.passwordCheck.text = "密碼不可以空空喔"
        }
        
        if self.usernameTextField.text!.isEmpty {
            self.usernameCheck.text = "使用者名稱不可以空空喔"
        }
        
        if self.checkPasswordTextField.text!.isEmpty {
            self.checkPasswordCheck.text = "密碼確認不可以空空喔"
            
        }else if self.checkPasswordTextField.text! != self.passwordTextField.text! {
            self.checkPasswordCheck.text = "好像跟密碼不一樣耶，再試一次看看吧"
        }
        
        if self.emailTextField.text!.isEmpty == false && self.passwordTextField.text!.isEmpty == false && self.checkPasswordTextField.text!.isEmpty == false && self.usernameTextField.text!.isEmpty == false && self.checkPasswordTextField.text == self.passwordTextField.text {
            
            Auth.auth().createUser(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                if let error = error {
                    self.handleError(error) 
                    return
                }
                SVProgressHUD.show(withStatus: "請稍候...")

                self.uploadUserData()
                
                let alertController = UIAlertController(title:"註冊成功", message:"登入開始使用吧",preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default) { (UIAlertAction) in
                    
                    self.dismiss(animated: true, completion: nil)
                }
                
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    func handleError(_ error: Error) {
        
        guard let errorCode = AuthErrorCode(rawValue: error._code) else {
            return
        }
        switch errorCode {
        case .emailAlreadyInUse:
            self.emailCheck.text = "這個email已經被使用過囉"
            
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            self.emailCheck.text = "email格式不符喔"
            //                        case .networkError:
        //                            return "Network error. Please try again."
        case .weakPassword:
            self.passwordCheck.text = "請輸入6位以上"
            
        default:
            self.emailCheck.text = "未知錯誤"
        }
    }
    
    
    @IBAction func uploadProfileImage(_ sender: Any) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let alert = UIAlertController(title: "來源", message: "選擇照片來源", preferredStyle: .actionSheet)
        let photoLibray = UIAlertAction(title: "相簿", style: .default) { (action) in
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            
            self.present(imagePicker, animated: true, completion: nil)
            
        }
        let camera = UIAlertAction(title: "相機", style: .default) { (action) in
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
            
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(photoLibray)
        alert.addAction(camera)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func cancelPressed(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func uploadUserData() {
        
        guard let currentUser = Auth.auth().currentUser else {
            print("Fail to get current user")
            return
        }
        
        let imageName = currentUser.uid
        let imageRef = Storage.storage().reference().child("userProfileImage").child(imageName)
        
        guard let image = self.profileImageView.image else{
            print("Fail to get user's image")
            return
        }
        
        guard let thumbnailImage = FirebaseManager.shared.thumbnail(image, widthSize: 150, heightSize: 150) else {
            print("Fail to get image")
            return
        }
        
        FirebaseManager.shared.uploadImage(imageRef, image: thumbnailImage) { (url) in
            
            let user = GUser(userID: currentUser.uid, email: self.emailTextField.text!,
                             name: self.usernameTextField.text!,
                             profileImageURL: String(describing: url))
            
            FirebaseManager.shared.databaseReference.child("user").child(currentUser.uid).setValue(user.uploadedUserData())
            SVProgressHUD.dismiss()
        }
    }
    
    
    // Adjust frame when keyboard is showing.
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
        
        let textFrame = self.view.window!.convert(self.stackView.frame, from: self.view)
        var visibleRect = self.view.frame;
        self.originalFrame = visibleRect
        
        guard textFrame.maxY > currentKeyboardFrame.minY else{
            
            return
        }
        
        let difference = textFrame.maxY - currentKeyboardFrame.minY
        visibleRect.origin.y = visibleRect.origin.y - (difference+16)
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
    }
    
}


extension RegisterVC: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        
        if self.emailTextField.text!.isEmpty == false {
            self.emailCheck.text! = ""
        }
        
        if self.passwordTextField.text!.isEmpty == false {
            self.passwordCheck.text! = ""
        }
        
        if self.checkPasswordTextField.text!.isEmpty == false {
            
            if self.checkPasswordTextField.text! != self.passwordTextField.text! {
                self.checkPasswordCheck.text = "好像跟密碼不一樣耶，重試看看吧"
            }else {
                
                self.checkPasswordCheck.text! = ""
            }
        }
        if self.usernameTextField.text!.isEmpty == false {
            self.usernameCheck.text = ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        
        switch textField{
            
        case self.emailTextField:
            self.emailTextField.resignFirstResponder()
            self.passwordTextField.becomeFirstResponder()

        case self.passwordTextField:
            self.passwordTextField.resignFirstResponder()
            self.checkPasswordTextField.becomeFirstResponder()
            
        case self.checkPasswordTextField:
            self.checkPasswordTextField.resignFirstResponder()
            self.usernameTextField.becomeFirstResponder()
            
        case self.usernameTextField:
            self.usernameTextField.resignFirstResponder()
            
        default:
            break
        }
        
        return true
    }
}


extension RegisterVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        var editedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if editedImage == nil{
            
            editedImage = originalImage
        }
        
        if let image = editedImage {
            
            self.profileImageView.image = image
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
