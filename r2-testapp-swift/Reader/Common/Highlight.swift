//
//  Highlight.swift
//  r2-testapp-swift
//
//  Created by Taehyun Kim on 06.06.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import UIKit
import R2Shared


public class HighlightData : Bookmark {
    
    public var annotation: String
    public var color: String
    public var style: String
    public var annotationMarkStyle: String
    public var selectionInfo: String
    public var highlightFrameID: String
    public var annotationID: String
    
    public init(id: Int64? = nil, publicationID: String = "", resourceIndex: Int = 0, locator: Locator, creationDate: Date = Date(), annotation: String = "", color:String = "", style:String = "", annotationMarkStyle:String = "", selectionInfo:String = "", highlightFrameID:String = "", annotationID: String = "") {
        
        self.annotation = annotation
        self.color = color
        self.style = style
        self.annotationMarkStyle = annotationMarkStyle
        self.selectionInfo = selectionInfo
        self.highlightFrameID = highlightFrameID
        self.annotationID = annotationID
        
        super.init(id: id,publicationID: publicationID,resourceIndex: resourceIndex,locator: locator,creationDate: creationDate)
    }
    
}
