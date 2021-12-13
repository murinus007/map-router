//
//  ViewController.swift
//  Map Router
//
//  Created by Alexey Sergeev on 08.12.2021.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    let addAddressButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        return button
    }()
    
    let resetButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 6
        button.tintColor = .white
        button.setTitle("reset", for: .normal)
        button.isHidden = true
        return button
    }()
    
    let routeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 6
        button.tintColor = .white
        button.setTitle("route", for: .normal)
        button.isHidden = true
        return button
    }()
    
    var annotations = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        setConstraints()
        
        addAddressButton.addTarget(self, action: #selector(add), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        routeButton.addTarget(self, action: #selector(route), for: .touchUpInside)
    }

    @objc func add() {
        alertAddAddress(title: "Add", placeholder: "Enter Address") { [self] text in
            setupPlacemark(addressPlace: text)
       }
    }
    
    @objc func reset() {
        
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        annotations = []
        routeButton.isHidden = true
        resetButton.isHidden = true
        
    }
    
    @objc func route() {
        
        for (index, annotation) in annotations.enumerated() {
            guard index + 1 < annotations.count else { return }
            createDirectionRequest(startCoordinate: annotation.coordinate,
                                   destinationCoordinate: annotations[index + 1].coordinate)
        }
        
    }
    
    private func setupPlacemark(addressPlace: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressPlace) { [self] placemarks, error in
            if let error = error {
                print(error)
                alertError(title: "error", message: error.localizedDescription)
                return
            }
            
            guard let placemarks = placemarks else { return }
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = addressPlace
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            
            annotations.append(annotation)
            
            if annotations.count > 1 {
                routeButton.isHidden = false
                resetButton.isHidden = false
            }
            
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    private func createDirectionRequest(startCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let startLocation = MKPlacemark(coordinate: startCoordinate)
        let destinationLocation = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let direction = MKDirections(request: request)
    
        direction.calculate { response, error in
            if let error = error {
                print(error)
                self.alertError(title: "error", message: error.localizedDescription)
                return
            }
            
            guard let response = response else { return }
            
            var minRoute = response.routes[0]
            for route in response.routes {
                minRoute = (route.distance < minRoute.distance) ? route : minRoute
            }
            
            self.mapView.addOverlay(minRoute.polyline)
            
        }
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
}


extension ViewController {
    func setConstraints() {
        view.addSubview(mapView)
        view.addSubview(addAddressButton)
        view.addSubview(resetButton)
        view.addSubview(routeButton)
        NSLayoutConstraint.activate([
            
            mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            mapView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        NSLayoutConstraint.activate([
            
            addAddressButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            addAddressButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addAddressButton.widthAnchor.constraint(equalToConstant: 42),
            addAddressButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        NSLayoutConstraint.activate([
            
            resetButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resetButton.widthAnchor.constraint(equalToConstant: 60),
            resetButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        NSLayoutConstraint.activate([
            
            routeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            routeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            routeButton.widthAnchor.constraint(equalToConstant: 60),
            routeButton.heightAnchor.constraint(equalToConstant: 42)
        ])

    }
}

