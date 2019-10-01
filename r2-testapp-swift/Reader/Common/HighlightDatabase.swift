//
//  HighlightDatabase.swift
//  r2-testapp-swift
//
//  Created by Senda Li on 2018/7/20.
//
//  Copyright 2018 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import SQLite
import UIKit
import R2Shared

final class HighlightDatabase {
    // Shared instance.
    public static let shared = HighlightDatabase()
    
    // Connection.
    let connection: Connection
    // The DB table for bookmark.
    let highlights: HighlightsTable!
    
    private init() {
        do {
            var url = try FileManager.default.url(for: .libraryDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil, create: true)
            
            url.appendPathComponent("hightlights_database")
            connection = try Connection(url.absoluteString)
            highlights = HighlightsTable(connection)
            
            
        } catch {
            fatalError("Error initializing db.")
        }
    }
}

class HighlightsTable : BookmarksTable {
    
    let highlightID = Expression<Int64>("id")
    let highlightFrameID = Expression<String>("frameId")
    let annotation = Expression<String>("annotation")
    let color = Expression<String>("color")
    let style = Expression<String>("style")
    let annotationMarkStyle = Expression<String>("annotationMarkStyle")
    let selectionInfo = Expression<String>("selectionInfo")
    
    override init(_ connection: Connection) {
        //      connection.userVersion = 0
        
        super.init(connection)
        super.tableName = Table("HIGHLIGHTS")
        if connection.userVersion == 0 {
            // handle first migration
            connection.userVersion = 1
            // upgrade database columns
            // drop table and recreate, this will delete all prior bookmarks
            _ = try? connection.run(tableName.drop())
        }
        
        _ = try? connection.run(tableName.create(temporary: false, ifNotExists: true) { t in
            //t.column(bookmarkID, primaryKey: PrimaryKey.autoincrement)
            t.column(highlightID, primaryKey: PrimaryKey.autoincrement)
            t.column(creationDate)
            t.column(publicationID)
            t.column(highlightFrameID)
            t.column(resourceHref)
            t.column(resourceIndex)
            t.column(resourceType)
            t.column(locations)
            t.column(locatorText)
            t.column(resourceTitle)
            t.column(annotation)
            t.column(color)
            t.column(style)
            t.column(annotationMarkStyle)
            t.column(selectionInfo)
        })
    }
    
    func insert(newHighlight: HighlightData) throws -> Int64? {
        let db = HighlightDatabase.shared.connection
        
        let highlight = tableName.filter(self.publicationID == newHighlight.publicationID && self.resourceHref == newHighlight.locator.href && self.resourceIndex == newHighlight.resourceIndex && self.locations == (newHighlight.locator.locations.jsonString ?? "") && self.selectionInfo == newHighlight.selectionInfo &&
            self.highlightFrameID == newHighlight.highlightFrameID )
        
        // Check if empty.
        guard try db.count(highlight) == 0 else {
            return nil
        }
        
        let insertQuery = tableName.insert(
            creationDate <- newHighlight.creationDate,
            publicationID <- newHighlight.publicationID,
            resourceHref <- newHighlight.locator.href,
            resourceIndex <- newHighlight.resourceIndex,
            resourceType <- newHighlight.locator.type,
            locations <- newHighlight.locator.locations.jsonString ?? "",
            locatorText <- newHighlight.locator.text.jsonString ?? "",
            resourceTitle <- newHighlight.locator.title ?? "",
            annotation <- newHighlight.annotation ?? "",
            color <- newHighlight.color ?? "",
            style <- newHighlight.style ?? "",
            annotationMarkStyle <- newHighlight.annotationMarkStyle ?? "",
            selectionInfo <- newHighlight.selectionInfo ?? "",
            highlightFrameID <- newHighlight.highlightFrameID
        )
        
        return try db.run(insertQuery)
    }
    
    func delete(highlight: HighlightData) throws -> Bool {
        return try delete(highlightID: highlight.id!)
    }
    
    func delete(highlightID: Int64) throws -> Bool {
        let db = HighlightDatabase.shared.connection
        let highlight = tableName.filter(self.highlightID == highlightID)
        
        // Check if empty.
        guard try db.count(highlight) > 0 else {
            return false
        }
        
        try db.run(highlight.delete())
        return true
    }
    
    func update(newHighlight: HighlightData) throws -> Bool {
        let db = HighlightDatabase.shared.connection
        
        let highlight = tableName.filter(self.highlightFrameID == newHighlight.highlightFrameID)
        
        try print(db.count(highlight));
        // Check if empty.
        guard try db.count(highlight) != 0 else {
            return false
        }
        
        let updateQuery = highlight.update(
            annotation <- newHighlight.annotation ?? "",
            color <- newHighlight.color ?? "",
            style <- newHighlight.style ?? ""
        )
        
        guard try db.run(updateQuery) == 1 else {
            return false
        }
        return true
    }
    
    
    func highlightList(for publicationID:String?=nil, resourceIndex:Int?=nil) throws -> [HighlightData]? {
        
        let db = HighlightDatabase.shared.connection
        // Check if empty.
        guard try db.count(tableName) > 0 else {
            return nil
        }
        
        let resultList = try { () -> AnySequence<Row> in
            if let fetchingID = publicationID {
                if let fetchingIndex = resourceIndex {
                    let query = self.tableName.filter(self.publicationID == fetchingID && self.resourceIndex == fetchingIndex)
                    return try db.prepare(query)
                }
                let query = self.tableName.filter(self.publicationID == fetchingID)
                return try db.prepare(query)
            }
            return try db.prepare(self.tableName)
            } ()
        
        return resultList.map { row in
            HighlightData(
                id: row[self.highlightID],
                publicationID: row[self.publicationID],
                resourceIndex: row[self.resourceIndex],
                locator: Locator(
                    href: row[self.resourceHref],
                    type: row[self.resourceType],
                    title: row[self.resourceTitle],
                    locations: Locations(jsonString: row[self.locations]),
                    text: LocatorText(jsonString: row[self.locatorText])
                ),
                creationDate: row[self.creationDate],
                annotation: row[self.annotation],
                color: row[self.color],
                style: row[self.style],
                annotationMarkStyle: row[self.annotationMarkStyle],
                selectionInfo: row[self.selectionInfo],
                highlightFrameID: row[self.highlightFrameID]
            )
        }
    }
    
    func highlightList(doc publicationID:String?=nil, resource resourceHref:String?=nil) throws -> [HighlightData]? {
        
        let db = HighlightDatabase.shared.connection
        // Check if empty.
        guard try db.count(tableName) > 0 else {
            return nil
        }
        
        let resultList = try { () -> AnySequence<Row> in
            guard let fetchingID = publicationID, let fetchingHref = resourceHref else {
                return try db.prepare(self.tableName)
            }
            let query = self.tableName.filter(self.publicationID == fetchingID && self.resourceHref == fetchingHref)
            return try db.prepare(query)
            } ()
        
        return resultList.map { row in
            HighlightData(
                id: row[self.highlightID],
                publicationID: row[self.publicationID],
                resourceIndex: row[self.resourceIndex],
                locator: Locator(
                    href: row[self.resourceHref],
                    type: row[self.resourceType],
                    title: row[self.resourceTitle],
                    locations: Locations(jsonString: row[self.locations]),
                    text: LocatorText(jsonString: row[self.locatorText])
                ),
                creationDate: row[self.creationDate],
                annotation: row[self.annotation],
                color: row[self.color],
                style: row[self.style],
                annotationMarkStyle: row[self.annotationMarkStyle],
                selectionInfo: row[self.selectionInfo],
                highlightFrameID: row[self.highlightFrameID]
            )
        }
    }
    
    func highlight(_ id:String) throws -> HighlightData? {
        
        let db = HighlightDatabase.shared.connection
        // Check if empty.
        guard try db.count(tableName) > 0 else {
            return nil
        }
        
        let query = self.tableName.filter(self.highlightFrameID == id)
        for row in try db.prepare(query) {
            return HighlightData(
                id: row[self.highlightID],
                publicationID: row[self.publicationID],
                resourceIndex: row[self.resourceIndex],
                locator: Locator(
                    href: row[self.resourceHref],
                    type: row[self.resourceType],
                    title: row[self.resourceTitle],
                    locations: Locations(jsonString: row[self.locations]),
                    text: LocatorText(jsonString: row[self.locatorText])
                ),
                creationDate: row[self.creationDate],
                annotation: row[self.annotation],
                color: row[self.color],
                style: row[self.style],
                annotationMarkStyle: row[self.annotationMarkStyle],
                selectionInfo: row[self.selectionInfo],
                highlightFrameID: row[self.highlightFrameID]
            )
        }
        
        return nil
    }
}
