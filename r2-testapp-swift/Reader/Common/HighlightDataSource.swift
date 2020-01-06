//
//HighlightDataSource.swift
//  r2-testapp-swift
//
//  Created by Senda Li on 2018/7/19.
//
//  Copyright 2018 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import R2Shared

class HighlightDataSource: Loggable {
    
    let publicationID :String?
    private(set) var highlights = [HighlightData]()
    
    init() {
        self.publicationID = nil
        self.reloadHighlights()
    }
    
    init(publicationID: String) {
        self.publicationID = publicationID
        self.reloadHighlights()
    }
    
    func reloadHighlights() {
        if let list = try? HighlightDatabase.shared.highlights.highlightList(for: self.publicationID) {
            self.highlights = list ?? [HighlightData]()
            self.highlights.sort { (b1, b2) -> Bool in
                let locations1 = b1.locator.locations
                let locations2 = b2.locator.locations
                if b1.resourceIndex == b2.resourceIndex {
                    if let position1 = locations1.position, let position2 = locations2.position {
                        return position1 < position2
                    } else if let progression1 = locations1.progression, let progression2 = locations2.progression {
                        return progression1 < progression2
                    }
                }
                return b1.resourceIndex < b2.resourceIndex
            }
        }
    }
    
    var count: Int {
        return highlights.count
    }
    
    func highlight(at index: Int) -> HighlightData? {
        guard highlights.indices.contains(index) else {
            return nil
        }
        return highlights[index]
    }
    
    func getHighlights(_ href:String? = nil) -> [HighlightData]? {
        if let list = try? HighlightDatabase.shared.highlights.highlightList(doc: self.publicationID, resource:href) {
            return list
        }
        
        return nil
    }
    
    func getHighlight(_ id:String) -> HighlightData? {
        if let highlight = try? HighlightDatabase.shared.highlights.highlight(id) {
            return highlight
        }
        
        return nil
    }
    
    func updateHighlight(newHighlight:HighlightData) -> Bool? {
        return try? HighlightDatabase.shared.highlights.update(newHighlight:newHighlight)
    }
    
    func addAnnotation(_ id:String, newHighlight:HighlightData) -> Bool? {
        if getHighlight(id) == nil {
            return addHighlight(highlight: newHighlight)
        }
        
        return updateHighlight(newHighlight:newHighlight)
        
    }
    
    func addHighlight(highlight: HighlightData) -> Bool {
        do {
            if let highlightID = try HighlightDatabase.shared.highlights.insert(newHighlight: highlight) {
                highlight.id = highlightID
                self.reloadHighlights()
                return true
            }
            return false
        } catch {
            log(.error, error)
            return false
        }
    }
    
    func changeHighlight(highlight: HighlightData) -> Bool {
        do {
            if try HighlightDatabase.shared.highlights.update(newHighlight: highlight) {
                self.reloadHighlights()
                return true
            }
            return false
        } catch {
            log(.error, error)
            return false
        }
    }
    
    func removeHighlight(index: Int) -> Bool {
        if index < 0 || index >= highlights.count {
            return false
        }
        let highlight = highlights[index]
        guard let deleted =  try? HighlightDatabase.shared.highlights.delete(highlight:highlight) else {
            return false
        }
        
        if deleted {
            highlights.remove(at:index)
            return true
        }
        return false
    }
    
    func removeHighlight(highlight: HighlightData) -> Bool {
        guard (try? HighlightDatabase.shared.highlights.delete(highlight: highlight)) != nil else {
            return false
        }
        self.reloadHighlights()
        
        return true
    }
    
    /*
     func highlightActivated(index: Int, progress: Double) -> Bool {
     return false
     }
     */
}
