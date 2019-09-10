//
//  NetworkManager.swift
//  TestApp
//
//  Created by Fry an Egg on 5/29/19.
//  Copyright © 2019 Fry an Egg. All rights reserved.
//

import UIKit

class NetworkManager: NSObject {

    func loadFeed() {
        
        let url = URL(string: "https://raw.githubusercontent.com/phunware-services/dev-interview-homework/master/feed.json")!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error = error {
                print("loadFeed URLSession error")
                print(error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue:"NETWORK_ERROR_NOTIFICATION"), object: nil, userInfo: nil)
                    }
                    return
            }
            
            do {
                if (data == nil) {return}
                
                // save bulletins in user prefences
                UserDefaults.standard.set(data, forKey: "Bulletins")
                UserDefaults.standard.synchronize()
                
                let responseObject = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue:"FEED_LOADED_NOTIFICATION"), object: responseObject, userInfo: nil)
                }
            }
            catch {
                print("JSONSerialization failed")
            }
        }
        task.resume()
    }
    
    
    func loadImage(bulletin:[String:Any]) {
        
        guard let urlString = bulletin["image"] as? String else {return}
        guard let url = URL(string: urlString) else {return}
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
           if let error = error {
                print("loadImage URLSession error")
                print(error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {

                    print(httpResponse)
                    // embedded 404 error comes here, to send error notifcation, uncomment:
                    //DispatchQueue.main.async {
                    //    NotificationCenter.default.post(name: NSNotification.Name(rawValue:"NETWORK_ERROR_NOTIFICATION"), object: NSNumber(value: httpResponse.statusCode), userInfo: nil)
                    //}
                    return
            }
            
            if (data == nil) {return}
            
            // save image data to defaults
            UserDefaults.standard.set(data, forKey: urlString)
            UserDefaults.standard.synchronize()
            
            // create and filter image as required
            guard let uiimage = UIImage.init(data: data!) else {return}
            let filterdImage = self.filterImage(image:uiimage)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:"IMAGE_UPDATE_NOTIFICATION"), object:filterdImage, userInfo: bulletin)
            }
        }
        task.resume()
        
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
