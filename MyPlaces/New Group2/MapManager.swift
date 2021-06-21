//
//  MapManager.swift
//  MyPlaces
//
//  Created by Егор Шкарин on 11.06.2021.
//

import UIKit
import MapKit

class MapManager {
    // менеджер для работы с картой
    let locationManager = CLLocationManager()
    // для площади региона (настрйока камеры для пользователя)
   private let regionInMeters = 1000.0
   private var directionsArray: [MKDirections] = []
   private var placeCoodinate:CLLocationCoordinate2D?
    
    /// Функция настройки метки на карте
    func setUpPlaceMark(place: Place, mapView: MKMapView) {
        // Первое - мы должны вытащить локацию объекта
        guard let location = place.location else {
            return
        }
        // Далее мы должны создать класс геокодера
        let geocoder = CLGeocoder()
        // Здесь эта функция переделывает из строкового адресса в координаты точки на карте. Злесь в замыкании прописывается сама метка для объекта на карте
        geocoder.geocodeAddressString(location) { placemarks, error in
            if let error = error {
                print(error)
            }
            // Так как в замыкание передается массив меток (может быть не одна) и этот массив опциональный мы должны извлечь метку
            guard let placemarks = placemarks else {return}
            // извлекаем первую метку
            let placemark = placemarks.first
            // в классе аннотации мы настраиваем сакму метку
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            // Мыдолжны вытащить локацию метка на карте что бы в следующей строчке перекинуть ее в локацию аннотации для этой метки (короче свомещаем аннотацию и саму метку
            guard let placemarkLocation = placemark?.location else {return}
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoodinate = placemarkLocation.coordinate
            // В первой строчке мы делаем метки видимыми
            mapView.showAnnotations([annotation], animated: true)
            //Выбирает указанную аннотацию и отображает для нее представление вызова. (я так понял, что этот метод указывается для конкретной аннотации, а предыдущий для всех)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: ()->()) {
        // Мпетод для того чтобы понять разрешил ли службы геолокации пользователь или нет
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title:"Локация не доступна",
                    message: "Чтобы включить: Настройки -> Конфиденциальность -> Службы геолокации"
                )
            }
        }
    }
    
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAdress" {showUserLocation(mapView: mapView)}
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title:"Локация не доступна",
                    message: "Чтобы включить: Настройки -> MyPlaces -> Геолокация"
                )
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title:"Локация не доступна",
                    message: "Чтобы включить: Настройки -> MyPlaces -> Геолокация"
                )
            }
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case is avilable")
        }
    }
    
     func showUserLocation(mapView: MKMapView) {
        // Ниже мы определяем через свойство location локацию пользователя и ее координаты
        if let location = locationManager.location?.coordinate {
            // Здесь мы выбираем регион площадью 10х10 км
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            // Перекидываем камеру на этот регион
            mapView.setRegion(region, animated: true)
        }
    }
    
    /// Функция получения маршрута
     func getDirections(for mapView: MKMapView, previousLocation: (CLLocation)->()) {
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Локация не определена")
            return
        }
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        guard let request = createDirectionsRequest(for: location) else {
            showAlert(title: "Error", message: "Путь не найден.")
            return
        }
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions, mapView: mapView)
        directions.calculate { response, error in
            if let error = error {
                print(error)
                return
            }
            guard let response = response else {
                self.showAlert(title: "Error", message: "Маршрут не найден")
                return
            }
            for route in response.routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    /// Настройка запроса для расчета маршрута 
    private func createDirectionsRequest(for coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoodinate else { return nil}
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destinationLocation = MKPlacemark(coordinate: destinationCoordinate)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
    }
    
    /// Меняем отображаему зону области карты в соответствии с перемещением пользователя
     func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        guard let location = location else {
            return
        }
        let center = getCenterLocation(for: mapView)
        
        guard center.distance(from: location) > 50 else {return}
        closure(center)
    }
    
    // Важно понимать, что перед построением новго маршрута необходжимо удалить все старые, чтобы не мешались
    private func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        // метод убирающий все маршруты с карты
        mapView.removeOverlays(mapView.overlays)
        // добавляем новые маршруты
        directionsArray.append(directions)
        // закрываем все маршруты
        let _ = directionsArray.map{ $0.cancel() }
        
        directionsArray.removeAll()
    }
    
    // Определение центра на карте
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
   
   private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
    
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
        
    }
}
