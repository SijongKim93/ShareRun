//
//  SettingsViewController.swift
//  ShareRun
//
//  Created by 김시종 on 8/26/24.
//

import UIKit

class SettingsViewController: UIViewController {

    private let profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.layer.cornerRadius = imageView.frame.width / 2
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let profileName: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 20, weight: .semibold, textColor: .black, textAlignment: .left, title: "사용자 이름")
    }()
    
    private let profileEmail: UILabel = {
        return LabelFactory.createRunningLabel(fontSize: 20, weight: .semibold, textColor: .black, textAlignment: .left, title: "abc123@abc.abc")
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
       
    }
    
    private func setupUI() {
        
    }
}
