import UIKit
import Firebase

class ResetPasswordVC: UIViewController {
    
    // TextField.
    @IBOutlet weak var emailTextField: UITextField!
    
    // Check Label.
    @IBOutlet weak var emailCheck: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func resetPassword(_ sender: Any) {
        if self.emailTextField.text!.isEmpty {
            self.emailCheck.text = "請輸入email"
        }else {
            
            Auth.auth().sendPasswordReset(withEmail: self.emailTextField.text!) { (error) in
                if error != nil {
                    if let errorCode = AuthErrorCode(rawValue: (error?._code)!) {
                        switch errorCode {
                            case .invalidEmail, .invalidSender, .invalidRecipientEmail:
                            self.emailCheck.text = "請輸入正確的email格式"
                        case .userNotFound:
                            self.emailCheck.text = "沒有這個帳號喔"
                        default:
                            self.emailCheck.text = ""
                        }
                    }
                }else {
                    self.emailTextField.text = ""
                    let alertController = UIAlertController(title: "重設密碼信已寄出", message: "請至信箱確認並重設密碼",
                                                            preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
 
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

}
