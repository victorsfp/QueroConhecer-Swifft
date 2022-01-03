//
//  PlaceFinderViewController.swift
//  QueroConhecer
//
//  Created by Victor Feitosa on 03/01/22.
//

import UIKit
import MapKit


enum PlaceFinderMessageType {
    case error(String)
    case confirmation(String)
}

protocol PlaceFinderDelegate: AnyObject {
    func addPlace(_ place:Place) -> Void
}

class PlaceFinderViewController: UIViewController {

    
    @IBOutlet weak var tfCity: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var aiLoading: UIActivityIndicatorView!
    @IBOutlet weak var viLoading: UIView!
    
    var place: Place!
    weak var delegate: PlaceFinderDelegate?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(getLocation(_:)))
        gesture.minimumPressDuration = 2.0
        mapView.addGestureRecognizer(gesture)
    }
    
    
    @objc func getLocation(_ gesture: UILongPressGestureRecognizer){
        if gesture.state == .began {
            load(show: true)
            let point = gesture.location(in: mapView) //Ele retorna X e Y do componente
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                self.load(show: false)
                if error == nil {
                    if !self.savePlace(with: placemarks?.first){
                        self.showMessage(type: .error("Não foi encontrado nenhum local com esse nome"))
                    }
                }else {
                    self.showMessage(type: .error("Erro desconhecido"))
                }
            }
        }
    }
    
    @IBAction func findCity(_ sender: UIButton) {
        tfCity.resignFirstResponder()
        let address = tfCity.text!
        load(show: true)
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            self.load(show: false)
            if error == nil {
                if !self.savePlace(with: placemarks?.first){
                    self.showMessage(type: .error("Não foi encontrado nenhum local com esse nome"))
                }
            }else {
                self.showMessage(type: .error("Erro desconhecido"))
            }
        }
    }
    
    func savePlace(with placemark: CLPlacemark?) -> Bool {
        guard let placemark = placemark, let coordinate = placemark.location?.coordinate else {
            return false
        }
        
        let name = placemark.name ?? placemark.country ?? "Desconhecido"
        let address = Place.getFormatedAddress(with: placemark)
        
        let place = Place(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude, address: address)
        self.place = place
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3500, longitudinalMeters: 3500)
        //let region = MKCoordinateRegionMakeWithDistance(coordinate, latitudinalMeters, longitudinal)
        
        mapView.setRegion(region, animated: true)
        self.showMessage(type: .confirmation(place.name))
        
        return true
    }
    
    func showMessage(type: PlaceFinderMessageType){
        let title: String, message: String
        var hasConfirmation: Bool = false
        
        switch type {
            case .error(let errorMessage):
                title = "Erro"
                message = errorMessage
            case .confirmation(let name):
                title = "Local encontrado"
                message = "Deseja adicionar \(name)?"
                hasConfirmation = true
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        if hasConfirmation {
            let confirmAction = UIAlertAction(title: "OK", style: .default) { action in
                self.delegate?.addPlace(self.place)
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(confirmAction)
        }
        present(alert, animated: true, completion: nil)
    }
    
    func load(show: Bool){
        viLoading.isHidden = !show
        if show {
            aiLoading.startAnimating()
        }else{
            aiLoading.stopAnimating()
        }
    }
    
    @IBAction func close(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
