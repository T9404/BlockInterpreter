//
//  BlockTextField.swift
//  BlockInterpreter
//

import UIKit

final class BlockTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        borderStyle = .none
        textAlignment = .center
        returnKeyType = .done
        clearButtonMode = .never
        tintColor = .appPurple
        textColor = .appBlack
        backgroundColor = .appWhite
        layer.cornerRadius = 10
        font = .blockTextField
        adjustsFontSizeToFitWidth = true
        minimumFontSize = 0.1
    }
}
