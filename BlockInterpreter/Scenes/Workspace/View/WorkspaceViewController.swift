//
//  WorkspaceViewController.swift
//  BlockInterpreter
//

import UIKit
import SnapKit
import Combine

final class WorkspaceViewController: UIViewController {
    
    private enum Constants {
            enum RunButton {
                static let size: CGFloat = 60
                static let cornerRadius: CGFloat = size / 2
                static let insetRight: CGFloat = 40
                static let insetBotton: CGFloat = 130
            }
    }
    
    private let codeTableView = UITableView()
    private let runButton = UIButton(type: .system)
    
    private lazy var backdrop: UIView = {
      let backdrop = UIView()
        
      backdrop.backgroundColor = .gray.withAlphaComponent(0.7)
      backdrop.isHidden = true
        
      return backdrop
    }()
    
    private let viewModel: WorkspaceViewModelType
    private var subscriptions = Set<AnyCancellable>()
    
    init(with viewModel: WorkspaceViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBindings()
    }
    
    private func move(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
      codeTableView.performBatchUpdates({
        codeTableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
      }) { [weak self] _ in
          self?.viewModel.moveBlock.send((sourceIndexPath, destinationIndexPath))
      }
    }
    
    private func setupUI() {
        setupSuperView()
        setupCodeTableView()
        setupRunButton()
    }
    
    private func setupSuperView() {
        view.backgroundColor = .systemBlue
    }
    
    private func setupCodeTableView() {
        view.addSubview(codeTableView)
        
        codeTableView.delegate = self
        codeTableView.dataSource = self
        codeTableView.dragDelegate = self
        codeTableView.dropDelegate = self
        codeTableView.separatorStyle = .none
        codeTableView.backgroundColor = .systemBlue
        codeTableView.register(VariableBlockCell.self, forCellReuseIdentifier: VariableBlockCell.identifier)
        codeTableView.register(ConditionBlockCell.self, forCellReuseIdentifier: ConditionBlockCell.identifier)
        
        codeTableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.width.equalToSuperview().multipliedBy(0.85)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupRunButton() {
        view.addSubview(runButton)
        
        runButton.backgroundColor = .appBlack
        runButton.tintColor = .systemGreen
        runButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        runButton.layer.cornerRadius = Constants.RunButton.cornerRadius
        
        runButton.snp.makeConstraints { make in
            make.width.height.equalTo(Constants.RunButton.size)
            make.right.equalToSuperview().inset(Constants.RunButton.insetRight)
            make.bottom.equalToSuperview().inset(Constants.RunButton.insetBotton)
        }
    }
    
}

// MARK: - UITableViewDataSource

extension WorkspaceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = viewModel.cellViewModels[indexPath.row]
        
        switch cellViewModel.type {
        case .variable:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: VariableBlockCell.identifier, for: indexPath) as? VariableBlockCell,
                let cellViewModel = cellViewModel as? VariableBlockCellViewModel
            else { return .init() }
            
            cell.configure(with: cellViewModel)
            return cell
            
        case .condition:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: ConditionBlockCell.identifier, for: indexPath) as? ConditionBlockCell,
                let cellViewModel = cellViewModel as? ConditionBlockCellViewModel
            else { return .init() }
            
            cell.configure(with: cellViewModel)
            return cell
            
        case .loop:
            return UITableViewCell()
        case .output:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

    }
    
}

// MARK: - UITableViewDelegate

extension WorkspaceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected work cell")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - UITableViewDragDelegate

extension WorkspaceViewController: UITableViewDragDelegate {
    
  func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
      backdrop.isHidden = false

      let item = UIDragItem(itemProvider: NSItemProvider())
      item.localObject = indexPath
      
      return [item]
  }

  func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
      let preview = UIDragPreviewParameters()
      
      preview.backgroundColor = .clear
      if #available(iOS 14.0, *) {
          preview.shadowPath = UIBezierPath(rect: .zero)
      }
      
      return preview
  }

}

// MARK: - UITableViewDropDelegate

extension WorkspaceViewController: UITableViewDropDelegate {

  func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
    guard
      let item = session.items.first,
      let fromIndexPath = item.localObject as? IndexPath,
      let toIndexPath = destinationIndexPath
    else {
      backdrop.frame = .zero
      return UITableViewDropProposal(operation: .forbidden)
    }
      
    if let firstCell = tableView.cellForRow(at: toIndexPath) {
      let headerFrame = tableView.rectForHeader(inSection: toIndexPath.section)
      let newFrame = CGRect(
        x: headerFrame.minX,
        y: headerFrame.maxY + (CGFloat(toIndexPath.row) * firstCell.frame.height),
        width: firstCell.frame.width,
        height: firstCell.frame.height
      )

      if backdrop.frame == .zero {
        backdrop.frame = newFrame
      } else {
        UIView.animate(withDuration: 0.15) { [backdrop] in
          backdrop.frame = newFrame
        }
      }
    } else {
      backdrop.frame = .zero
    }

    if fromIndexPath.section == toIndexPath.section {
      return .init(operation: .move, intent: .automatic)
    }
      
    return UITableViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
  }

  func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    guard
      let item = coordinator.session.items.first,
      let sourceIndexPath = item.localObject as? IndexPath,
      let destinationIndexPath = coordinator.destinationIndexPath
    else { return }

    switch coordinator.proposal.intent {
      case .insertAtDestinationIndexPath:
        move(from: sourceIndexPath, to: destinationIndexPath)
        coordinator.drop(item, toRowAt: destinationIndexPath)

      case .insertIntoDestinationIndexPath:
//        interact(from: sourceIndexPath, to: destinationIndexPath)
        coordinator.drop(item, toRowAt: sourceIndexPath)
      default: break
    }
      
    backdrop.isHidden = true
    backdrop.frame = .zero
  }
    
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let preview = UIDragPreviewParameters()
        
        preview.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            preview.shadowPath = UIBezierPath(rect: .zero)
        }
        
        return preview
    }
    
}

// MARK: - Reactive Behavior

private extension WorkspaceViewController {
    func setupBindings() {
        runButton.tapPublisher
            .sink { [weak self] in self?.viewModel.showConsole.send() }
            .store(in: &subscriptions)
    }
}
