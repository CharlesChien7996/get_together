import UIKit
import UserNotifications

class EventAlertVC: UIViewController {
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var alertDate: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var event: Event!
    var alertOptions: [String] = ["活動開始時間", "5分鐘前", "15分鐘前", "30分鐘前", "1小時前", "3小時前", "1天前"]
    var alertStatus: [Bool] = [false, false, false, false, false, false, false]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let alertOptions = UserDefaults.standard.array(forKey: self.event.eventID) {
            self.alertStatus = alertOptions as! [Bool]
        }
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        
        self.eventImageView.image = self.event.image
        self.eventTitle.text = self.event.title
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
       let eventDate = dateFormatter.date(from: self.event.date)!

        if eventDate < Date() {
            self.alertDate.text = "活動已過期"
            self.alertDate.isHidden = false
            self.tableView.isHidden = true

        }else {
            self.alertDate.text = self.event.date
        }
    }
    
    func setAlertDate(_ option: Int) -> (Date, String) {
        
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm"
        var date: Date!
        var alertID: String!
        
        switch option {
            
        case 0:
            date = dateformatter.date(from: self.event.date)
            alertID = self.event.eventID
        case 1:
            date = dateformatter.date(from: self.event.date)! - 5 * 60
            alertID = self.event.eventID + "5m"
        case 2:
            date = dateformatter.date(from: self.event.date)! - 15 * 60
            alertID = self.event.eventID + "15m"
        case 3:
            date = dateformatter.date(from: self.event.date)! - 30 * 60
            alertID = self.event.eventID + "30m"
        case 4:
            date = dateformatter.date(from: self.event.date)! - 60 * 60
            alertID = self.event.eventID + "1h"
        case 5:
            date = dateformatter.date(from: self.event.date)! - 3 * 60 * 60
            alertID = self.event.eventID + "3h"
        case 6:
            date = dateformatter.date(from: self.event.date)! - 24 * 60 * 60
            alertID = self.event.eventID + "1d"

        default:
            date = Date()
            alertID = self.event.eventID
        }
        
        return (date, alertID)
    }
    

    func setLocalNotification(_ date: Date, alertID: String) {
        
        let content = UNMutableNotificationContent()
        content.title = "您的活動「\(self.event.title)」即將到來"
        content.body = "別忘了赴約喔：）"
        
        content.sound = UNNotificationSound.default()
        
        let components = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: date)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: alertID, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request){error in
            print("成功建立通知...")
        }
    }
    
    
    
    
//
//    func saveChecklistItems() {
//
//        let encoder = PropertyListEncoder()
//        do {
//
//            let data:Data = try encoder.encode(alertOptions)
//            try data.write(to: dataFilePath(),options: Data.WritingOptions.atomic)
//
//        } catch {
//            print("Error encoding item array!")
//        }
//    }
//
//    func loadChecklistItems() {
//
//        let path = dataFilePath()
//        if let data = try? Data(contentsOf: path) {
//            let decoder = PropertyListDecoder()
//            do {
//                alertOptions = try decoder.decode([AlertOptionItem].self,from: data)
//            } catch {
//                print("Error decoding item array!")
//            }
//        }
//    }
//
//
//    func dataFilePath() -> URL {
//
//        let paths = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask)
//
//        return paths[0].appendingPathComponent("Checklists.plist")
//    }
    

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

extension EventAlertVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.alertOptions.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let alertOptionCell = self.tableView.dequeueReusableCell(withIdentifier: "alertOptionCell", for: indexPath)
        let alertOption = self.alertOptions[indexPath.row]
        let isAlertOn = self.alertStatus[indexPath.row]
        
        alertOptionCell.textLabel?.text = alertOption
        if isAlertOn == true {
            alertOptionCell.accessoryType = .checkmark
        }else {
            alertOptionCell.accessoryType = .none
        }
        
        return alertOptionCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var isAlertOn = self.alertStatus[indexPath.row]
        var removedIDs: [String] = []
        
        isAlertOn = !isAlertOn
        self.alertStatus[indexPath.row] = isAlertOn
        UserDefaults.standard.set(self.alertStatus, forKey: self.event.eventID)
        tableView.reloadData()
        let result = self.setAlertDate(indexPath.row)
        
        if isAlertOn == true {
            
        self.setLocalNotification(result.0, alertID:result.1 )
            if removedIDs.count > 0 {
                removedIDs.removeAll()
            }
        }else {
            removedIDs.append(result.1)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: removedIDs)
        }
        
    }  
}
