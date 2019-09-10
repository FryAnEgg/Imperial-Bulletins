//
//  BulletinDetail_TableViewController.swift
//  TestApp
//
//  Created by Fry an Egg on 6/1/19.
//  Copyright © 2019 Fry an Egg. All rights reserved.
//

import UIKit

class BulletinDetail_TableViewController: UITableViewController {

    var bulletin = [String:Any]()
    var image = UIImage()
    var bresize = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! BulletinDetail_TableViewCell

        cell.bulletinImageView.image = image
        
        let title = bulletin["title"] as! String
        let description = (bulletin["description"] ?? "") as! String
        
        let dateString = bulletin["date"] as! String
        let dateStr = self.formatDateString(dateString:dateString)
        
        cell.titleLabel.text = title
        cell.dateLabel.text = dateStr
        cell.descriptionField.text = description

        self.navigationItem.title = title
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let description = (bulletin["description"] ?? "") as! String
        
        let textSize = CGSize(width: tableView.frame.size.width - 40.0, height: 3000)
        let font = UIFont.systemFont(ofSize: 15) // must agree with font size in storyboard
        let attributedString = NSAttributedString(string: description, attributes: [NSAttributedString.Key.font : font])
        
        let rect = attributedString.boundingRect(with: textSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        return 374.0 + rect.height + 100.0
        
    }
    
    func formatDateString(dateString:String) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "us")
        let date = formatter.date(from: dateString)
        
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.short
        let dateStr = formatter.string(from: date ?? Date())
        return dateStr
    }
    
    @IBAction func shareSheet(sender:AnyObject) {
        
        let activityViewController = UIActivityViewController(
            activityItems:[bulletin, image], applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityViewController, animated: true, completion: nil)
        
    }
}
