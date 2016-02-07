//
//  AddEventViewController.swift
//  Bubble
//
//  Created by Mike Fink on 1/29/15.
//  Copyright (c) 2016 Mike Fink. All rights reserved.
//
//  Based on Ken Toh's Geofencing App Cat

import UIKit
import MapKit
import CoreLocation

let kSavedItemsKey = "savedItemsd4"

class AddEventViewController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
  //var delegate: AddEventViewControllerDelegate!
  let locationManager = CLLocationManager()
  var events = [Event]()
    
  @IBOutlet weak var mapView: MKMapView!

  @IBOutlet var addButton: UIBarButtonItem!
  @IBOutlet var zoomButton: UIBarButtonItem!

  @IBOutlet weak var radiusTextField: UITextField!
  @IBOutlet weak var noteTextField: UITextField!

  @IBOutlet weak var menuButton: UIBarButtonItem!
  @IBOutlet weak var extraButton: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.mapView.delegate = self
    self.locationManager.delegate = self
    
    self.locationManager.requestAlwaysAuthorization()
    loadAllEvents()
    
    if revealViewController() != nil {
        //            revealViewController().rearViewRevealWidth = 62
        menuButton.target = revealViewController()
        menuButton.action = "revealToggle:"
        
        revealViewController().rightViewRevealWidth = 150
        extraButton.target = revealViewController()
        extraButton.action = "rightRevealToggle:"
        
        view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
    }

    zoomToUserLocationInMapView(mapView)
    navigationItem.rightBarButtonItems = [extraButton, zoomButton]
    tableView.tableFooterView = UIView()
  }

  @IBAction func textFieldEditingChanged(sender: UITextField) {
    addButton.enabled = !radiusTextField.text!.isEmpty && !noteTextField.text!.isEmpty
  }

  @IBAction func onCancel(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction private func onAdd(sender: AnyObject) {
    let coordinate = mapView.centerCoordinate
    let radius = (radiusTextField.text! as NSString).doubleValue
    let identifier = NSUUID().UUIDString
    let note = noteTextField.text
    let eventType = EventType.OnExit

    // 1
    let clampedRadius = (radius > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius
    
    let event = Event(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note!, eventType: eventType)
    addEvent(event)
    // 2
    startMonitoringEvent(event)
    
    saveAllEvents()
  }

  @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
    
    
    // MARK: Loading and saving functions
    
    func loadAllEvents() {
        events = []
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(kSavedItemsKey) {
            for savedItem in savedItems {
                if let event = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? Event {
                    addEvent(event)
                }
            }
        }
    }
    
    func saveAllEvents() {
        let items = NSMutableArray()
        for event in events {
            let item = NSKeyedArchiver.archivedDataWithRootObject(event)
            items.addObject(item)
        }
        NSUserDefaults.standardUserDefaults().setObject(items, forKey: kSavedItemsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    // MARK: Functions that update the model/associated views with event changes
    
    func addEvent(event: Event) {
        events.append(event)
        mapView.addAnnotation(event)
        addRadiusOverlayForEvent(event)
        updateEventsCount()
    }
    
    func removeEvent(event: Event) {
        if let indexInArray = events.indexOf(event) {
            events.removeAtIndex(indexInArray)
        }
        
        mapView.removeAnnotation(event)
        removeRadiusOverlayForEvent(event)
        updateEventsCount()
    }
    
    func updateEventsCount() {
        navigationItem.rightBarButtonItem?.enabled = (events.count < 20)
    }
    
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let identifier = "myEvent"
        if annotation is Event {
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .Custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteEvent")!, forState: .Normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.blueColor()
            circleRenderer.fillColor = UIColor.blueColor().colorWithAlphaComponent(0.4)
            return circleRenderer
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        // Delete event
        let event = view.annotation as! Event
        stopMonitoringEvent(event)
        removeEvent(event)
        saveAllEvents()
    }
    
    // MARK: Map overlay functions
    
    func addRadiusOverlayForEvent(event: Event) {
        mapView?.addOverlay(MKCircle(centerCoordinate: event.coordinate, radius: event.radius))
    }
    
    func removeRadiusOverlayForEvent(event: Event) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        if let overlays = mapView?.overlays {
            for overlay in overlays {
                if let circleOverlay = overlay as? MKCircle {
                    let coord = circleOverlay.coordinate
                    if coord.latitude == event.coordinate.latitude && coord.longitude == event.coordinate.longitude && circleOverlay.radius == event.radius {
                        mapView?.removeOverlay(circleOverlay)
                        break
                    }
                }
            }
        }
    }
    
    // MARK: Other mapview functions
    
    @IBAction func zoomToCurrentLocation(sender: AnyObject) {
        zoomToUserLocationInMapView(mapView)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .AuthorizedAlways)
    }
    
    func regionWithEvent(event: Event) -> CLCircularRegion {
        // 1
        let region = CLCircularRegion(center: event.coordinate, radius: event.radius, identifier: event.identifier)
        // 2
        region.notifyOnEntry = (event.eventType == .OnEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func startMonitoringEvent(event: Event) {
        // 1
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: self)
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            showSimpleAlertWithTitle("Warning", message: "Your event is saved but will only be activated once you grant Bubble permission to access the device location.", viewController: self)
        }
        // 3
        let region = regionWithEvent(event)
        // 4
        print(region)
        self.locationManager.startMonitoringForRegion(region)
    }
    
    func stopMonitoringEvent(event: Event) {
        for region in locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == event.identifier {
                    locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        print("Monitoring failed for region with identifier: \(region.identifier) \(error)")
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        print("Location Manager failed with the following error: \(error)")
    }
    

}
