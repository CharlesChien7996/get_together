import UIKit
import Firebase
import FirebaseAuth

class LoginVC: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var emailCheck: UILabel!
    @IBOutlet weak var passwordCheck: UILabel!
    
    @IBOutlet weak var laterBtn: UIButton!
    var originalFrame : CGRect?

    @IBAction func laterPressed(_ sender: Any) {
        let tabBarVC = self.storyboard?.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
        self.present(tabBarVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        
    }
    
    
    @IBAction func loginPressed(_ sender: Any) {
        if self.emailTextField.text!.isEmpty {
            self.emailCheck.text = "請輸入email"
        }
        
        if self.passwordTextField.text!.isEmpty {
            self.passwordCheck.text = "請輸入密碼"
        }
        
        if self.emailTextField.text!.isEmpty == false && self.passwordTextField.text!.isEmpty == false {
            Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                
                if let error = error {
                    self.loginErrorHandle(error)
                    return
                }
                
                let tabBarVC = self.storyboard?.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
                self.present(tabBarVC, animated: true, completion: nil)
            }
        }
    }
    
    
    // RegisterVC's Cancel button be pressed.
    @IBAction func cancelPressed(segue: UIStoryboardSegue) {
        print("User pressed Cancel button to back.")
        self.view.endEditing(true)

    }

    
    func loginErrorHandle(_ error: Error) {
        
        guard let errorCode = AuthErrorCode(rawValue: error._code) else {
            return
        }
        
        switch errorCode {
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            self.emailCheck.text = "email格式不符喔"
        case .userNotFound:
            self.emailCheck.text = "沒有這個帳號喔"
        case .userDisabled:
            self.emailCheck.text = "這個帳號已經失效，請聯絡客服"
        case .wrongPassword:
            self.passwordCheck.text = "密碼不正確，請重新輸入或使用忘記密碼"
            //                        case .networkError:
        //                            return "Network error. Please try again."
        default:
            self.emailCheck.text = "未知錯誤"
        }
    }
    
    // Adjust frame when keyboard is showing.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let user = Auth.auth().currentUser
        
        if user != nil {
            let tabBarVC = self.storyboard?.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            DispatchQueue.main.async {
                self.present(tabBarVC, animated: true, completion: nil)
                
            }
        }
        
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

        let textFrame = self.view.window!.convert(self.laterBtn.frame, from: self.view)
        var visibleRect = self.view.frame
        self.originalFrame = visibleRect

        if textFrame.maxY > currentKeyboardFrame.minY {

            let difference = textFrame.maxY - currentKeyboardFrame.minY
            visibleRect.origin.y = visibleRect.origin.y - (difference+16)
            UIView.animate(withDuration: duration) {
                self.view.frame = visibleRect
            }
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


extension LoginVC: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        
        if self.emailTextField.text!.isEmpty == false {
            self.emailCheck.text! = ""
        }
        
        if self.passwordTextField.text!.isEmpty == false {
            self.passwordCheck.text! = ""
        }
    }
}

