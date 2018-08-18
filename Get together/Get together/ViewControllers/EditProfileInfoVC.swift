import UIKit
import Firebase
import SVProgressHUD

class EditProfileInfoVC: UITableViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    
    var user: GUser!
    let ref = FirebaseManager.shared.databaseReference
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usernameTextField.text = self.user.name
        self.profileImageView.image = self.user.image
        self.usernameTextField.becomeFirstResponder()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        self.uploadUserData()
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    @IBAction func pickImagePressed(_ sender: Any) {
        
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
    
    // 上傳使用者資料
    func uploadUserData() {
        SVProgressHUD.show(withStatus: "請稍候...")
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid.")
            return
        }
        
        let imageName = uid
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
            
            let user = GUser(userID: uid, email: self.user.email, name: self.usernameTextField.text!, profileImageURL: String(describing: url))
            self.ref.child("user").child(uid).setValue(user.uploadedUserData())
            SVProgressHUD.dismiss()
        }
    }
    
    
}

extension EditProfileInfoVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
