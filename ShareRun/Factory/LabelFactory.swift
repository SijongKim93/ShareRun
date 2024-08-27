//
//  LabelFactory.swift
//  ShareRun
//
//  Created by 김시종 on 8/27/24.
//

import UIKit

class LabelFactory {
    static func createRunningLabel(fontSize: CGFloat, weight: UIFont.Weight, textColor: UIColor, textAlignment: NSTextAlignment, title: String? = nil) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: fontSize, weight: weight)
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.text = title ?? ""
        return label
    }
}
