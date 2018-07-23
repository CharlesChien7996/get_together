//
//  ProfileVC.swift
//  Get together
//
//  Created by 簡士荃 on 2018/7/5.
//  Copyright © 2018年 Charles. All rights reserved.
//

import UIKit
import Firebase

class ProfileVC: UIViewController {

    @IBOutlet weak var logoutBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        if Auth.auth().currentUser == nil {
            self.logoutBtn.isHidden = true
        }
        // Do any additional setup after loading the view.
    }
    @IBAction func logoutPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
            self.present(loginVC, animated: true, completion: nil)
        }catch {
            print("error: \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
