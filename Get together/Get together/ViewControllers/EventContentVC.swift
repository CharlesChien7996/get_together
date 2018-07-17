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

class EventContentVC: UITableViewController {
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var eventContent: UITextView!
    
    var event: Event!
    var eventIDs: Set<String> = []
//    var isNewMember: Bool = false
    let ref = Database.database().reference()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.eventContent.text = self.event.description
        self.eventImageView.image = self.event.image
        // 建立時間格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"


    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Table view data source
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 4
//    }
//    //
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//
//        if section == 0 {
//            return 2
//        }else if section == 1 && self.isOn {
//            return 2
//        }else {
//            return 1
//
//        }
//
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


