import UIKit
import Firebase

class InvitingMemberVC: UITableViewController {
    
    var invitingMemberData: [GUser] = []
    var event: Event!
    var imageCache = FirebaseManager.shared.imageCache
    var spinner: UIActivityIndicatorView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpActivityUndicatorView()
        self.queryInvitingMemberData()
    }
    
    func queryInvitingMemberData() {
        
        self.spinner.startAnimating()

//        if self.invitingMemberData.count == 0 {
//
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
//                self.spinner.stopAnimating()
//
//            }
//        }

        
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
                    
                    guard let dict = dict else {
                        
                        print("Fail to get dict")
                        return
                    }
                    
                    let user = GUser(userID: dict["userID"] as! String,
                                     email: dict["email"] as! String,
                                     name: dict["name"] as! String,
                                     profileImageURL: dict["profileImageURL"] as! String)
                    
                    self.invitingMemberData.append(user)
                    self.tableView.reloadData()
                }
            }
            self.spinner.stopAnimating()
            self.tableView.separatorStyle = .singleLine
            self.tableView.reloadData()
        }
    }
    
    
    // Set up UIActivityUndicatorView.
    func setUpActivityUndicatorView() {
        
        self.spinner = UIActivityIndicatorView()
        self.spinner.activityIndicatorViewStyle = .gray
        self.spinner.center = self.view.center
        self.spinner.hidesWhenStopped = true
        self.view.addSubview(self.spinner)
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
                invitingMemberCell.imageView?.image = image
                
                
            }
            
        }
        return invitingMemberCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
