import Foundation
import Firebase
import FirebaseStorage

class FirebaseManager {
    
    static let shared = FirebaseManager()
    private init() {
        
    }
    let databaseReference: DatabaseReference = Database.database().reference()
    var imageCache = NSCache<NSString, AnyObject>()

    
    func getData(_ reference:DatabaseQuery, type: DataEventType, completionHandler: @escaping (_ allObjects: [DataSnapshot], _ dict: Dictionary<String,Any>) -> Void) {
        
        
        reference.observe(type) { (snapshot: DataSnapshot) in
            
            completionHandler(snapshot.children.allObjects as! [DataSnapshot], snapshot.value as! [String : Any])
            
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
    func thumbnail(_ image: UIImage?) -> UIImage? {
        guard let image = image else {
            print("Fail to get imageData")
            return nil
        }
        
        let thumbnailSize = CGSize(width: 80, height: 80)
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
    
    
    func uploadImage(_ reference: StorageReference, image: UIImage?, completionHandler: @escaping (_ imageURL: URL) -> Void){
        
        guard let imageData = UIImageJPEGRepresentation(image!, 1) else{
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
    

}
