import UIKit

class RootVC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // 設定點選tab時回到root
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        if self.selectedIndex == 0 || self.selectedIndex == 1 {
            let firstVC = self.viewControllers![0] as! UINavigationController
            let secondVC = self.viewControllers![1] as! UINavigationController
            firstVC.popToRootViewController(animated: false)
            secondVC.popToRootViewController(animated: false)
        }
    }

}
