//
//  AddTableViewController.swift
//  Get together
//
//  Created by 簡士荃 on 2018/7/4.
//  Copyright © 2018年 Charles. All rights reserved.
//

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
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0 :
            return UITableViewAutomaticDimension
        case 1:
            return 44
        case 2:
            return 70
        case 3:
            return 80
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
            
            
            if let placemarks = placemarks {
                let annotation = MKPointAnnotation()

                if let location = placemarks[0].location {
                    annotation.coordinate = location.coordinate
                    annotation.title = self.event.location
                    self.eventLocationMap.addAnnotation(annotation)
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                    self.eventLocationMap.setRegion(region, animated: false)
            }
  
               
            }
            
            
        }

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLocationAnnotation()
        
        self.queryOrganiserData()
        self.queryMemberData()
        self.memberCollectionView.dataSource = self
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Fail to get uid")
            return
        }
        

        
        let ref = Database.database().reference().child("eventList").child(uid)
        
        ref.observe(.value) { (snapshot) in
       
            for snap in snapshot.children.allObjects as! [DataSnapshot] {
                
                guard let dict = snap.value as? [String : Any] else {
                    print("Fail to get data")
                    return
                }
                let eventID = dict["eventID"] as! String
                self.eventIDs.insert(eventID)

            }
            
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
            
            
            
//            for i in 0...self.eventIDs.count-1 {
//
//
//                if self.event.eventID == self.eventIDs[i] {
//                    self.isNewMember = false
//                    break
//                }else if i == self.eventIDs.count-1 {
//                    self.isNewMember = true
//                }
//
//                if self.isNewMember == true {
//                    let alert = UIAlertController(title: "提示", message: "是否同意加入\(self.event.title)?", preferredStyle: .alert)
//                    let agree = UIAlertAction(title: "同意", style: .default) { (action) in
//
//                        guard let uid = Auth.auth().currentUser?.uid else{
//                            return
//                        }
//                        self.ref.child("memberList").child(self.event.eventID).child(uid).child("memberID").setValue(uid)
//                        self.ref.child("eventList").child(uid).child(self.event.eventID).child("eventID").setValue(self.event.eventID)
//                    }
//                    let reject = UIAlertAction(title: "拒絕", style: .cancel) { (action) in
//
//                        self.navigationController?.popViewController(animated: true)
//                    }
//
//                    alert.addAction(agree)
//                    alert.addAction(reject)
//                    self.present(alert, animated: true, completion: nil)
//                }
//            }
        }

        
        self.eventTitle.text = self.event.title
        self.eventDate.text = self.event.date
        self.eventLocation.text = self.event.location
        self.eventDescription.text = self.event.description
        self.eventImageView.image = self.event.image
        

        // 建立時間格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"


    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Query organiser's data from database.
    func queryOrganiserData() {
        
        let ref = Database.database().reference().child("user").child(self.event.organiserID)
        
        FirebaseManager.shared.getDataBySingleEvent(ref, type: .value) { (allObject, dict) in
            guard let dict = dict else {
                return
            }
            let user = User(userID: dict["userID"] as! String,
                            email: dict["email"] as! String,
                             name: dict["name"] as! String,
                             profileImageURL: dict["profileImageURL"] as! String)
            
            let urlString = user.profileImageURL
           FirebaseManager.shared.getImage(urlString: urlString) { (image) in
                
                let smallImage = FirebaseManager.shared.thumbnail(image)
                DispatchQueue.main.async {
                    self.organiserProfileImage.image = smallImage
                    self.organiserName.text = user.name
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
                            return
                        }
                        let user = User(userID: dict["userID"] as! String,
                                        email: dict["email"] as! String,
                                        name: dict["name"] as! String,
                                        profileImageURL: dict["profileImageURL"] as! String)
                        
                        let urlString = user.profileImageURL
                        FirebaseManager.shared.getImage(urlString: urlString) { (image) in
                            
                            let smallImage = FirebaseManager.shared.thumbnail(image)
                            user.image = smallImage
                            self.memberData.insert(user, at: 0)
                            DispatchQueue.main.async {
                                self.memberCollectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
                            }
                            
                        }
                    }
                    
                }
            
            

        }
    }
    
    
    
    // MARK: - Table view data source
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 1
//    }
//    //
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//
//        if section == 0 {
//            return 7
//        }else {
//            return 0
//        }
//    }
    
 
    
    
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
extension EventContentVC: UICollectionViewDataSource {
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.memberData.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let memberCell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! MemberCollectionViewCell
        let member = self.memberData[indexPath.item]
        
                memberCell.memberName.text = member.name
                memberCell.memberProfileImage.image = member.image
                memberCell.deleteButton.isHidden = true
        
        
        return memberCell
}
}

