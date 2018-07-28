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
        self.tableView.separatorStyle = .none

        if self.invitingMemberData.count == 0 {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.spinner.stopAnimating()

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
                    
                    guard let dict = dict else {
                        
                        print("Fail to get dict")
                        return
                    }
                    
                    let user = GUser(userID: dict["userID"] as! String,
                                     email: dict["email"] as! String,
                                     name: dict["name"] as! String,
                                     profileImageURL: dict["profileImageURL"] as! String)
                    
                    self.invitingMemberData.append(user)
                    self.spinner.stopAnimating()
                    self.tableView.separatorStyle = .singleLine
                    self.tableView.reloadData()
                }
            }
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
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
