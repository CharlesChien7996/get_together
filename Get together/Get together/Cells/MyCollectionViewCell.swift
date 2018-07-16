import UIKit
protocol MemberCollectionViewCellDelegate {
    func deleteData(cell: MemberCollectionViewCell)
}
class MemberCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var memberProfileImage: UIImageView!
    
    @IBOutlet weak var memberName: UILabel!
    
    var delegate: MemberCollectionViewCellDelegate?
    var indexPath: IndexPath?
    
    @IBAction func deletePressed(_ sender: Any) {
        self.delegate?.deleteData(cell: self)
    }
    
}
