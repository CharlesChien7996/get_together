import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var commentContent: UILabel!
    @IBOutlet weak var timeInterval: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
