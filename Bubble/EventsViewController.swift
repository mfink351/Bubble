//
//  EventsViewController.swift
//  Bubble
//
//  Created by Mike Fink on 1/29/15.
//  Copyright (c) 2016 Mike Fink. All rights reserved.
//
//  Credit to Ken Toh's Geofencing App

import UIKit
import MapKit
import HealthKit
import CoreLocation

//let kSavedItemsKey = "savedItems"

class EventsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

  /*@IBOutlet weak var mapView: MKMapView!

  var events = [Event]()
  let locationManager = CLLocationManager()
  let healthStore = HKHealthStore()

  override func viewDidLoad() {
    super.viewDidLoad()

    // 1
    locationManager.delegate = self
    // 2
    locationManager.requestAlwaysAuthorization()
    // 3
    loadAllEvents()
    
    let spoofTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("spoof"), userInfo: nil, repeats: true)
    let heartTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("getHeartRate"), userInfo: nil, repeats: true)
  }
    
    func inRegion() -> Bool{
        let string = NSString(data: getJSON("https://people.rit.edu/mrf1379/spoof.json"), encoding: NSUTF8StringEncoding)!
        if string.lowercaseString.rangeOfString("true") != nil {
            return true
        } else {
            return false
        }
    }
    
    func spoof()
    {
        if !inRegion() {
            showSimpleAlertWithTitle("Whoah!", message: "Max has left the area! Better go check in!", viewController: self)
        }
    }
    
    //Functionaility to get heartrate
    func getHeartRate(){
        
        let heartRateType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        
        if (HKHealthStore.isHealthDataAvailable()){
            healthStore.requestAuthorizationToShareTypes(nil, readTypes:[heartRateType], completion:{(success, error) in
                let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:false)
                let timeFormatter = NSDateFormatter()
                
                timeFormatter.dateFormat = "hh:mm:ss"
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MM/dd/YYYY"
                
                let query = HKSampleQuery(sampleType:heartRateType, predicate:nil, limit:2, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
                    guard let results = results else { return }
                    //for quantitySample in results {
                        let quantity = (results.first as! HKQuantitySample).quantity
                        let heartRateUnit = HKUnit(fromString: "count/min")
                        
                        let heartRate = quantity.doubleValueForUnit(heartRateUnit)
                        //print(heartRate)
                        if( heartRate < 60.0){
                            showSimpleAlertWithTitle("SOS!", message: "Mike's heart rate dropped below 60! Go check on them!", viewController: self)
                        }
                        print("\(timeFormatter.stringFromDate(results.first!.startDate)),\(dateFormatter.stringFromDate(results.first!.startDate)),\(quantity.doubleValueForUnit(heartRateUnit))")
                    //}
                    
                    
                })
                self.healthStore.executeQuery(query)
            })
        }
        
        //return totalHeartRate/totalCount;
    }
    

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "addEvent" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddEventViewController
      //vc.delegate = self
    }
  }

  // MARK: Loading and saving functions

  func loadAllEvents() {
    events = []

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

  // MARK: AddEventViewControllerDelegate

  func addEventViewController(controller: AddEventViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    // 1
    let clampedRadius = (radius > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius

    let event = Event(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
    addEvent(event)
    // 2
    startMonitoringEvent(event)

    saveAllEvents()
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
      circleRenderer.strokeColor = UIColor.purpleColor()
      circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
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
    locationManager.startMonitoringForRegion(region)
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
    print("Monitoring failed for region with identifier: \(region.identifier)")
  }

  func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
    print("Location Manager failed with the following error: \(error)")
  }*/

}
