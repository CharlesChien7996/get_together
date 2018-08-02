import Foundation
import Firebase
import FirebaseStorage

class FirebaseManager {
    
    static let shared = FirebaseManager()
    private init() {
        
    }
    let databaseReference: DatabaseReference = Database.database().reference()
    var imageCache = NSCache<NSString, AnyObject>()
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var user:GUser?
    
    func getData(_ reference:DatabaseQuery, type: DataEventType, completionHandler: @escaping (_ allObjects: [DataSnapshot], _ dict: Dictionary<String,Any>?) -> Void) {
        
        
        reference.observe(type) { (snapshot: DataSnapshot) in
            
            completionHandler(snapshot.children.allObjects as! [DataSnapshot], snapshot.value as? [String : Any])
            
        }
    }
    
    
    func getDataBySingleEvent(_ reference:DatabaseQuery, type: DataEventType, completionHandler: @escaping (_ allObjects: [DataSnapshot], _ dict: Dictionary<String,Any>?) -> Void) {
        
        reference.observeSingleEvent(of: type) { (snapshot) in
            completionHandler(snapshot.children.allObjects as! [DataSnapshot], snapshot.value as? [String : Any])
            
        }
    }
    
    
    func getImage(urlString: String, completionHandler: @escaping (_ image: UIImage?) -> Void) {
        
        guard let imageURL = URL(string: urlString) else {
            print("Fail to get imageURL")
            return
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
            
            
            
            DispatchQueue.main.async {
                completionHandler(image)
                
            }
            
            
        }
        task.resume()
    }
    
    
    // Convert image into thumbnail.
    func thumbnail(_ image: UIImage?, widthSize: Int, heightSize: Int) -> UIImage? {
        
        guard let image = image else {
            print("Fail to get image")
            return nil
        }
        
        let thumbnailSize = CGSize(width: widthSize, height: heightSize)
        let scale = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, scale)
        
        let widthRatio = thumbnailSize.width / image.size.width
        let heightRatio = thumbnailSize.height / image.size.height
        
        let ratio = max(widthRatio, heightRatio)
        
        let imageSize = CGSize(width: image.size.width*ratio, height: image.size.height*ratio)
        let cgRect = CGRect(x: -(imageSize.width - thumbnailSize.width) / 2, y: -(imageSize.height - thumbnailSize.height) / 2, width: imageSize.width, height: imageSize.height)
        image.draw(in: cgRect)
        
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return smallImage
    }
    
    
    func uploadImage(_ reference: StorageReference, image: UIImage, completionHandler: @escaping (_ imageURL: URL) -> Void){
        
        
        
        guard let imageData = UIImageJPEGRepresentation(image, 1) else{
            print("Fail to get imageData")
            return
        }
        
        reference.putData(imageData, metadata: nil) { (metadata, error) in
            
            if let error = error {
                print("error: \(error)")
                return
            }
            
            reference.downloadURL() { (url, error) in
                
                guard let url = url else{
                    print("error: \(error!)")
                    return
                }
                
                completionHandler(url)
            }
        }
    }
    
    
    public func showOverlay(view: UIView) {
        
        overlayView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.lightGray
        overlayView.clipsToBounds = true
        overlayView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = CGPoint(x: overlayView.bounds.width / 2 ,y: overlayView.bounds.height / 2)
        
        
        overlayView.addSubview(activityIndicator)
        view.addSubview(overlayView)
        
        activityIndicator.startAnimating()
    }
    
    public func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
    
    
    // Set up UIActivityUndicatorView.
    func setUpActivityUndicatorView(_ view: UIView, activityIndicatorView: UIActivityIndicatorView) {
        
        activityIndicatorView.activityIndicatorViewStyle = .gray
        activityIndicatorView.center = view.center
        activityIndicatorView.hidesWhenStopped = true
        view.addSubview(activityIndicatorView)
    }
    
    func setUpLoadingView(_ viewController: UIViewController){
        
        let alert = UIAlertController(title:"", message: "載入中...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        viewController.present(alert, animated: true, completion: nil)
    }
    
    
    func setUpLoadingView(_ tableViewController: UITableViewController){
        
        let alert = UIAlertController(title:"", message: "載入中...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        tableViewController.present(alert, animated: true, completion: nil)
    }
    
}
