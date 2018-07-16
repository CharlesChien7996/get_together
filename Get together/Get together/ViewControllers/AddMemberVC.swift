import UIKit
import Firebase

protocol AddMemberVCDelegate: class {
    func didMembersUpdate(_ updatedmembers: [Member])
}

class AddMemberVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var memberData: [Member] = []
    var newMemberData: [Member]!
    var newMember = ""
    var isNew = false
    weak var delegate: AddMemberVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.queryMemberData()
        self.tableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addPressed(_ sender: Any) {
        let member = Member(memberID: "", email: "", name: "", profileImageURL: "")
        let indexPath = IndexPath(row: 0, section: 0)
        self.newMemberData.insert(member, at: 0)
        self.isNew = true
        self.tableView.insertRows(at: [indexPath], with: .automatic)

    }
    
    @IBAction func trashPressed(_ sender: Any) {
        
        
        
    }
    
    @IBAction func donePressed(_ sender: Any) {
        
        
        self.delegate?.didMembersUpdate(self.newMemberData)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    func queryMemberData() {
        
        let ref = Database.database().reference().child("user")
        ref.observe(.childAdded) { (snapshot) in

            guard let dict = snapshot.value as? [String : Any] else {
                print("Fail to get data")
                return
            }
            
            print(dict)
            let member = Member(memberID: dict["userID"] as! String,
                                email: dict["email"] as! String,
                                name: dict["name"] as! String,
                                profileImageURL: dict["profileImageURL"] as! String)
            
            self.memberData.insert(member, at: 0)

        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension AddMemberVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.newMemberData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath == IndexPath(row: 0, section: 0) && self.isNew == true {
            let addMemberCell = tableView.dequeueReusableCell(withIdentifier: "add", for: indexPath) as! AddMemberCell
            addMemberCell.addMemberTextField.text = ""
            addMemberCell.addMemberTextField.delegate = self
            return addMemberCell
            
        }
        
        let memberCell = tableView.dequeueReusableCell(withIdentifier: "member", for: indexPath) as! MemberCell
        let member = newMemberData[indexPath.row]
        let urlString = member.profileImageURL
        
        guard let imageURL = URL(string: urlString) else {
            print("Fail to get imageURL")
            return UITableViewCell()
        }
        let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            if let error = error {
                print("Download image task fail: \(error.localizedDescription)")
                return
            }
            
            guard let imageData = data else {
                print("Fail to get imageData")
                return
            }
            
            let image = UIImage(data: imageData)
//            let smallImage = self.thumbnail(image)
            member.image = image
                DispatchQueue.main.async {
                    memberCell.email.text = member.name
                    memberCell.profileImageView.image = member.image
            }
        }
        task.resume()
        
        return memberCell

    }
    
    
}

extension AddMemberVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        self.isNew = false
        self.newMemberData.remove(at: 0)
        self.tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        
        if let newMember = textField.text {
            self.newMember = newMember 
            
            for i in 0...self.memberData.count-1 {
                if self.newMember == self.memberData[i].email {
                    
                    guard let currentUser = Auth.auth().currentUser else {
                        return false
                    }
                    
                    if self.newMember == currentUser.email {
                        let alert = UIAlertController(title: "錯誤", message: "你已經在成員內了！", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(ok)
                        present(alert, animated: true, completion: nil)
                        return false
                    }
                    
                    for i in self.newMemberData {
                        if self.newMember == i.email {
                            let alert = UIAlertController(title: "錯誤", message: "這個帳號已經是成員了！", preferredStyle: .alert)
                            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(ok)
                            present(alert, animated: true, completion: nil)
                            return false
                        }
                    }

                    self.newMemberData.insert(self.memberData[i], at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    return true
                }
                
                else if i == self.memberData.count-1 {
                    let alert = UIAlertController(title: "錯誤", message: "找不到這個帳號耶！重新輸入看看吧！", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(ok)
                    present(alert, animated: true, completion: nil)
                    return false
                }

            }
 
        }
        
        return true
    }
}


