import UIKit
import Firebase
import SVProgressHUD

class ProfileVC: UITableViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var userName: UILabel!
    var user: GUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        
        
        guard let currentUser = Auth.auth().currentUser else {
            self.logoutBtn.setTitle("登入", for: .normal)
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
            
            self.user = GUser(userID: dict["userID"] as! String,
                              email: dict["email"] as! String,
                              name: dict["name"] as! String,
                              profileImageURL: dict["profileImageURL"] as! String)
            DispatchQueue.main.async {
                self.userEmail.text = self.user.email
                self.userName.text = self.user.name
            }

            
            FirebaseManager.shared.getImage(urlString: self.user.profileImageURL) { (image) in
                DispatchQueue.main.async {
                    self.user.image = image
                    self.profileImageView.image = image
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(didUserLogin), name: NSNotification.Name("login"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUserLogout), name: NSNotification.Name("logout"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func didUserLogin() {
        
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        self.logoutBtn.setTitle("登出", for: .normal)
        self.editBtn.title = "編輯"
        self.editBtn.isEnabled = false

        self.queryUserInfo(currentUser)
    }
    
    
    @objc func didUserLogout() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let tabbarController = appDelegate.window?.rootViewController as! UITabBarController
        let secondVC = tabbarController.viewControllers![1]
        secondVC.tabBarItem.badgeValue = nil
        self.profileImageView.image = nil
        self.logoutBtn.setTitle("登入", for: .normal)
        self.editBtn.title = ""
        self.editBtn.isEnabled = false
        self.userEmail.text = "尚未登入"
        self.userName.text = "尚未登入"
    }
    
    
    @IBAction func logoutPressed(_ sender: Any) {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
        
        guard Auth.auth().currentUser != nil else {
            self.present(loginVC, animated: true, completion: nil)
            return
        }
        
        
        do {
            try Auth.auth().signOut()
            NotificationCenter.default.post(name: NSNotification.Name("logout"), object: nil, userInfo: nil)

            self.present(loginVC, animated: true, completion: nil)
        }catch {
            print("error: \(error)")
        }
    }
    
    
    func queryUserInfo(_ currentUser: User) {
        SVProgressHUD.show(withStatus: "載入中")
        let userRef = FirebaseManager.shared.databaseReference.child("user").child(currentUser.uid)
        
        FirebaseManager.shared.getData(userRef, type: .value) { (allObject, dict) in
            
            guard let dict = dict else{
                print("Fail to get dict")
                return
            }
            
            self.user = GUser(userID: dict["userID"] as! String,
                              email: dict["email"] as! String,
                              name: dict["name"] as! String,
                              profileImageURL: dict["profileImageURL"] as! String)
            
            DispatchQueue.main.async {
                self.userEmail.text = self.user.email
                self.userName.text = self.user.name
            }
            
            FirebaseManager.shared.getImage(urlString: self.user.profileImageURL) { (image) in
                DispatchQueue.main.async {
                    self.user.image = image
                    self.profileImageView.image = image
                }
            }
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
