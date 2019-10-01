//
//  annotate.swift
//  r2-testapp-swift
//
//  Created by Taehyun on 24/06/2019.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import UIKit

class AnnotationViewController: UIViewController {
    public var selectionText = ""
    public var existingText = ""
    public var newAnnotation = ""
    public var id = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        annotation.text = existingText
        selectText.text = selectionText
        selectText.textContainer.maximumNumberOfLines = 3
        selectText.textContainer.lineBreakMode = .byTruncatingTail
        selectText.centerVertically()
    }
    
    @IBAction func OnDone(_ sender: Any) {
        newAnnotation = annotation.attributedText.string
        dismiss(animated: true, completion: nil)
        
        let notification = Notification.Name(rawValue: "annotated")
        let param:[String:String] = ["text":newAnnotation,"id":id]
        
        NotificationCenter.default.post(name: notification, object: self, userInfo:param)
        
    }
    @IBOutlet weak var annotation: UITextView!
    @IBOutlet weak var selectText: UITextView!
}

extension UITextView {
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}
