import UIKit
import Firebase

protocol MemberSearchVCDelegate: class {
    
    func didUpdateMember(_ updatedMember: GUser)
}

class MemberSearchVC: UITableViewController {
    
    var memberSearchResultController: UISearchController!
    var memberData: [GUser] = []
    var matchingItems: [GUser] = []
    weak var delegate: MemberSearchVCDelegate?
    var imageCache = FirebaseManager.shared.imageCache

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = 60
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "取消"
        
        let ref = FirebaseManager.shared.databaseReference.child("user")
        
        // 查詢使用者資料
        FirebaseManager.shared.getData(ref, type: .childAdded) { (allObjects, dict) in
            
            guard let dict = dict else{
                print("Fail to get dict")
                return
            }
            
            let member = GUser(userID: dict["userID"] as! String,
                              email: dict["email"] as! String,
                              name: dict["name"] as! String,
                              profileImageURL: dict["profileImageURL"] as! String)
            
            self.memberData.append(member)
        }
        
        
        // 設定Search bar
        self.memberSearchResultController = UISearchController(searchResultsController: nil)
        self.memberSearchResultController.searchResultsUpdater = self
        let memberSearchBar = self.memberSearchResultController.searchBar
        memberSearchBar.sizeToFit()
        let textFieldInsideUISearchBar = memberSearchBar.value(forKey: "searchField") as? UITextField
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = textFieldInsideUISearchBarLabel?.font.withSize(14)
        memberSearchBar.placeholder = "輸入暱稱或Email來搜尋成員..."
        memberSearchBar.barTintColor = UIColor.white
        self.memberSearchResultController?.dimsBackgroundDuringPresentation = false
        self.memberSearchResultController?.hidesNavigationBarDuringPresentation = false
        self.navigationItem.titleView = memberSearchBar
        definesPresentationContext = true

    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.matchingItems.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchMemberCell", for: indexPath)
        let selectedMember = matchingItems[indexPath.row]
        
        cell.textLabel?.text = selectedMember.name
        cell.detailTextLabel?.text = selectedMember.email
        cell.imageView?.image = UIImage(named: "profileImage")
        cell.imageView?.layer.cornerRadius = 30
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        if let image = self.imageCache.object(forKey: selectedMember.profileImageURL as NSString) as? UIImage {
            
            cell.imageView?.image = image
            selectedMember.image = image
        }else {
            
            FirebaseManager.shared.getImage(urlString: selectedMember.profileImageURL) { (image) in
                
                guard let image = image else {
                    print("Fail to get image")
                    return
                }
                
                cell.imageView?.image = image
                selectedMember.image = image
                self.imageCache.setObject(image, forKey: selectedMember.profileImageURL as NSString)
            }
        }

        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedMember = matchingItems[indexPath.row]
        self.delegate?.didUpdateMember(selectedMember)
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func filterMemberData(for searchText: String) {
        
        self.matchingItems = self.memberData.filter() { (member) -> Bool in
            let isMatch = member.name.localizedCaseInsensitiveContains(searchText) || member.email.localizedCaseInsensitiveContains(searchText)
            return isMatch
        }
    }
    
}


// MARK: - UISearchResultsUpdating
extension MemberSearchVC : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchText = searchController.searchBar.text else{
            return
        }
        
        self.filterMemberData(for: searchText)
        self.tableView.reloadData()

    }
}

