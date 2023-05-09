//
//  BlockCellStyle.swift
//  BlockInterpreter
//
//  Created by Ivan Semenov on 10.05.2023.
//

import Foundation

enum BlockCellStyle {
    case work, presentation
    
    var cornerRadius: CGFloat {
        switch self {
        case .work:
            return 8
        case .presentation:
            return 15
        }
    }
    
    func multiplierHeight() -> CGFloat {
        switch self {
        case .work:
            return 1
        case .presentation:
            return 0.75
        }
    }
    
    func multiplierWidth(for blockType: BlockType) -> CGFloat {
        guard self == .work else { return 1 }
        
        switch blockType {
        case .variable:
            return 0.8
        case .condition:
            return 0.9
        case .loop:
            return 1
        case .output:
            return 1
        }
    }
}
