import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import MapKit

class EventContentVC: UITableViewController {
    
    @IBOutlet weak var organiserName: UILabel!
    @IBOutlet weak var organiserProfileImage: UIImageView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var memberCollectionView: UICollectionView!
    @IBOutlet weak var eventLocation: UILabel!
    @IBOutlet weak var eventLocationMap: MKMapView!
    @IBOutlet weak var eventDescription: UILabel!
    
    
    var event: Event!
    var eventIDs: Set<String> = []
    let ref = Database.database().reference()
    var memberData: [User] = []
    var imageCache = FirebaseManager.shared.imageCache
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0 :
            return UITableViewAutomaticDimension
        case 1:
            return 44
        case 2:
            return 100
        case 3:
            return 110
        case 4 :
            return 44
        case 5:
            return 177
        case 6:
            return UITableViewAutomaticDimension
        default:
            break
        }
        return UITableViewAutomaticDimension
    }
    
    func setLocationAnnotation() {
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(self.event.location) { (placemarks, error) in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let placemarks = placemarks else {
                print("Fail to get placemarks")
                return
            }
            
            let annotation = MKPointAnnotation()
            
            guard let location = placemarks[0].location else {
                print("Fail to get placemarks[0].location")
                return
            }
            
            annotation.coordinate = location.coordinate
            annotation.title = self.event.location
            self.eventLocationMap.addAnnotation(annotation)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
            self.eventLocationMap.setRegion(region, animated: false)
            
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLocationAnnotation()
        self.queryEventList()
        self.queryOrganiserData()
        self.queryMemberData()
        self.memberCollectionView.dataSource = self
        
        self.eventTitle.text = self.event.title
        self.eventDate.text = self.event.date
        self.eventLocation.text = self.event.location
        self.eventDescription.text = self.event.description
        self.eventImageView.image = self.event.image
        
        
        // 建立時間格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
    }
    
    func queryEventList() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        
        let ref = Database.database().reference().child("eventList").child(uid)
        
        FirebaseManager.shared.getDataBySingleEvent(ref, type: .childAdded) { (allObject, dict) in
            
            guard let dict = dict else {
                print("Fail to get data")
                return
            }
            
            let eventID = dict["eventID"] as! String
            self.eventIDs.insert(eventID)
        
        
        guard self.eventIDs.contains(self.event.eventID) || self.event.organiserID == uid else{
            
            let alert = UIAlertController(title: "提示", message: "是否同意加入\(self.event.title)?", preferredStyle: .alert)
            let agree = UIAlertAction(title: "同意", style: .default) { (action) in
                
                guard let uid = Auth.auth().currentUser?.uid else{
                    return
                }
                self.ref.child("memberList").child(self.event.eventID).child(uid).child("memberID").setValue(uid)
                self.ref.child("eventList").child(uid).child(self.event.eventID).child("eventID").setValue(self.event.eventID)
            }
            let reject = UIAlertAction(title: "拒絕", style: .cancel) { (action) in
                
                self.navigationController?.popViewController(animated: true)
            }
            
            alert.addAction(agree)
            alert.addAction(reject)
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        }
    }
    
    
    // Query organiser's data from database.
    func queryOrganiserData() {
        
        let ref = Database.database().reference().child("user").child(self.event.organiserID)
        
        FirebaseManager.shared.getDataBySingleEvent(ref, type: .value) { (allObject, dict) in
            
            guard let dict = dict else {
                print("fail to get dict")
                return
            }
            
            let user = User(userID: dict["userID"] as! String,
                            email: dict["email"] as! String,
                            name: dict["name"] as! String,
                            profileImageURL: dict["profileImageURL"] as! String)
            
            self.organiserName.text = user.name
            
            
            // Show image from cache if that has been stored in there.
            if let image = self.imageCache.object(forKey: user.profileImageURL as NSString) as? UIImage {
                
                self.organiserProfileImage.image = image
            }else {
                
                // Download image from firebase storage.
                FirebaseManager.shared.getImage(urlString: user.profileImageURL) { (image) in
                    
                    guard let image = image else {
                        
                        print("Fail to get image")
                        return
                    }
                    
                    self.imageCache.setObject(image, forKey: user.profileImageURL as NSString)
                    self.organiserProfileImage.image = image
                }
            }
        }
    }
    
    
    func queryMemberData() {
        
        let memberRef = Database.database().reference().child("memberList").child(self.event.eventID)
        
        FirebaseManager.shared.getDataBySingleEvent(memberRef, type: .value) { (allObjects, dict) in
            
            for snap in allObjects {
                
                guard let dict = snap.value as? [String : Any] else {
                    print("Fail to get data")
                    return
                }
                
                let memberID = dict["memberID"] as! String
                let userRef = Database.database().reference().child("user").child(memberID)
                
                FirebaseManager.shared.getDataBySingleEvent(userRef, type: .value){ (allObjects, dict) in
                    
                    guard let dict = dict else {
                        print("Fail to get dict")
                        return
                    }
                    
                    let user = User(userID: dict["userID"] as! String,
                                    email: dict["email"] as! String,
                                    name: dict["name"] as! String,
                                    profileImageURL: dict["profileImageURL"] as! String)
                    
                    self.memberData.insert(user, at: 0)
                    self.memberCollectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                }
            }
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {

        self.navigationController?.popViewController(animated: true)
    }
    
    
    
}


extension EventContentVC: UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.memberData.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let memberCell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! MemberCollectionViewCell
        let member = self.memberData[indexPath.item]
        
        memberCell.deleteButton.isHidden = true
        memberCell.memberName.text = member.name
        memberCell.memberProfileImage.image = nil
        
        // Show image from cache if that has been stored in there.
        if let image = self.imageCache.object(forKey: member.profileImageURL as NSString) as? UIImage {
            
            memberCell.memberProfileImage.image = image
        }else {
            
            // Download image from firebase storage.
            FirebaseManager.shared.getImage(urlString: member.profileImageURL) { (image) in
                
                guard let image = image else {
                    print("Fail to get image")
                    return
                }
                
                self.imageCache.setObject(image, forKey: member.profileImageURL as NSString)
                memberCell.memberProfileImage.image = image
            }
        }
        
        return memberCell
    }
}

