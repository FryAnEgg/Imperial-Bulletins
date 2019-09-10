//
//  Bulletins_CollectionViewController.swift
//  TestApp
//
//  Created by Fry an Egg on 5/29/19.
//  Copyright © 2019 Fry an Egg. All rights reserved.
//

import UIKit

private let reuseIdentifier = "BulletinCell"

class Bulletins_CollectionViewController: UICollectionViewController  {

    var bulletins = [[String:Any]] ()
    var images = [NSNumber:UIImage]()
    var selectedIndexPath = IndexPath()
    
    // MARK: View Controller
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(Bulletins_CollectionViewController.imageUpdated(_:) ), name: NSNotification.Name(rawValue:"IMAGE_UPDATE_NOTIFICATION"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Bulletins_CollectionViewController.feedLoaded(_:) ), name: NSNotification.Name(rawValue:"FEED_LOADED_NOTIFICATION"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Bulletins_CollectionViewController.networkError(_:) ), name: NSNotification.Name(rawValue:"NETWORK_ERROR_NOTIFICATION"), object: nil)
        
        guard let bulletinData = UserDefaults.standard.value(forKey: "Bulletins") as? Data else {
            let ad = UIApplication.shared.delegate as? AppDelegate
            ad?.network.loadFeed()
            return
        }
        
        do {
            let responseObject = try JSONSerialization.jsonObject(with: bulletinData, options: JSONSerialization.ReadingOptions.allowFragments)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:"FEED_LOADED_NOTIFICATION"), object: responseObject, userInfo: nil)
            }
        }
        catch {
            print ("JSON failed")
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let layout = self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = self.cellSizeForView(view:view)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
    }
    
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .all
    }
    
    // MARK: Utility functions
    
    func cellSizeForView(view:UIView) -> CGSize {
        
        // set up the cell size based on model and orientation
        // ipad is 2 cells across, iphone is 1
        var cellWidth : CGFloat = view.frame.size.width / 2.0
        var cellheight : CGFloat = view.frame.size.height / 4.0
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone) {
            cellWidth = view.frame.size.width
            cellheight = view.frame.size.height / 2.5
        }
        return CGSize(width: cellWidth , height:cellheight)
    }
    
    
    func formatDateString(dateString:String) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "us")
        guard let date = formatter.date(from: dateString) else {return ""}
        
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.short
        let dateStr = formatter.string(from: date)
        return dateStr
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "BulletinDetailSegue") {
            let detailController = segue.destination as! BulletinDetail_TableViewController
            
            let bulletin = bulletins[selectedIndexPath.row]
            detailController.bulletin = bulletin
            
            let bid = bulletin["id"] as! NSNumber
            
            let image = images[bid]
            detailController.image = image ?? UIImage()
        }
    }
    

    // MARK: UICollectionViewDataSource and delegate

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bulletins.count
    }

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! Bulletins_CollectionViewCell
    
        let bulletin = bulletins[indexPath.row]
        
        let bid = (bulletin["id"] ?? NSNumber(-1)) as? NSNumber
        var description = bulletin["description"] as? String
        if (description==nil) {description=""}
        let title = bulletin["title"] as? String
        
        let dateString = (bulletin["date"] ?? "") as? String
        let dateStr = self.formatDateString(dateString:dateString!)
        
        var location = bulletin["locationline1"] as? String
        if (location == nil) {
            location = ""
        } else {
            location! += ", "
        }
        if let location2 = bulletin["locationline2"] {
            location! += location2 as! String
        }
        
        let uiimage = images[bid!]
        
        // Configure the cell
        cell.dateLabel.text = dateStr
        cell.titleLabel.text = title
        cell.locationLabel.text = location
        cell.bulletinImageView.image = uiimage
        cell.descriptionField.text = description
    
        cell.descriptionField.textContainer.maximumNumberOfLines = 8
        cell.descriptionField.textContainer.lineBreakMode = .byTruncatingTail
        
        return cell
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedIndexPath = indexPath
        
        performSegue(withIdentifier: "BulletinDetailSegue", sender: self)
        
    }
   
    
    // MARK: Notifications
    // These are always called on main thread
    
    @objc func imageUpdated(_ notification:NSNotification){
        
        guard let filterdImage = notification.object as? UIImage else {return}
        
        // set image in images dictionary
        guard let bulletin = notification.userInfo as? [String:Any] else {return}
        guard let bid = bulletin["id"] as? NSNumber else {return}
        images[bid] = filterdImage
        
        //UserDefaults.standard.set(filterdImage, forKey: bulletin[""])
        
        // find which cell contains this bulletin and reload it
        for (index, listBull) in  bulletins.enumerated() {
            let lbid = listBull["id"] as! NSNumber
            if (lbid.intValue == bid.intValue) {
                let ip = IndexPath(row: index, section: 0)
                self.collectionView.reloadItems(at:[ip])
                return // images - bulletins are 1 to 1 for now
            }
        }
    }
    
    @objc func feedLoaded(_ notification:NSNotification){
        
        bulletins = notification.object as! Array
        
        self.collectionView.reloadData()
        
        // kick off image requests
        let ad = UIApplication.shared.delegate as? AppDelegate
        for bulletin in bulletins {
            // check if image has loaded already
            guard let urlString = bulletin["image"] as? String else {continue}
            if let imageData = UserDefaults.standard.value(forKey: urlString) as? Data {
                // create and filter image as required
                guard let uiimage = UIImage.init(data: imageData) else { continue }
                let filterdImage = self.filterImage(image:uiimage)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue:"IMAGE_UPDATE_NOTIFICATION"), object:filterdImage, userInfo: bulletin)
                }
            } else {
                ad?.network.loadImage(bulletin: bulletin)
            }
        }
    }
    
    @objc func networkError(_ notification:NSNotification){
     
        guard let statusCode = notification.object as? NSNumber else {return}
        
        let errorString = String(format:"%d",statusCode.intValue )
        let alert = UIAlertController(title: "ALERT!!!", message: errorString, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
            
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    // MARK - Utility
    func filterImage(image:UIImage) -> UIImage {
        
        let ci = CIImage(image: image)
        
        let colorfilter = CIFilter(name: "CIColorControls")
        
        colorfilter!.setValue(ci, forKey: kCIInputImageKey)
        colorfilter!.setValue(NSNumber(value: 0.3), forKey: "inputBrightness")
        colorfilter!.setValue(NSNumber(value: 0.5), forKey: "inputContrast")
        colorfilter!.setValue(NSNumber(value: 0.0), forKey: "inputSaturation")
        
        let CIout = colorfilter!.outputImage
        
        let context = CIContext()
        let filteredCGImageRef = context.createCGImage(
            CIout!,
            from: CIout!.extent
        )
        
        let returnImage = UIImage(cgImage: filteredCGImageRef!)
        return returnImage
    }
}
