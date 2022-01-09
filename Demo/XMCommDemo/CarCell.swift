//
//  CarCell.swift
//  XMCommDemo
//
//  Created by Ferdinand Urban on 11.10.2021.
//

import UIKit
import XMComm

class CarCell: UITableViewCell {

  @IBOutlet weak var carName: UILabel!
  @IBOutlet weak var regNumber: UILabel!
  
  // MARK: - UI Setup
  override func prepareForReuse() {
    super.prepareForReuse()
  }
  
  var content: Car? = nil {
    didSet {
      setupTitle(content?.fullModelName ?? "nevim jake auto")
      setupSubtitle(content?.registrationNumber ?? "no registr. number")
    }
  }
  
  private func setupTitle(_ title: String) {
    let attributes = [NSAttributedString.Key.foregroundColor: UIColor.black,
                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20.0, weight: .medium)]
    
    let attrS = NSAttributedString(string: title, attributes: attributes)
    carName.attributedText = attrS
    carName.adjustsFontSizeToFitWidth = true
  }
  
  private func setupSubtitle(_ title: String) {
    let attributes = [NSAttributedString.Key.foregroundColor: UIColor.black,
                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.0, weight: .regular)]
    
    let attrS = NSAttributedString(string: title, attributes: attributes)
    regNumber.attributedText = attrS
    regNumber.adjustsFontSizeToFitWidth = true
  }
}
