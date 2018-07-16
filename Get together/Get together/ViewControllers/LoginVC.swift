import UIKit
import Firebase
import FirebaseAuth

class LoginVC: UIViewController {

    // TextField.
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // Check Label.
    @IBOutlet weak var emailCheck: UILabel!
    @IBOutlet weak var passwordCheck: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       

        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let user = Auth.auth().currentUser
        
        if user != nil {
            let tabBarVC = self.storyboard?.instantiateViewController(withIdentifier: "tabBarVC") as! UITabBarController
            DispatchQueue.main.async {
                self.present(tabBarVC, animated: true, completion: nil)
                
            }
        }
    }
    

    
    // Login Button.
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
//                let naviVC = tabBarVC.viewControllers?.first as! UINavigationController
//                let mainVC = naviVC.viewControllers.first as! MainVC
//                let user = User()
//                user.email = self.emailTextField.text
//                mainVC.user = user
                self.present(tabBarVC, animated: true, completion: nil)
            }
        }
    }
    

    
    // RegisterVC's Cancel button be pressed.
    @IBAction func cancelPressed(segue: UIStoryboardSegue) {
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
//     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//     // Get the new view controller using segue.destinationViewController.
//     // Pass the selected object to the new view controller.
//        if segue.identifier == "login" {
//            let user = User()
//            user.email = self.emailTextField.text
//            let tabVC = segue.destination as! UITabBarController
//            let naviVC = tabVC.viewControllers?.first as! UINavigationController
//            let mainVC = naviVC.viewControllers.first as! MainVC
//            mainVC.user = user
//        }
//     }
    
    func loginErrorHandle(_ error: Error) {
        if let errorCode = AuthErrorCode(rawValue: error._code) {
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

