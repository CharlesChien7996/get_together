import UIKit

class MyEventCell: UITableViewCell {
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }

    override func prepareForReuse() {
        self.eventImageView.image = nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
