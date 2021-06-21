//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Егор Шкарин on 10.06.2021.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {

    var mapManager = MapManager()
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    // Идентификатор для опрделенной аннотации для метки на карте
    let annotationIdentifier = "annotationIdentifier"
    // Идентификатор для сегуэя в этом классе нужен для того чтобы понимать с какой кнопки мы на него переходим
    var incomeSegueIdentifier = ""
    var previousLocation: CLLocation? {
        didSet{
            mapManager.startTrackingUserLocation(for: self.mapView,
                                                 and: previousLocation)
            { currentLocation in
                self.previousLocation = currentLocation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
                }
            }
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.adressLabel.text = ""
        mapView.delegate = self
        setupMapView()
    }
    
    @IBAction func closeVC(_ sender: Any) {
        //Уничножение котроллера
        dismiss(animated: true, completion: nil)
    }
    /// Эта функция для того чтобы перейти на локацию пользователя
    @IBAction func centerViewInUserLocation() {
        mapManager.showUserLocation(mapView: self.mapView)
    }
    /// в этой функции мы проверяем входящий идентификатор и вызываем функцию для создания метки
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(adressLabel.text)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goButtonPressed() {
        mapManager.getDirections(for: self.mapView) { location in
            self.previousLocation = location
        }
    }
    
    // Сетапим карту в зависимости от сегуэя
    private func setupMapView() {
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: self.mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        if incomeSegueIdentifier == "showPlace" {
            mapManager.setUpPlaceMark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            doneButton.isHidden = true
            adressLabel.isHidden = true
            goButton.isHidden = false
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {return nil}
        // Забираем нашу аннтацию по ее идетификатору
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        // Соответственно если ее нет присваиваем ее
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: annotationIdentifier)
            // Эта хуета нужна для того чтобы мы могли отображать доп инфу по объекту на карте
            annotationView?.canShowCallout = true
        }
        if let imageData = place.image {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    // Этот метод будет срабатывать при каждом изменении региона куда смотрит камера
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapManager.getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center) { placeMarks, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let placeMarks = placeMarks else {return}
            
            let placeMark = placeMarks.first
            // thoroughfare выдергивает название улицы
            let streetName = placeMark?.thoroughfare
            // subThoroughfare выдергивает номер дома
            let buildNumber = placeMark?.subThoroughfare
            // Весь интерфейс рабоатет в основном потоке, поэтому надо воткунть адрес туда
            DispatchQueue.main.async {
                if streetName != nil, buildNumber != nil {
                    self.adressLabel.text = "\(streetName!), \(buildNumber!)"

                } else if streetName != nil {
                    self.adressLabel.text = "\(streetName!)"
                } else {
                    self.adressLabel.text = ""
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        mapManager.checkLocationAuthorization(mapView: self.mapView, segueIdentifier: incomeSegueIdentifier)
    }
}
