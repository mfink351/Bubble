//
//  Event.swift
//  Bubble
//
//  Created by Mike Fink on 1/29/15.
//  Copyright (c) 2016 Mike Fink. All rights reserved.
//
//  Based on Ken Toh's Geofencing App

import UIKit
import MapKit
import CoreLocation

let kGEventLatitudeKey = "latitude"
let kEventLongitudeKey = "longitude"
let kEventRadiusKey = "radius"
let kEventIdentifierKey = "identifier"
let kEventNoteKey = "note"
let kEventEventTypeKey = "eventType"

enum EventType: Int {
  case OnEntry = 0
  case OnExit
}

class Event: NSObject, NSCoding, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var radius: CLLocationDistance
  var identifier: String
  var note: String
  var eventType: EventType

  var title: String? {
    if note.isEmpty {
      return "No Note"
    }
    return note
  }

  var subtitle: String? {
    var eventTypeString = eventType == .OnEntry ? "On Entry" : "On Exit"
    return "Radius: \(radius)m - \(eventTypeString)"
  }

  init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, note: String, eventType: EventType) {
    self.coordinate = coordinate
    self.radius = radius
    self.identifier = identifier
    self.note = note
    self.eventType = eventType
  }

  // MARK: NSCoding

  required init(coder decoder: NSCoder) {
    let latitude = decoder.decodeDoubleForKey(kGEventLatitudeKey)
    let longitude = decoder.decodeDoubleForKey(kEventLongitudeKey)
    coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    radius = decoder.decodeDoubleForKey(kEventRadiusKey)
    identifier = decoder.decodeObjectForKey(kEventIdentifierKey) as! String
    note = decoder.decodeObjectForKey(kEventNoteKey) as! String
    eventType = EventType(rawValue: decoder.decodeIntegerForKey(kEventEventTypeKey))!
  }

  func encodeWithCoder(coder: NSCoder) {
    coder.encodeDouble(coordinate.latitude, forKey: kGEventLatitudeKey)
    coder.encodeDouble(coordinate.longitude, forKey: kEventLongitudeKey)
    coder.encodeDouble(radius, forKey: kEventRadiusKey)
    coder.encodeObject(identifier, forKey: kEventIdentifierKey)
    coder.encodeObject(note, forKey: kEventNoteKey)
    coder.encodeInt(Int32(eventType.rawValue), forKey: kEventEventTypeKey)
  }
}
