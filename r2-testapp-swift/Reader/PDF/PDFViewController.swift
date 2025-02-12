//
//  PDFViewController.swift
//  r2-testapp-swift
//
//  Created by Mickaël Menu on 07.03.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import UIKit
import R2Navigator
import R2Shared


@available(iOS 11.0, *)
final class PDFViewController: ReaderViewController {
    
    init(publication: Publication, book: Book, drm: DRM?) {
        let navigator = PDFNavigatorViewController(publication: publication, license: drm?.license, initialLocation: book.progressionLocator)
        
        super.init(navigator: navigator, publication: publication, book: book, drm: drm)
        
        navigator.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

@available(iOS 11.0, *)
extension PDFViewController: PDFNavigatorDelegate {
}
