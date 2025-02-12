//
//  OPDSPublicationTableViewCell.swift
//  r2-testapp-swift
//
//  Created by Geoffrey Bugniot on 23/04/2018.
//
//  Copyright 2018 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import UIKit
import R2Shared
import Kingfisher

class OPDSPublicationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var feed: Feed?
    weak var opdsRootTableViewController: OPDSRootTableViewController?
    
    enum GeneralScreenOrientation: String {
        case landscape
        case portrait
    }
    
    static let iPadLayoutNumberPerRow:[GeneralScreenOrientation: Int] = [.portrait: 4, .landscape: 5]
    static let iPhoneLayoutNumberPerRow:[GeneralScreenOrientation: Int] = [.portrait: 3, .landscape: 4]
    
    lazy var layoutNumberPerRow:[UIUserInterfaceIdiom:[GeneralScreenOrientation: Int]] = [
        .pad : OPDSPublicationTableViewCell.iPadLayoutNumberPerRow,
        .phone : OPDSPublicationTableViewCell.iPhoneLayoutNumberPerRow
    ]
    
    fileprivate var previousScreenOrientation: GeneralScreenOrientation?

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(UINib(nibName: "PublicationCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "publicationCollectionViewCell")

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

}

extension OPDSPublicationTableViewCell: UICollectionViewDataSource {
    
    // MARK: - Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feed?.publications.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "publicationCollectionViewCell",
                                                      for: indexPath) as! PublicationCollectionViewCell
      
        cell.isAccessibilityElement = true
        cell.accessibilityHint = NSLocalizedString("opds_show_detail_view_a11y_hint", comment: "Accessibility hint for OPDS publication cell")
      
        if let publications = feed?.publications, let publication = feed?.publications[indexPath.row] {
            
            cell.accessibilityLabel = publication.metadata.title
            
            let titleTextView = OPDSPlaceholderListView(
                frame: cell.frame,
                title: publication.metadata.title,
                author: publication.metadata.authors
                    .map { $0.name }
                    .joined(separator: ", ")
            )

            var coverURL: URL?
            if publication.coverLink != nil {
                coverURL = publication.url(to: publication.coverLink)
            } else if publication.images.count > 0 {
                coverURL = URL(string: publication.images[0].href)
            }
            
            if let coverURL = coverURL {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                cell.coverImageView.kf.setImage(with: coverURL,
                                           placeholder: titleTextView,
                                           options: [.transition(ImageTransition.fade(0.5))],
                                           progressBlock: nil) { (_, _, _, _) in
                                            DispatchQueue.main.async {
                                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            }
                }
            } else {
                cell.coverImageView.addSubview(titleTextView)
            }
            
            cell.titleLabel.text = publication.metadata.title
            cell.authorLabel.text = publication.metadata.authors
                .map { $0.name }
                .joined(separator: ", ")
            
            if indexPath.row == publications.count - 3 {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                opdsRootTableViewController?.loadNextPage(completionHandler: { (feed) in
                    self.feed = feed
                    collectionView.reloadData()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                })
            }
            
        }
        
        return cell
    }
    
}

extension OPDSPublicationTableViewCell: UICollectionViewDelegateFlowLayout {
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let idiom = { () -> UIUserInterfaceIdiom in
            let tempIdion = UIDevice.current.userInterfaceIdiom
            return (tempIdion != .pad) ? .phone:.pad // ignnore carplay and others
        } ()
        
        let orientation = { () -> GeneralScreenOrientation in
            let deviceOrientation = UIDevice.current.orientation
            
            switch deviceOrientation {
            case .unknown, .portrait, .portraitUpsideDown:
                return GeneralScreenOrientation.portrait
            case .landscapeLeft, .landscapeRight:
                return GeneralScreenOrientation.landscape
            case .faceUp, .faceDown:
                return previousScreenOrientation ?? .portrait
            }
        } ()
        
        previousScreenOrientation = orientation

        guard let deviceLayoutNumberPerRow = layoutNumberPerRow[idiom] else {return CGSize(width: 0, height: 0)}
        guard let numberPerRow = deviceLayoutNumberPerRow[orientation] else {return CGSize(width: 0, height: 0)}
        
        let minimumSpacing: CGFloat = 5.0
        let labelHeight: CGFloat = 50.0
        let coverRatio: CGFloat = 1.5
        
        let itemWidth = (collectionView.frame.width / CGFloat(numberPerRow)) - (CGFloat(minimumSpacing) * CGFloat(numberPerRow)) - minimumSpacing
        let itemHeight = (itemWidth * coverRatio) + labelHeight

        return CGSize(width: itemWidth, height: itemHeight)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let publication = feed?.publications[indexPath.row] {
            let opdsPublicationInfoViewController: OPDSPublicationInfoViewController = OPDSFactory.shared.make(publication: publication)
            opdsRootTableViewController?.navigationController?.pushViewController(opdsPublicationInfoViewController, animated: true)
        }
    }
    
}
