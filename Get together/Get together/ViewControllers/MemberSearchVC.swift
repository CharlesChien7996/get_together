import UIKit
import Firebase
protocol MemberSearchVCDelegate {
    func didUpdateMember(_ updatedMember: User)
}

class MemberSearchVC: UITableViewController {
    var memberSearchResultController: UISearchController?

    var memberData: [User] = []
    var matchingItems: [User] = []
    var delegate: MemberSearchVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref = Database.database().reference().child("user")
        FirebaseManager.shared.getData(ref, type: .childAdded) { (snap, dict) in
            let member = User(userID: dict["userID"] as! String,
                                email: dict["email"] as! String,
                                name: dict["name"] as! String,
                                profileImageURL: dict["profileImageURL"] as! String)
            
            // 在viewDidLoad就先下載圖片
           FirebaseManager.shared.getImage(urlString: member.profileImageURL){ (image) in
                let smallImage = FirebaseManager.shared.thumbnail(image)
                member.image = smallImage
                self.memberData.append(member)

            }
        }// 在viewDidLoad就先下載圖片

                self.memberSearchResultController = UISearchController(searchResultsController: nil)
                self.memberSearchResultController?.searchResultsUpdater = self
                let memberSearchBar = self.memberSearchResultController?.searchBar
                memberSearchBar?.sizeToFit()
                memberSearchBar?.placeholder = "搜尋成員"
                memberSearchBar?.barTintColor = UIColor.white
        self.memberSearchResultController?.dimsBackgroundDuringPresentation = false
                memberSearchResultController?.hidesNavigationBarDuringPresentation = false
//        self.tableView.tableHeaderView = memberSearchBar
        self.navigationItem.titleView = memberSearchBar

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
            return self.matchingItems.count

    
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberDataCell", for: indexPath)
        let selectedMember = matchingItems[indexPath.row]
/* 在cellForRow才下載圖片

//        let task = FirebaseManager.shared.getImage(urlString: selectedMember.profileImageURL) { (image) in
//            let smallImage = FirebaseManager.shared.thumbnail(image)
//
//            DispatchQueue.main.async {
//                cell.textLabel?.text = selectedMember.name
//                cell.detailTextLabel?.text = selectedMember.email
//                cell.imageView?.image = smallImage
//            }
//
//        }
//        task.resume()
 */
                        cell.textLabel?.text = selectedMember.name
                        cell.detailTextLabel?.text = selectedMember.email
                        cell.imageView?.image = selectedMember.image
        
        
        return cell
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMember = matchingItems[indexPath.row]
        self.delegate?.didUpdateMember(selectedMember)

        self.navigationController?.popViewController(animated: true)

    }
    
//    // Query member's data from database.
//    func queryMemberData() {
//
//        let ref = Database.database().reference().child("user")
//
//        FirebaseManager.shared.getData(ref, type: .value) { (allObjects, dict)  in
//
//            for snap in allObjects {
//
//                guard let dict = snap.value as? [String : Any] else {
//                    print("Fail to get data")
//                    return
//                }
//
//                let member = Member(memberID: dict["userID"] as! String,
//                                    email: dict["email"] as! String,
//                                    name: dict["name"] as! String,
//                                    profileImageURL: dict["profileImageURL"] as! String)
//
//                self.memberData.insert(member, at: 0)
//                self.memberStrings.insert(member.email)
//
//            }
//            if self.memberStrings.contains(self.addMemberTextFiled.text!) {
//
//                guard let currentUser = Auth.auth().currentUser else {
//                    return
//                }
//
//                if self.addMemberTextFiled.text! == currentUser.email {
//                    let alert = UIAlertController(title: "錯誤", message: "你已經在成員內了！", preferredStyle: .alert)
//                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
//                    alert.addAction(ok)
//                    self.present(alert, animated: true, completion: nil)
//                    return
//                }
//
//                for i in self.members {
//                    if self.addMemberTextFiled.text == i.email {
//                        let alert = UIAlertController(title: "錯誤", message: "這個帳號已經是成員了！", preferredStyle: .alert)
//                        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
//                        alert.addAction(ok)
//                        self.present(alert, animated: true, completion: nil)
//                        return
//                    }
//                }
//
//                for i in self.memberData {
//                    if self.addMemberTextFiled.text! == i.email {
//                        self.members.insert(i, at: 0)
//                        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
//                        break
//                    }
//                }
//            }else {
//                let alert = UIAlertController(title: "錯誤", message: "找不到這個帳號耶！重新輸入看看吧！", preferredStyle: .alert)
//                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
//                alert.addAction(ok)
//                self.present(alert, animated: true, completion: nil)
//            }
//
    
            
            
            /* old
             ref.observe(.value) { (snapshot) in
             
             for snap in snapshot.children.allObjects as! [DataSnapshot] {
             
             guard let dict = snap.value as? [String : Any] else {
             print("Fail to get data")
             return
             }
             
             let member = Member(memberID: dict["userID"] as! String,
             email: dict["email"] as! String,
             name: dict["name"] as! String,
             profileImageURL: dict["profileImageURL"] as! String)
             
             self.memberData.insert(member, at: 0)
             self.memberStrings.insert(member.email)
             }
             
             
             if self.memberStrings.contains(self.addMemberTextFiled.text!) {
             
             guard let currentUser = Auth.auth().currentUser else {
             return
             }
             
             if self.addMemberTextFiled.text! == currentUser.email {
             let alert = UIAlertController(title: "錯誤", message: "你已經在成員內了！", preferredStyle: .alert)
             let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
             alert.addAction(ok)
             self.present(alert, animated: true, completion: nil)
             return
             }
             
             for i in self.members {
             if self.addMemberTextFiled.text == i.email {
             let alert = UIAlertController(title: "錯誤", message: "這個帳號已經是成員了！", preferredStyle: .alert)
             let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
             alert.addAction(ok)
             self.present(alert, animated: true, completion: nil)
             return
             }
             }
             
             for i in self.memberData {
             if self.addMemberTextFiled.text! == i.email {
             self.members.insert(i, at: 0)
             self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
             break
             }
             }
             }else {
             let alert = UIAlertController(title: "錯誤", message: "找不到這個帳號耶！重新輸入看看吧！", preferredStyle: .alert)
             let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
             alert.addAction(ok)
             self.present(alert, animated: true, completion: nil)
             }*/
            
            /*
             if let newMember = self.addMemberTextFiled.text {
             
             for i in 0...self.memberData.count-1 {
             
             if newMember == self.memberData[i].email {
             
             guard let currentUser = Auth.auth().currentUser else {
             return
             }
             
             if newMember == currentUser.email {
             let alert = UIAlertController(title: "錯誤", message: "你已經在成員內了！", preferredStyle: .alert)
             let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
             alert.addAction(ok)
             self.present(alert, animated: true, completion: nil)
             return
             }
             
             for i in self.members {
             if newMember == i.email {
             let alert = UIAlertController(title: "錯誤", message: "這個帳號已經是成員了！", preferredStyle: .alert)
             let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
             alert.addAction(ok)
             self.present(alert, animated: true, completion: nil)
             return
             }
             }
             
             self.members.insert(self.memberData[i], at: 0)
             self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
             break
             }else if i == self.memberData.count-1 {
             let alert = UIAlertController(title: "錯誤", message: "找不到這個帳號耶！重新輸入看看吧！", preferredStyle: .alert)
             let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
             alert.addAction(ok)
             self.present(alert, animated: true, completion: nil)
             }
             }
//             }*/
//        }
//    }
    
    func filterMemberData(for searchText: String) {
        self.matchingItems = self.memberData.filter() { (member) -> Bool in
            let isMatch = member.email.localizedCaseInsensitiveContains(searchText)
            return isMatch
        }
    }
}

extension MemberSearchVC : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else{
            return
        }
        self.filterMemberData(for: searchText)
        self.tableView.reloadData()
    }
}

