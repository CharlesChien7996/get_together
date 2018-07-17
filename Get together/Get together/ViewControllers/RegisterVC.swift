import UIKit
import Firebase
import FirebaseStorage

class RegisterVC: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var checkPasswordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!

    @IBOutlet weak var emailCheck: UILabel!
    @IBOutlet weak var passwordCheck: UILabel!
    @IBOutlet weak var checkPasswordCheck: UILabel!
    @IBOutlet weak var usernameCheck: UILabel!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    let ref = Database.database().reference()

    
    @IBOutlet weak var register: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.checkPasswordTextField.delegate = self
        self.usernameTextField.delegate = self
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
                
                self.uploadUserData(self.profileImageView.image)
                
                let alertController = UIAlertController(title:"註冊成功", message:"登入開始使用吧",preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .cancel) { (UIAlertAction) in
                    self.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func handleError(_ error: Error) {
        if let errorCode = AuthErrorCode(rawValue: error._code) {
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
    }
    
    @IBAction func uploadProfileImage(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func uploadUserData(_ image: UIImage?) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid.")
            return
        }
        
        let imageName = uid
        let imageRef = Storage.storage().reference().child("userProfileImage").child(imageName)
        
        FirebaseManager.shared.uploadImage(imageRef, image: image) { (url) in
            
            let user = User(userID: uid, email: self.emailTextField.text!, name: self.usernameTextField.text!, profileImageURL: String(describing: url))
            self.ref.child("user").child(uid).setValue(user.uploadedUserData())
        }
        
        
        /*
        guard let imageData = UIImageJPEGRepresentation(image!, 0.5) else{
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid.")
            return
        }
        
        let imageName = uid
        let imageRef = Storage.storage().reference().child("userProfileImage").child(imageName)
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
                
                let user = User(userID: uid, email: self.emailTextField.text!, name: self.usernameTextField.text!, profileImageURL: "\(url)")
                self.ref.child("user").child(uid).setValue(user.uploadedUserData())
            }
        }*/
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
    

}

extension RegisterVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.profileImageView.image = image
        }
        self.dismiss(animated: true, completion: nil)
    }
}


