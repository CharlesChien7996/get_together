import UIKit
import UserNotifications

class EventAlertVC: UIViewController {
    
    var event: Event!
    
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var alertDate: UILabel!
    @IBOutlet weak var alertDatePicker: UIDatePicker!
    @IBOutlet weak var alertSettingSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.alertDatePicker.addTarget(self, action: #selector(dateChanged(sender:)), for: UIControlEvents.valueChanged)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.alertDatePicker.maximumDate = dateFormatter.date(from: self.event.date)
        
        if let isAlertSwitchOn = UserDefaults.standard.object(forKey: "isAlertSwitchOn") {
            self.alertSettingSwitch.isOn = isAlertSwitchOn as! Bool
        }
        
        
        self.eventImageView.image = self.event.image
        self.eventTitle.text = self.event.title
        
        if self.alertSettingSwitch.isOn {
            
            self.alertDate.text = UserDefaults.standard.object(forKey: "alertDate") as? String
        }else {
            
            self.alertDate.text = self.event.date
        }
        
        let eventDate = self.alertDate.text!
        let now = dateFormatter.string(from: Date())
        
        if eventDate < now {
            self.alertDate.text = "已過期"
            self.alertDatePicker.isHidden = true
            self.alertSettingSwitch.isHidden = true
        }
        


    }
    
    @IBAction func alertSettingSwitch(_ sender: UISwitch) {
        
        if  sender.isOn {
            
            let content = UNMutableNotificationContent()
            content.title = "您的活動「\(self.event.title)」即將到來"
            content.body = "別忘了赴約喔：）"
            content.badge = nil
            
            content.sound = UNNotificationSound.default()
            
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy-MM-dd HH:mm"
            let date = dateformatter.date(from: self.alertDate.text!)
            
            let components = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: date!)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request){error in
                print("成功建立通知...")
            }
            
            UserDefaults.standard.setValue(self.alertDate.text, forKey: "alertDate")
            UserDefaults.standard.set(true, forKey: "isAlertSwitchOn")
        }else {
            UserDefaults.standard.set(false, forKey: "isAlertSwitchOn")

        }
        


    }
    
    
    
    @IBAction func alertDatePicker(_ sender: Any) {
    }
    
    @objc func dateChanged(sender:UIDatePicker){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.alertDate.text = dateFormatter.string(from: self.alertDatePicker.date)
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
