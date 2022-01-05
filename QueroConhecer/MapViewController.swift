//
//  MapViewController.swift
//  QueroConhecer
//
//  Created by Victor Feitosa on 03/01/22.
//

import UIKit
import MapKit

enum MapMessageType {
    case routeError
    case authorizationWarning
}

class MapViewController: UIViewController {

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viInfo: UIView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var places: [Place]!
    var poi: [MKAnnotation] = []
    lazy var locationManager = CLLocationManager()
    var btUserLocation: MKUserTrackingButton!
    var selectedAnnotation: PlaceAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.layer.cornerRadius = 10.0
        
        searchBar.isHidden = true
        viInfo.isHidden = true
        mapView.layer.borderWidth = 5.0
        mapView.layer.borderColor = CGColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0)
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        locationManager.delegate = self
        
        
        if places.count == 1 {
            title = places[0].name
        }else{
            title = "Meus lugares"
        }
        
        for place in places {
            addToMap(place)
        }
        // Do any additional setup after loading the view.
        
        configureLocationButton()
        showPlaces()
        requestUserLocationAuthorization()
    }
    
    func configureLocationButton(){
        btUserLocation = MKUserTrackingButton(mapView: mapView)
        btUserLocation.backgroundColor = .white
        btUserLocation.frame.origin.x = 10
        btUserLocation.frame.origin.y = 10
        btUserLocation.layer.cornerRadius = 5
        btUserLocation.layer.borderWidth = 1.0
        btUserLocation.layer.borderColor = UIColor(named: "main")?.cgColor
    }
    
    func requestUserLocationAuthorization(){
        if CLLocationManager.locationServicesEnabled() {
            //switch CLLocationManager.authorizationStatus()
            switch locationManager.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse, .authorized:
                    //MOSTRAR O BOTÃO DE LOCALIZAÇÃO NO MAPA
                    mapView.addSubview(btUserLocation)
                case .denied:
                    showMessage(type: .authorizationWarning)
                case .notDetermined:
                    locationManager.requestWhenInUseAuthorization()
                case . restricted:
                    break
            default:
                break
                
            }
        }
    }
    
    
    func addToMap(_ place: Place){
        let annotation = PlaceAnnotation(coordinate: place.coordinate, type: .place)
        annotation.title = place.name
        annotation.address = place.address
        mapView.addAnnotation(annotation)
    }
    
    func showPlaces(){
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func showInfo(){
        lbName.text = selectedAnnotation?.title
        lbAddress.text = selectedAnnotation?.address
        viInfo.isHidden = false
    }

    
    @IBAction func showRoute(_ sender: UIButton) {
        if locationManager.authorizationStatus != .authorizedWhenInUse {
            showMessage(type: .authorizationWarning)
            return
        }
        
        let request = MKDirections.Request()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: selectedAnnotation!.coordinate))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location!.coordinate))
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if error == nil {
                if let response = response {
                    self.mapView.removeOverlays(self.mapView.overlays)
                    
                    let route = response.routes.first!
                    
                    print("Nome: ", route.name)
                    print("Distancia: ", route.distance)
                    print("Duração: ", route.expectedTravelTime)
                    print("=============")
                    
                    for step in route.steps {
                        print("Em \(step.distance) metros(s), \(step.instructions)")
                    }
                    
                    self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    
                    var annotations = self.mapView.annotations.filter({ !($0 is PlaceAnnotation)  })
                    annotations.append(self.selectedAnnotation!)
                    
                    self.mapView.showAnnotations(annotations, animated: true)
                }
            } else {
                self.showMessage(type: .routeError)
            }
        }
    }
    
    @IBAction func showSearchBar(_ sender: Any) {
        searchBar.resignFirstResponder()
        searchBar.isHidden = !searchBar.isHidden
    }
    
    func showMessage(type: MapMessageType){
        let title: String = type == .authorizationWarning ? "Aviso" : "Erro"
        let message: String = type == .authorizationWarning ? "Para usar os recursos de localização do App, você precisa permitir o uso na tela de Ajustes" : "não foi possível encontrar essa rota"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)

        alert.addAction(cancelAction)
        if type == .authorizationWarning {
            let confirmAction = UIAlertAction(title: "Ir para ajustes", style: .default) { action in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }
            alert.addAction(confirmAction)
        }
        present(alert, animated: true, completion: nil)
    }
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is PlaceAnnotation){
            return nil
        }
        
        let type = (annotation as! PlaceAnnotation).type
        let identifier = "\(type)"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        annotationView?.annotation = annotation
        annotationView?.canShowCallout = true
        annotationView?.markerTintColor = type == .place ? UIColor(named: "main") : UIColor(named: "poi")
        annotationView?.glyphImage = type == .place ? UIImage(named: "placeGlyph") : UIImage(named: "poiGlyph")
        annotationView?.displayPriority = type == .place ? .required : .defaultHigh
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let camera = MKMapCamera()
        camera.centerCoordinate = view.annotation!.coordinate
        camera.pitch = 80 //EM GRAUS 80 Graus
        camera.altitude = 100
        mapView.setCamera(camera, animated: true)
        
        
        selectedAnnotation = (view.annotation as! PlaceAnnotation)
        showInfo()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(named: "main")?.withAlphaComponent(0.8)
            renderer.lineWidth = 5.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}


extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.isHidden = true
        searchBar.resignFirstResponder()
        loading.startAnimating()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBar.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if error == nil {
                guard let response = response else {
                    self.loading.stopAnimating()
                    return
                }
                
                self.mapView.removeAnnotations(self.poi)
                self.poi.removeAll()
                
                for item in response.mapItems {
                    let annotation = PlaceAnnotation(coordinate: item.placemark.coordinate, type: .poi)
                    annotation.title = item.name
                    annotation.subtitle = item.phoneNumber
                    annotation.address = Place.getFormatedAddress(with: item.placemark)
                    self.poi.append(annotation)
                }
                self.mapView.addAnnotations(self.poi)
                self.mapView.showAnnotations(self.poi, animated: true)
            }
            self.loading.stopAnimating()
        }
    }
}


extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                mapView.showsUserLocation = true
                mapView.addSubview(btUserLocation)
                locationManager.startUpdatingLocation()
            default:
                break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if  let location = locations.last {
//            print("Velocidade: ", location.speed)
//            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
//            mapView.setRegion(region, animated: true)
//        }

    }
}
