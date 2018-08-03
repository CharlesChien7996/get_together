import UIKit
import Firebase
import SVProgressHUD

class InvitingMemberVC: UITableViewController {
    
    var invitingMemberData: [GUser] = []
    var event: Event!
    var imageCache = FirebaseManager.shared.imageCache
    var alert: UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        FirebaseManager.shared.setUpLoadingView(self)
        self.queryInvitingMemberData()
        
    }
    
    
    func queryInvitingMemberData() {
        
        SVProgressHUD.show(withStatus: "載入中...")
        if self.invitingMemberData.count == 0 {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                
                SVProgressHUD.dismiss()
                self.tableView.reloadData()
            }
        }
        
        let ref = FirebaseManager.shared.databaseReference
        let invitingMembetListRef = ref.child("invitingMemberList").child(self.event.eventID)
        FirebaseManager.shared.getDataBySingleEvent(invitingMembetListRef, type: .value) { (allObjects, dict) in
            
            for snap in allObjects {
                
                guard let dict = snap.value as? [String : Any] else {
                    
                    print("Fail to get data")
                    return
                }
                
                let invitingMemberID = dict["invitingMemberID"] as! String
                let invitingMemberRef = ref.child("user").child(invitingMemberID)
                
                FirebaseManager.shared.getDataBySingleEvent(invitingMemberRef, type: .value) { (allObjects, dict) in
                    SVProgressHUD.show(withStatus: "載入中...")

                    guard let dict = dict else {
                        
                        print("Fail to get dict")
                        return
                    }
                    
                    let user = GUser(userID: dict["userID"] as! String,
                                     email: dict["email"] as! String,
                                     name: dict["name"] as! String,
                                     profileImageURL: dict["profileImageURL"] as! String)
                    
                    self.invitingMemberData.append(user)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        SVProgressHUD.dismiss()
                    }
                }
            }
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.invitingMemberData.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let invitingMemberCell = tableView.dequeueReusableCell(withIdentifier: "invitingMemberCell", for: indexPath)
        
        let invitingMember = self.invitingMemberData[indexPath.row]
        invitingMemberCell.textLabel?.text = invitingMember.name
        invitingMemberCell.detailTextLabel?.text = invitingMember.email
        invitingMemberCell.imageView?.image = #imageLiteral(resourceName: "profileImage")
        // Show image from cache if that has been stored in there.
        if let image = self.imageCache.object(forKey: invitingMember.profileImageURL as NSString) as? UIImage {
            
            invitingMemberCell.imageView?.image = image
        }else {
            
            // Download image from firebase storage.
            FirebaseManager.shared.getImage(urlString: invitingMember.profileImageURL) { (image) in
                
                guard let image = image else {
                    
                    print("Fail to get image")
                    return
                }
                
                self.imageCache.setObject(image, forKey: invitingMember.profileImageURL as NSString)
                
                DispatchQueue.main.async {
                    invitingMemberCell.imageView?.image = image

                }

            }
            
        }
        return invitingMemberCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
