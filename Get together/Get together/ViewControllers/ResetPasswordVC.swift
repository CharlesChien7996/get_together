import UIKit
import Firebase
import SVProgressHUD

class ResetPasswordVC: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func resetPassword(_ sender: Any) {
        
        if self.emailTextField.text!.isEmpty {
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: self.emailTextField.text!) { (error) in
            if let error = error {
                
                print(error.localizedDescription)
                return
            }
            SVProgressHUD.show(withStatus: "請稍候...")

            self.emailTextField.text = ""
            let alertController = UIAlertController(title: "重設密碼信已寄出", message: "請至信箱確認並重設密碼", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
            SVProgressHUD.dismiss()
        }
    }
    @IBAction func cancelPressed(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
