import UIKit
import Firebase

class EditProfileInfoVC: UITableViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    
    var user: User!
    let ref = FirebaseManager.shared.databaseReference
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usernameTextField.text = self.user.name
        self.profileImageView.image = self.user.image
    }
    
    @IBAction func donePressed(_ sender: Any) {
        self.uploadUserData()
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    @IBAction func pickImagePressed(_ sender: Any) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // Upload user's data to database.
    func uploadUserData() {
        
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
        
        guard let thumbnailImage = FirebaseManager.shared.thumbnail(image, widthSize: 100, heightSize: 100) else {
            print("Fail to get image")
            return
        }
        
        FirebaseManager.shared.uploadImage(imageRef, image: thumbnailImage) { (url) in
            
            let user = User(userID: uid, email: self.user.email, name: self.usernameTextField.text!, profileImageURL: String(describing: url))
            self.ref.child("user").child(uid).setValue(user.uploadedUserData())
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
