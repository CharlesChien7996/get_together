import UIKit
import Firebase

class ProfileVC: UITableViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var userName: UILabel!
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)

        
        guard let currentUser = Auth.auth().currentUser else {
            self.logoutBtn.isHidden = true
            self.editBtn.title = ""
            self.editBtn.isEnabled = false
            self.userEmail.text = "尚未登入"
            self.userName.text = "尚未登入"
            return
        }
        
        let userRef = FirebaseManager.shared.databaseReference.child("user").child(currentUser.uid)

        FirebaseManager.shared.getData(userRef, type: .value) { (allObject, dict) in

            guard let dict = dict else{
                print("Fail to get dict")
                return
            }
            
            self.user = User(userID: dict["userID"] as! String,
                            email: dict["email"] as! String,
                            name: dict["name"] as! String,
                            profileImageURL: dict["profileImageURL"] as! String)
            
            self.userEmail.text = self.user.email
            self.userName.text = self.user.name
            
            FirebaseManager.shared.getImage(urlString: self.user.profileImageURL) { (image) in
                self.user.image = image
                self.profileImageView.image = image
            }
        }
    }
    
    
    @IBAction func logoutPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
            self.present(loginVC, animated: true, completion: nil)
        }catch {
            print("error: \(error)")
        }
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editProfileInfo" {
            let editProfileInfoVC = segue.destination as! EditProfileInfoVC
            
            editProfileInfoVC.user = self.user
        }
    }
    
}
