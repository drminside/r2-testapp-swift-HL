//
//  EPUBViewController.swift
//  r2-testapp-swift
//
//  Created by Alexandre Camilleri on 7/3/17.
//
//  Copyright 2018 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import UIKit
import R2Shared
import R2Navigator
import MenuItemKit

class EPUBViewController: ReaderViewController {
  
    var popoverUserconfigurationAnchor: UIBarButtonItem?
    var userSettingNavigationController: UserSettingsNavigationController

    init(publication: Publication, book: Book, drm: DRM?, resourcesServer: ResourcesServer) {
        let initialLocation = EPUBViewController.initialLocation(for: publication)
        let navigator = EPUBNavigatorViewController(publication: publication, license: drm?.license, initialLocation: book.progressionLocator, resourcesServer: resourcesServer)

        let settingsStoryboard = UIStoryboard(name: "UserSettings", bundle: nil)
        userSettingNavigationController = settingsStoryboard.instantiateViewController(withIdentifier: "UserSettingsNavigationController") as! UserSettingsNavigationController
        userSettingNavigationController.fontSelectionViewController =
            (settingsStoryboard.instantiateViewController(withIdentifier: "FontSelectionViewController") as! FontSelectionViewController)
        userSettingNavigationController.advancedSettingsViewController =
            (settingsStoryboard.instantiateViewController(withIdentifier: "AdvancedSettingsViewController") as! AdvancedSettingsViewController)
        
        super.init(navigator: navigator, publication: publication, book: book, drm: drm)
        
        navigator.delegate = self
    }
    
    var epubNavigator: EPUBNavigatorViewController {
        return navigator as! EPUBNavigatorViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
  
        setSelectionMenu()

        /// Set initial UI appearance.
        if let appearance = publication.userProperties.getProperty(reference: ReadiumCSSReference.appearance.rawValue) {
            setUIColor(for: appearance)
        }
        
        let userSettings = epubNavigator.userSettings
        userSettingNavigationController.userSettings = userSettings
        userSettingNavigationController.modalPresentationStyle = .popover
        userSettingNavigationController.usdelegate = self
        userSettingNavigationController.userSettingsTableViewController.publication = publication
        

        publication.userSettingsUIPresetUpdated = { [weak self] preset in
            guard let `self` = self, let presetScrollValue:Bool = preset?[.scroll] else {
                return
            }
            
            if let scroll = self.userSettingNavigationController.userSettings.userProperties.getProperty(reference: ReadiumCSSReference.scroll.rawValue) as? Switchable {
                if scroll.on != presetScrollValue {
                    self.userSettingNavigationController.scrollModeDidChange()
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        epubNavigator.userSettings.save()
    }

    override func makeNavigationBarButtons() -> [UIBarButtonItem] {
        var buttons = super.makeNavigationBarButtons()

        // User configuration button
        let userSettingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "settingsIcon"), style: .plain, target: self, action: #selector(presentUserSettings))
        buttons.insert(userSettingsButton, at: 1)
        popoverUserconfigurationAnchor = userSettingsButton

        return buttons
    }
    
    override var currentBookmark: Bookmark? {
        guard let publicationID = publication.metadata.identifier,
            let locator = navigator.currentLocation,
            let resourceIndex = publication.readingOrder.firstIndex(withHref: locator.href) else
        {
            return nil
        }
        return Bookmark(publicationID: publicationID, resourceIndex: resourceIndex, locator: locator)
    }
    
    override var currentSelection: HighlightData? {
        guard let publicationID = publication.metadata.identifier,
            let locator = navigator.currentLocation,
            let annotation: String = "",
            let color: String = "",
            let style: String = "",
            let annotationMarkStyle: String = "",
            let selectionInfo: String = "",
            let resourceIndex = publication.readingOrder.firstIndex(withHref: locator.href) else
        {
            return nil
        }
        return HighlightData(publicationID: publicationID, resourceIndex: resourceIndex, locator: locator,
                             annotation: annotation, color:color, style:style, annotationMarkStyle:annotationMarkStyle,
                             selectionInfo:selectionInfo)
    }

    
    @objc func presentUserSettings() {
        let popoverPresentationController = userSettingNavigationController.popoverPresentationController!
        
        popoverPresentationController.delegate = self
        popoverPresentationController.barButtonItem = popoverUserconfigurationAnchor

        userSettingNavigationController.publication = publication
        present(userSettingNavigationController, animated: true) {
            // Makes sure that the popover is dismissed also when tapping on one of the other UIBarButtonItems.
            // ie. http://karmeye.com/2014/11/20/ios8-popovers-and-passthroughviews/
            popoverPresentationController.passthroughViews = nil
        }
    }

    @objc func presentDrmManagement() {
        guard let drm = drm else {
            return
        }
        moduleDelegate?.presentDRM(drm, from: self)
    }
    
    
    @objc override func changeColorActivated(_ notification: NSNotification) {
        guard let selectionInfo = notification.userInfo?["selectionInfo"] as? String,
            let color = notification.userInfo?["color"] as? String,
            let id = notification.userInfo?["id"] as? String,
            let dataSource = highlightsDataSource,
            let highlight = currentSelection else
        {
            return
        }
        
        let annotationID = notification.userInfo?["annotationID"] as? String ?? ""
        highlight.selectionInfo = selectionInfo
        highlight.color = color
        highlight.highlightFrameID = id
        highlight.annotationID = dataSource.getHighlight(id)?.annotationID ?? ""
        
        guard dataSource.updateHighlight(newHighlight: highlight)! else
        {
            return
        }
        
    }
    
    @objc override func highlightActivated(_ notification: NSNotification) {
        guard let id = notification.userInfo?["id"] as? String else
        {
            return
        }
        epubNavigator.rectangleForHighlightWithID(id) { rect in
            UIMenuController.shared.menuItems?.removeAll()
            
            let highlightData = self.highlightsDataSource!.getHighlight(id)
            let highlight = Highlight(
                id: highlightData!.highlightFrameID,
                locator: highlightData!.locator,
                style: "",
                color: self.getUIColor(color: highlightData!.color)
            )
            
            let yellow = UIMenuItem(title: "yellow", image: UIImage(named: "yellow")) {_ in
                self.changeColorYellow(highlight)
            }
            let green = UIMenuItem(title: "green", image: UIImage(named: "green")) {_ in
                self.changeColorGreen(highlight)
            }
            let blue = UIMenuItem(title: "blue", image: UIImage(named: "blue")) {_ in
                self.changeColorBlue(highlight)
            }
            let red = UIMenuItem(title: "red", image: UIImage(named: "red")) {_ in
                self.changeColorRed(highlight)
            }
            let purple = UIMenuItem(title: "purple", image: UIImage(named: "purple")) {_ in
                self.changeColorPurple(highlight)
            }
            let memo = UIMenuItem(title: "memo", image: UIImage(named: "Pen")) {_ in
                self.createAnnotation(highlight)
            }
            let delete = UIMenuItem(title: "delete", image: UIImage(named: "Delete")) {_ in
                self.deleteHighlight(highlight)
            }
            
            UIMenuController.shared.menuItems = [yellow, green, blue, red, purple, memo, delete]
            
            var menuFrameRect = UIMenuController.shared.menuFrame
            menuFrameRect.origin.y = CGFloat((rect?.origin.y)!)
            let documentWebView = (self.epubNavigator.view)!
            UIMenuController.shared.setTargetRect(menuFrameRect, in: documentWebView)
            
            UIMenuController.shared.update()
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
        
    }
    
    func _annotationActivcated(_ notification: NSNotification, _ type: String) {
        
        
        guard  let id = notification.userInfo?["id"] as? String else {
            return
        }
        
        guard let positionInfo = notification.userInfo?["selectionInfo"] as? String,
            let json:[String:Any] = (self.makeJSON(positionInfo) as! [String : Any]) else {
                return
        }
        let cleanText = json["cleanText"] as? String
        
        if (type == "newAnnotationActivated") {
            if ( cleanText == nil ) {
                return
            }
            highlightActivated(notification)
        }
        
        let highlightId = id.replacingOccurrences(of:"ANNOTATION", with:"HIGHLIGHT")
        guard let highlight = highlightsDataSource!.getHighlight(highlightId) else {
            return
        }
        
        let annotationStoryboard = UIStoryboard(name: "Annotation", bundle: nil)
        
        let annotationView =  annotationStoryboard.instantiateViewController(withIdentifier: "annotationViewController") as! AnnotationViewController
        
        annotationView.id = highlightId
        if ( type == "newAnnotationActivated" || highlight.annotation == "") {
            annotationView.selectionText = cleanText!
            annotationView.existingText = cleanText!
        } else {
            annotationView.selectionText = cleanText!
            annotationView.existingText = highlight.annotation
            
        }
        
        self.present(annotationView, animated: true, completion: nil)
    }
    
    @objc override func changeAnnotationActivated(_ notification: NSNotification) {
        _annotationActivcated(notification,"changeAnnotationActivated")
    }
    
    
    @objc override func annotationActivated(_ notification: NSNotification) {
        guard  let id = notification.userInfo?["id"] as? String else {
            return
        }
        
        let highlightId = id.replacingOccurrences(of:"ANNOTATION", with:"HIGHLIGHT")
        let highlightData = highlightsDataSource!.getHighlight(highlightId)
        createAnnotation(
            Highlight(
                id: highlightData!.highlightFrameID,
                locator: highlightData!.locator,
                style: highlightData!.style,
                color: self.getUIColor(color: highlightData!.color)
            )
        )
    }
    
    @objc override func deleteHighlightActivated(_ notification: NSNotification) {
        guard let id = notification.userInfo?["id"] as? String else {
            return
        }
        
        let highlightId = id.replacingOccurrences(of:"ANNOTATION", with:"HIGHLIGHT")
        guard let highlight = highlightsDataSource!.getHighlight(highlightId) else {
            return
        }
        
        highlightsDataSource?.removeHighlight(highlight:highlight)
    }
    
    @objc override func annotated(_ notification: NSNotification) {
        guard let id = notification.userInfo?["id"] as? String, let text = notification.userInfo?["text"] as? String else {
            return
        }
        
        if !text.isEmpty {
            let highlightId = id.replacingOccurrences(of:"ANNOTATION", with:"HIGHLIGHT")
            let highlight = highlightsDataSource!.getHighlight(highlightId)
            
            if highlight != nil {
                highlight!.annotation = text
                highlight!.style = "annotated"
                
                guard highlightsDataSource!.updateHighlight(newHighlight: highlight!)! else
                {
                    return
                }
                
                epubNavigator.showAnnotation(id)
            }
            else {
                let color:NSDictionary = [
                    "red" : 150,
                    "green" : 150,
                    "blue"  : 150
                ]
                epubNavigator.createHighlight(color) { result in
                    guard let highlight = self.currentSelection else {
                        return
                    }
                    
                    highlight.color = self.convJSON(color)!
                    highlight.highlightFrameID = result.id
                    highlight.locator = result.locator
                    highlight.annotation = text
                    highlight.style = "annotated"
                    
                    guard self.highlightsDataSource!.addHighlight(highlight: highlight) else
                    {
                        return
                    }
                    
                    self.epubNavigator.showAnnotation(id)
                }
            }
        }
    }
    
    private func convJSON (_ dictionary: NSDictionary) -> String? {
        if let jsonData = try? JSONSerialization.data(
            withJSONObject: dictionary,
            options: .prettyPrinted) {
            let theJSONText = String(data:jsonData,encoding:.ascii)!
            return theJSONText
        }
        return nil
    }
    
    @objc override func defaultMenuActivated(_ notification: NSNotification) {
        //setSelectionMenu()
    }
    
    func setSelectionMenu() {
        let memuNotification = Notification.Name(rawValue: "defaultMenu")
        NotificationCenter.default.post(name: memuNotification, object: self, userInfo:nil)
        let highlight = UIMenuItem(title: "Highlight", action: #selector(highlightMenuTapped))

        let memo = UIMenuItem(title: "Memo", action: #selector(annotationMenuTapped))
        UIMenuController.shared.menuItems = [ highlight, memo ]
        UIMenuController.shared.update()
    }
    
    @objc func highlightMenuTapped() {
        let notification = Notification.Name(rawValue: "initMenuActivated")
        NotificationCenter.default.post(name: notification, object: self, userInfo:nil)
        
        UIMenuController.shared.menuItems?.removeAll()
        
        let yellow = UIMenuItem(title: "yellow", image: UIImage(named: "yellow")) {_ in
            self.changeColorYellow()
        }
        let green = UIMenuItem(title: "green", image: UIImage(named: "green")) {_ in
            self.changeColorGreen()
        }
        let blue = UIMenuItem(title: "blue", image: UIImage(named: "blue")) {_ in
            self.changeColorBlue()
        }
        let red = UIMenuItem(title: "red", image: UIImage(named: "red")) {_ in
            self.changeColorRed()
        }
        let purple = UIMenuItem(title: "purple", image: UIImage(named: "purple")) {_ in
            self.changeColorPurple()
        }
        
        
        UIMenuController.shared.menuItems = [yellow, green, blue, red, purple]
        
        var menuFrameRect = UIMenuController.shared.menuFrame
        menuFrameRect.origin.y += menuFrameRect.size.height
        let documentWebView = (epubNavigator.view)!
        UIMenuController.shared.setTargetRect(menuFrameRect, in: documentWebView)
        
        UIMenuController.shared.update()
        UIMenuController.shared.setMenuVisible(true, animated: true)
        
    }
    
    func createHighlight(_ highlight: Highlight? = nil, _ colorInfo:NSDictionary) {
        if (highlight == nil) {
            epubNavigator.createHighlight(colorInfo) { result in
                guard let highlight = self.currentSelection,
                    let dataSource = self.highlightsDataSource else {
                        return
                }
                
                
                highlight.color = self.convJSON(colorInfo)!
                highlight.highlightFrameID = result.id
                highlight.locator = result.locator
                
                guard dataSource.addHighlight(highlight: highlight) else
                {
                    return
                }
            }
        }
        else {
            guard let highlightData = highlightsDataSource!.getHighlight(highlight!.id) else {
                return
            }
            
            highlightData.color = self.convJSON(colorInfo)!
            
            guard highlightsDataSource!.updateHighlight(newHighlight: highlightData)! else
            {
                return
            }
            
            epubNavigator.showHighlight(
                Highlight(
                    id: highlightData.highlightFrameID,
                    locator: highlightData.locator,
                    style: highlightData.style,
                    color: self.getUIColor(color: highlightData.color)
                )
            )
        }
    }
    
    func changeColor(_ highlight: Highlight? = nil, _ color: NSDictionary) {
        createHighlight(highlight, color)
        UIMenuController.shared.menuItems?.removeAll()
        setSelectionMenu()
    }
    
    func changeColorRed(_ highlight: Highlight? = nil) {
        
        print("Selected Red?-R")
        
        let color:NSDictionary = [
            "red" : 247,
            "green" : 124,
            "blue"  : 124
        ]
        
        changeColor(highlight, color)
    }
    
    func changeColorBlue(_ highlight: Highlight? = nil) {
        
        print("Selected Blue?")
        
        let color:NSDictionary = [
            "red" : 124,
            "green" : 198,
            "blue"  : 247
        ]
        
        changeColor(highlight, color)
    }
    
    func changeColorGreen(_ highlight: Highlight? = nil) {
        
        print("Selected Green?")
        
        let color:NSDictionary = [
            "red" : 173,
            "green" : 247,
            "blue"  : 123
        ]
        
        changeColor(highlight, color)
    }
    
    func changeColorYellow(_ highlight: Highlight? = nil) {
        
        print("Selected Yellow?")
        
        let color:NSDictionary = [
            "red" : 249,
            "green" : 239,
            "blue"  : 125
        ]
        
        changeColor(highlight, color)
    }
    
    func changeColorPurple(_ highlight: Highlight? = nil) {
        
        print("Selected Purple?")
        
        let color:NSDictionary = [
            "red" : 182,
            "green" : 153,
            "blue"  : 255
        ]
        
        changeColor(highlight, color)
    }
    
    @objc func annotationMenuTapped() {
        let annotationStoryboard = UIStoryboard(name: "Annotation", bundle: nil)
    
        let annotationView =  annotationStoryboard.instantiateViewController(withIdentifier: "annotationViewController") as! AnnotationViewController
    
        epubNavigator.currentSelection { locator in
            annotationView.selectionText = locator!.text.highlight!
            self.present(annotationView, animated: true, completion: nil)
        }
        setSelectionMenu()
    }
    
    func createAnnotation(_ highlight: Highlight? = nil) {
        let annotationStoryboard = UIStoryboard(name: "Annotation", bundle: nil)
        
        let annotationView =  annotationStoryboard.instantiateViewController(withIdentifier: "annotationViewController") as! AnnotationViewController
        
        if highlight != nil {
            annotationView.id = highlight!.id
            annotationView.existingText = highlightsDataSource?.getHighlight(highlight!.id)?.annotation ?? ""
            annotationView.selectionText = highlight!.locator.text.highlight!
            self.present(annotationView, animated: true, completion: nil)
        }
        else {
            epubNavigator.currentSelection { locator in
                annotationView.selectionText = locator!.text.highlight!
                self.present(annotationView, animated: true, completion: nil)
            }
        }
        setSelectionMenu()
    }
    
    func deleteHighlight(_ highlight: Highlight? = nil) {
        guard let highlightData = highlightsDataSource!.getHighlight(highlight!.id) else {
            return
        }
        
        epubNavigator.deleteHighlight(highlight!.id)
        
        guard highlightsDataSource!.removeHighlight(highlight: highlightData) else
        {
            return
        }
        
        setSelectionMenu()
    }
    
    @objc override func pageLoaded(_ notification: NSNotification) {
        /*
         guard let resourceHref = notification.userInfo?["resourceHref"] as? URL else {
         return
         }
         */
        let url = navigator.currentLocation?.href
        guard let list = highlightsDataSource!.getHighlights(url)
            //highlightsDataSource!.getHighlights()
            else {
                return
        }
        
        for (index, element) in list.enumerated() {
            let highlightData = element as HighlightData
            let selectionInfo = highlightData.selectionInfo
            var color = highlightData.color as String
            //let highlight:Highlight
            
            epubNavigator.showHighlight(
                Highlight(
                    id: highlightData.highlightFrameID,
                    locator: highlightData.locator,
                    style: highlightData.style,
                    color: getUIColor(color: color)
                )
            )
        }
        //navigator.
        return
        
        
    }
    
    @objc private func getUIColor(color:String) -> UIColor {
        guard let json:[String:Any] = (makeJSON(color) as! [String : Any]) else {
            return UIColor(red:100.0, green:100.0, blue:100.0, alpha:1.0)
        }
        
        let uiColor:UIColor = UIColor(red:json["red"] as! CGFloat,green:json["green"] as! CGFloat ,blue:json["blue"] as! CGFloat ,alpha:1.0)
        
        return uiColor
    }
    
    private func makeJSON(_ source:String) -> Any {
        let data = Data(source.utf8)
        
        do {
            if let json = try JSONSerialization.jsonObject (with:data, options: []) as? [String: Any] {
                return json
            }
        }
        catch let error as NSError {
            print("Failed to conversion: \(error.localizedDescription)")
        }
        
        return Optional<Any>.none
    }

}

extension EPUBViewController: EPUBNavigatorDelegate {
    
}

extension EPUBViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension EPUBViewController: UserSettingsNavigationControllerDelegate {

    internal func getUserSettings() -> UserSettings {
        return epubNavigator.userSettings
    }
    
    internal func updateUserSettingsStyle() {
        DispatchQueue.main.async {
            self.epubNavigator.updateUserSettingStyle()
        }
    }
    
    /// Synchronyze the UI appearance to the UserSettings.Appearance.
    ///
    /// - Parameter appearance: The appearance.
    internal func setUIColor(for appearance: UserProperty) {
        let colors = AssociatedColors.getColors(for: appearance)
        
        navigator.view.backgroundColor = colors.mainColor
        view.backgroundColor = colors.mainColor
        //
        navigationController?.navigationBar.barTintColor = colors.mainColor
        navigationController?.navigationBar.tintColor = colors.textColor
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: colors.textColor]
    }
    
}

extension EPUBViewController: UIPopoverPresentationControllerDelegate {
    // Prevent the popOver to be presented fullscreen on iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return .none
    }
}
