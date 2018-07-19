import UIKit
import CoreLocation
import MapKit

protocol LoginVCDelegate {
    func getCoordinate(_ coordinate: CLLocationCoordinate2D)
}


class LocationVC: UIViewController {

    @IBOutlet weak var confirm: UIBarButtonItem!
    var selectedPin:MKPlacemark!
    var delegate: LoginVCDelegate?
    var locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    
    var resultSearchController: UISearchController!

    

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
        searchBar.placeholder = "Search for places"

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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirmPressed(_ sender: Any) {
        self.delegate?.getCoordinate(self.selectedPin.coordinate)
        self.navigationController?.popViewController(animated: true)
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

extension LocationVC: CLLocationManagerDelegate, MKMapViewDelegate {
    
    

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error)")
    }
}

extension LocationVC: HandleMapSearch {
    
    func dropPinZoomIn(placemark:MKPlacemark){
        self.confirm.isEnabled = true
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city),\(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
}
