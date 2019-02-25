//
//  LCPLibraryService.swift
//  r2-testapp-swift
//
//  Created by Mickaël Menu on 01.02.19.
//
//  Copyright 2019 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

#if LCP

import Foundation
import SafariServices
import UIKit
import R2Shared
import ReadiumLCP


final class LCPLibraryService: NSObject {
    
    private var lcpService: LCPService!
    private var interactionsCallbacks: [Int: () -> Void] = [:]
    
    override init() {
        super.init()
        lcpService = R2MakeLCPService(interactionDelegate: self)
    }
    
    func importPublication(from url: URL, completion: @escaping ((URL, URLSessionDownloadTask?)?, Error?) -> Void) {
        lcpService.importPublication(from: url, authentication: self) { publication, error in
            if case LCPError.cancelled? = error {
                completion(nil, nil)
                return
            }
            guard let publication = publication else {
                completion(nil, error)
                return
            }
            completion((publication.localUrl, publication.downloadTask), nil)
        }
    }
    
    func retrieveLicense(at path: String, completion: @escaping (DRMLicense?, Error?) -> Void) {
        guard let url = URL(string: path) else {
            completion(nil, nil)
            return
        }
        
        lcpService.retrieveLicense(from: url, authentication: self) { license, error in
            if case LCPError.cancelled? = error {
                completion(nil, nil)
                return
            }
            completion(license, error)
        }
    }

}

extension LCPLibraryService: LCPAuthenticating {
    
    func requestPassphrase(for license: LCPAuthenticatedLicense, reason: LCPAuthenticationReason, completion: @escaping (String?) -> Void) {
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            completion(nil)
            return
        }
        
        let title: String
        switch reason {
        case .passphraseNotFound:
            title = "LCP Passphrase"
        case .invalidPassphrase:
            title = "The passphrase is incorrect"
        }
        
        let alert = UIAlertController(title: title, message: license.hint, preferredStyle: .alert)
        let dismissButton = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(nil)
        }
        let confirmButton = UIAlertAction(title: "Submit", style: .default) { _ in
            let passphrase = alert.textFields?[0].text
            completion(passphrase ?? "")
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Passphrase"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(dismissButton)
        alert.addAction(confirmButton)
        viewController.present(alert, animated: true)
    }
    
}

extension LCPLibraryService: LCPInteractionDelegate {
    
    func presentLCPInteraction(at url: URL, dismissed: @escaping () -> Void) {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else {
            dismissed()
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        safariVC.modalPresentationStyle = .formSheet
        
        interactionsCallbacks[safariVC.hash] = dismissed
        rootViewController.present(safariVC, animated: true)
    }
    
}

extension LCPLibraryService: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        let dismissed = interactionsCallbacks.removeValue(forKey: controller.hash)
        dismissed?()
    }
    
}

#endif
