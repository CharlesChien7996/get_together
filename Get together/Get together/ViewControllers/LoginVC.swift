import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FacebookCore
import FacebookLogin
import SVProgressHUD


class LoginVC: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var emailCheck: UILabel!
    @IBOutlet weak var passwordCheck: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var googleSignInBtn: UIButton!
    @IBOutlet weak var facebookLoginBtn: UIButton!
    
    
    var originalFrame : CGRect?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self

        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.loginBtn.layer.cornerRadius = self.loginBtn.frame.height / 5.0
        self.registerBtn.layer.cornerRadius = self.registerBtn.frame.height / 5.0
        self.googleSignInBtn.layer.cornerRadius = self.googleSignInBtn.frame.height / 5.0
        self.facebookLoginBtn.layer.cornerRadius = self.facebookLoginBtn.frame.height / 5.0

        
    }
    
    
    // 一般登入
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
                
                SVProgressHUD.show(withStatus: "請稍候...")
                NotificationCenter.default.post(name: NSNotification.Name("login"), object: nil, userInfo: nil)
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let tabbarController = delegate.window?.rootViewController as! UITabBarController
                tabbarController.selectedIndex = 0

                self.dismiss(animated: true)
                SVProgressHUD.dismiss()

            }
        }
    }
    

    // Google登入
    @IBAction func googleSignInPressed(_ sender: Any) {
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    

    // Facebook登入
    @IBAction func facebookSignInPressed(_ sender: Any) {
        
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile, .email,], viewController: self) { (result) in
            SVProgressHUD.show(withStatus: "請稍候...")

            switch result {
            case .success(grantedPermissions: _, declinedPermissions: _, token: _):

                guard let accessToken = AccessToken.current?.authenticationToken else {
                    return
                }

                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
                Auth.auth().signInAndRetrieveData(with: credential){ (result, error) in

                    if let error = error {

                        print(error)
                        return
                    }
                    
                    guard let user = result?.user else {
                        return
                    }

                    let gUser = GUser(userID: user.uid, email: user.email ?? user.phoneNumber ?? "Facebook 使用者", name: user.displayName ?? "", profileImageURL: user.photoURL?.absoluteString ?? "")
                    let userRef = FirebaseManager.shared.databaseReference.child("user").child(user.uid)

                    FirebaseManager.shared.getDataBySingleEvent(userRef, type: .value){ (allObjects, dict) in

                        if dict?.count == 0 || dict?.count == nil {

                            userRef.setValue(gUser.uploadedUserData())
                        }

                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        let tabbarController = delegate.window?.rootViewController as! UITabBarController
                        tabbarController.selectedIndex = 0
                        NotificationCenter.default.post(name: NSNotification.Name("login"), object: nil, userInfo: nil)

                        SVProgressHUD.dismiss()
                        self.dismiss(animated: true, completion: nil)
                    }
                }

            case .failed( let error):
                print(error)
            case .cancelled:
                SVProgressHUD.dismiss()
            }

        }
    }
    
    
    // 稍後登入
    @IBAction func laterPressed(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // 錯誤訊息
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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard Auth.auth().currentUser != nil else {
            print("Fail to get current user")
            return
        }
        
        // 若使用者已登入則畫面跳轉至主畫面
        let tabBarVC = self.storyboard?.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
        self.present(tabBarVC, animated: true, completion: nil)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == self.emailTextField {
            
            emailTextField.resignFirstResponder()
            
            passwordTextField.becomeFirstResponder()
            
        }else {
            
            passwordTextField.resignFirstResponder()
        }
        
        return true
    }
    
}

extension LoginVC: GIDSignInUIDelegate {
    
}

