import Foundation


class Tree {
    var rootNode: Node = Node(value: "", type: AllTypes.root, id: 0)
    var index: Int = 0
    var blocks = [IBlock]()

    init() {

    }

    func setBlocks(_ blocks: [IBlock]) {
        self.blocks = blocks
    }

    func buildTree() {
        while index < blocks.count {
            let block = blocks[index]
            switch block {
            case let variableBlock as Variable:
                let variableNode = buildVariableNode(variable: variableBlock)
                rootNode.addChild(variableNode)
                index += 1
            case let printBlock as Output:
                let printingNode = buildPrintingNode(printing: printBlock)
                rootNode.addChild(printingNode)
                index += 1
            case is Loop:
                if let loopNode = buildNode(getBlockAndMoveIndex(),
                        type: AllTypes.loop) {
                    rootNode.addChild(loopNode)
                }
            case is Condition:
                if let conditionNode = buildNode(getBlockAndMoveIndex(),
                        type: determineConditionBlock(block) ?? AllTypes.ifBlock) {
                    rootNode.addChild(conditionNode)
                }
            case is Function:
                if let functionNode = buildNode(getBlockAndMoveIndex(),
                        type: AllTypes.function) {
                    rootNode.addChild(functionNode)
                }
            case is Flow:
                index += 1
            default:
                index += 1
            }
        }
    }

    private func getMatchingDelimiterIndex() -> Int? {
        var countBegin = 0
        for i in (index + 1)..<blocks.count {
            guard let block = blocks[i] as? Flow else {
                continue
            }
            countBegin += countForMatchingDelimiter(block)
            if countBegin == 0 {
                return i
            }
        }
        return nil
    }

    private func countForMatchingDelimiter(_ block: Flow) -> Int {
        if isEndDelimiter(block) {
            return -1
        } else if isBeginDelimiter(block) {
            return 1
        }
        return 0
    }

    private func isBeginDelimiter(_ block: Flow) -> Bool {
        block.type == FlowType.begin
    }

    private func isEndDelimiter(_ block: Flow) -> Bool {
        block.type == FlowType.end
    }


    private func getBlockAndMoveIndex() -> [IBlock] {
        var wholeBlock: [IBlock] = []
        guard let endIndex = getMatchingDelimiterIndex() else {
            return wholeBlock
        }
        wholeBlock.append(blocks[index])
        wholeBlock += Array(blocks[(index + 1)...endIndex])
        index = endIndex + 1
        return wholeBlock
    }

    private func buildVariableNode(variable: Variable) -> Node {
        let node = Node(value: variable.type.rawValue, type: AllTypes.assign,
                id: variable.id)
        let nameVariable = Node(value: variable.name, type: AllTypes.variable,
                id: variable.id)
        let valueVariable = Node(value: variable.value, type: AllTypes.arithmetic,
                id: variable.id)
        node.addChild(nameVariable)
        node.addChild(valueVariable)
        return node
    }


    private func buildPrintingNode(printing: Output) -> Node {
        let node = Node(value: printing.value, type: AllTypes.print,
                id: printing.id)
        return node
    }

    private func determineConditionBlock(_ block: IBlock) -> AllTypes? {
        if let condition = block as? Condition {
            if condition.type == ConditionType.ifBlock {
                return AllTypes.ifBlock
            } else if condition.type == ConditionType.elifBlock {
                return AllTypes.elifBlock
            } else if condition.type == ConditionType.elseBlock {
                return AllTypes.elseBlock
            }
        }
        return nil
    }


    private func buildNode(_ block: [IBlock], type: AllTypes) -> Node? {
        guard let firstBlock = block.first else {
            return nil
        }

        var node: Node?

        if type == AllTypes.ifBlock {
            guard let condition = firstBlock as? Condition else {
                return nil
            }
            node = Node(value: condition.value, type: AllTypes.ifBlock, id: condition.id)
        } else if type == AllTypes.elifBlock {
            guard let condition = firstBlock as? Condition else {
                return nil
            }
            node = Node(value: condition.value, type: AllTypes.elifBlock, id: condition.id)
        } else if type == AllTypes.elseBlock {
            guard let condtion = firstBlock as? Condition else {
                return nil
            }
            node = Node(value: condtion.value, type: AllTypes.elseBlock, id: condtion.id)
        }
        else if type == AllTypes.loop {
            guard let loop = firstBlock as? Loop else {
                return nil
            }
            node = Node(value: loop.value, type: type, id: loop.id)
        } else if type == AllTypes.function {
            guard let function = firstBlock as? Function else {
                return nil
            }
            node = Node(value: function.value, type: type, id: function.id)
        }

        var index = 1

        while index < block.count {
            if block[index] is Flow {
                index += 1
                continue
            } else if let variableBlock = block[index] as? Variable {
                let variableNode = buildVariableNode(variable: variableBlock)
                node?.addChild(variableNode)
            } else if let printBlock = block[index] as? Output {
                let printingNode = buildPrintingNode(printing: printBlock)
                node?.addChild(printingNode)
            } else if let returnBlock = block[index] as? Returning {
                let returnNode = Node(value: returnBlock.value,
                        type: .returnFunction, id: returnBlock.id)
                node?.addChild(returnNode)
            } else if let nestedConditionBlock = block[index] as? Condition {
                var nestedBlocks: [IBlock] = []
                var additionIndex = index + 1
                nestedBlocks.append(nestedConditionBlock)
                var countBegin: Int = 0
                while additionIndex < block.count {
                    if let blockEnd = block[additionIndex] as? Flow {
                        countBegin += countForMatchingDelimiter(blockEnd)
                        if countBegin == 0 {
                            break
                        }
                    }
                    nestedBlocks.append(block[additionIndex])
                    additionIndex += 1
                }
                if let typeCondition = determineConditionBlock(nestedConditionBlock) {
                    if let nestedNode = buildNode(nestedBlocks, type: typeCondition) {
                        node?.addChild(nestedNode)
                    }
                }

                index = additionIndex
            } else if let nestedLoopBlock = block[index] as? Loop {
                var nestedBlocks: [IBlock] = []
                var additionIndex = index + 1
                nestedBlocks.append(nestedLoopBlock)
                var countBegin: Int = 0
                while additionIndex < block.count {
                    if let blockEnd = block[additionIndex] as? Flow {
                        countBegin += countForMatchingDelimiter(blockEnd)
                        if countBegin == 0 {
                            break
                        }
                    }
                    nestedBlocks.append(block[additionIndex])
                    additionIndex += 1
                }
                if let nestedNode = buildNode(nestedBlocks, type: .loop) {
                    node?.addChild(nestedNode)
                }
                index = additionIndex
            } else if let nestedFunctionBlock = block[index] as? Function {
                var nestedBlocks: [IBlock] = []
                var additionIndex = index + 1
                nestedBlocks.append(nestedFunctionBlock)
                var countBegin: Int = 0
                while additionIndex < block.count {
                    if let blockEnd = block[additionIndex] as? Flow {
                        countBegin += countForMatchingDelimiter(blockEnd)
                        if countBegin == 0 {
                            break
                        }
                    }
                    nestedBlocks.append(block[additionIndex])
                    additionIndex += 1
                }
                if let nestedNode = buildNode(nestedBlocks, type: .function) {
                    node?.addChild(nestedNode)
                }
                index = additionIndex
            }
            index += 1
        }
        return node
    }
}