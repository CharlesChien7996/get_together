import UIKit
import CoreLocation
import MapKit

protocol LoginVCDelegate: class {
    func getCoordinate(_ coordinate: CLLocationCoordinate2D)
}

class LocationVC: UIViewController {
    
    @IBOutlet weak var confirm: UIBarButtonItem!
    var selectedPin:MKPlacemark!
    weak var delegate: LoginVCDelegate?
    var locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    var resultSearchController: UISearchController!
    
//    override func viewWillDisappear(_ animated: Bool) {
//
//        super.viewWillDisappear(animated)
//        switch self.mapView.mapType {
//        case .hybrid:
//            self.mapView.mapType = .standard
//
//        case .standard:
//            self.mapView.mapType = .hybrid
//
//        default:
//            break
//        }
//        self.mapView.showsUserLocation = false
//        self.mapView.delegate = nil
//        self.mapView.removeFromSuperview()
//        self.mapView = nil
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location Service is not enable.")
            return
        }
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchVC
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = textFieldInsideUISearchBarLabel?.font.withSize(14)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "取消"
    
        searchBar.placeholder = "輸入地址或關鍵字來搜尋地點..."
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        
        // Ask user's permission.
        locationManager.requestAlwaysAuthorization()
        
        // prepare locationManager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .automotiveNavigation
        
        locationManager.startUpdatingLocation()
        
        self.mapView.delegate = self
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Get current location.
        guard let coordinate = locationManager.location?.coordinate else {
            print("Fail to get current location.")
            return
        }
        
        // Prepare region and set region.
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        self.mapView.setRegion(region, animated: true)
    }
    
    
    @IBAction func confirmPressed(_ sender: Any) {
        self.delegate?.getCoordinate(self.selectedPin.coordinate)
        self.navigationController?.popViewController(animated: true)
    }
    
}


extension LocationVC: CLLocationManagerDelegate, MKMapViewDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error)")
    }
}


extension LocationVC: HandleMapSearch {
    
    func dropPinZoomIn(placemark:MKPlacemark){
        
        self.confirm.isEnabled = true
        
        selectedPin = placemark
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        
        if let city = placemark.locality, let state = placemark.administrativeArea {
            
            annotation.subtitle = "\(city),\(state)"
        }
        
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
}
