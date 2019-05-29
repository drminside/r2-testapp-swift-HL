//
//  CBZViewController.swift
//  r2-testapp-swift
//
//  Created by Alexandre Camilleri on 6/28/17.
//
//  Copyright 2018 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import UIKit
import R2Navigator
import R2Shared
import R2Streamer


class CBZViewController: ReaderViewController {

    init(publication: Publication, drm: DRM?) {
        let initialLocation = CBZViewController.initialLocation(for: publication)
        let navigator = CBZNavigatorViewController(publication: publication, initialLocation: initialLocation)
        
        super.init(navigator: navigator, publication: publication, drm: nil)
        
        navigator.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        addChild(navigator)
        navigator.view.frame = view.bounds
        navigator.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(navigator.view)
        navigator.didMove(toParent: self)
    }
    
    override var currentBookmark: Bookmark? {
        guard let publicationID = publication.metadata.identifier,
            let locator = navigator.currentLocation,
            let resourceIndex = publication.readingOrder.firstIndex(withHref: locator.href) else
        {
            return nil
        }
        
        return Bookmark(
            publicationID: publicationID,
            resourceIndex: resourceIndex,
            locator: locator
        )
    }

}

extension CBZViewController: CBZNavigatorDelegate {
}
