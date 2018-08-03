import UIKit
import UserNotifications
import FirebaseAuth
import Firebase
import FirebaseMessaging
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    override init() {
        FirebaseApp.configure()
        //        Database.database().isPersistenceEnabled = true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        SVProgressHUD.setDefaultStyle(.dark)

        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            Messaging.messaging().delegate = self // For iOS 10 data message (sent via FCM)
            
            // 在程式一啟動即詢問使用者是否接受圖文(alert)、聲音(sound)、數字(badge)三種類型的通知
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { granted, error in
                if granted {
                    print("允許...")
                } else {
                    print("不允許...")
                }
            })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        guard let currentUser = Auth.auth().currentUser else {
            print("Fail to get current user.")
            return
        }
        self.queryNotificationCount(currentUser)
        
    
    }
    
    func queryNotificationCount(_ currentUser: User) {
        
        let notificationRef = FirebaseManager.shared.databaseReference.child("notification").queryOrdered(byChild: "time")
        
        FirebaseManager.shared.getData(notificationRef, type: .value) { (allObjects, dict) in
            
            let myNotification = allObjects.compactMap {(snap) -> GNotification? in
                
                let dict = snap.value as! [String : Any]
                
                let notification = GNotification(notificationID: dict["notificationID"] as! String,
                                                 userID: dict["userID"] as! String,
                                                 eventID: dict["eventID"] as! String,
                                                 message: dict["message"] as! String,
                                                 remark: dict["remark"] as! String,
                                                 isRead: dict["isRead"] as! Bool,
                                                 time: dict["time"] as! String,
                                                 isRemoved: dict["isRemoved"] as! Bool)
                
                return (currentUser.uid == notification.userID ? notification : nil)
            }
            
            var unReads: [GNotification] = []
            
            for notification in myNotification {
                
                if !notification.isRead {
                    
                    unReads.insert(notification, at: 0)
                }
                
                let tabbarController = self.window?.rootViewController as! UITabBarController
                let secondVC = tabbarController.viewControllers![1]
                DispatchQueue.main.async {
                    secondVC.tabBarItem.badgeValue = String(unReads.count)
                    if secondVC.tabBarItem.badgeValue == "0" {
                        secondVC.tabBarItem.badgeValue = nil
                    }
                }
                
                
            }
        }
        
    }

    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    }
    
    /// iOS10 以下的版本接收推播訊息的 delegate
    ///
    /// - Parameters:
    ///   - application: _
    ///   - userInfo: _
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
        // 印出後台送出的推播訊息(JOSN 格式)
        print("userInfo: \(userInfo)")
    }
    
    /// iOS10 以下的版本接收推播訊息的 delegate
    ///
    /// - Parameters:
    ///   - application: _
    ///   - userInfo: _
    ///   - completionHandler: _
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // 印出後台送出的推播訊息(JOSN 格式)
        print("userInfo: \(userInfo)")
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    /// 推播失敗的訊息
    ///
    /// - Parameters:
    ///   - application: _
    ///   - error: _
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    /// 取得 DeviceToken，通常 for 後台人員推播用
    ///
    /// - Parameters:
    ///   - application: _
    ///   - deviceToken: _
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // 將 Data 轉成 String
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("deviceTokenString: \(deviceTokenString)")
        
        // 將 Device Token 送到 Server 端...
        
    }
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// 推播送出時即會觸發的 delegate
    ///
    /// - Parameters:
    ///   - center: _
    ///   - notification: _
    ///   - completionHandler: _
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // 印出後台送出的推播訊息(JOSN 格式)
        let userInfo = notification.request.content.userInfo
        print("userInfo: \(userInfo)")
        
        // 可設定要收到什麼樣式的推播訊息，至少要打開 alert，不然會收不到推播訊息
        completionHandler([.badge, .sound, .alert])
    }
    
    /// 點擊推播訊息時所會觸發的 delegate
    ///
    /// - Parameters:
    ///   - center: _
    ///   - response: _
    ///   - completionHandler: _
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // 印出後台送出的推播訊息(JOSN 格式)
        let userInfo = response.notification.request.content.userInfo
        print("userInfo: \(userInfo)")
        
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    
    /// iOS10 含以上的版本用來接收 firebase token 的 delegate
    ///
    /// - Parameters:
    ///   - messaging: _
    ///   - fcmToken: _
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        // 用來從 firebase 後台推送單一裝置所必須的 firebase token
        print("Firebase registration token: \(fcmToken)")
    }
}
