import UIKit
import MapKit

protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}
class LocationSearchVC: UITableViewController {

    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView!
    weak var handleMapSearchDelegate: HandleMapSearch!

    override func viewDidLoad() {
        super.viewDidLoad()

    }


    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return self.matchingItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = self.parseAddress(selectedItem: selectedItem)

        return cell
    }
 

 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
        self.dismiss(animated: true, completion: nil)
    }
    

    
    func parseAddress(selectedItem: MKPlacemark) -> String {
        
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // 門牌號碼
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // 街 / 路
            selectedItem.thoroughfare ?? "",
            comma,
            // 市
            selectedItem.locality ?? "",
            secondSpace,
            // 州
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }

}

extension LocationSearchVC : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = self.mapView, let searchBarText = searchController.searchBar.text else {
            return
        }
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

