//
//  MainCoordinator.swift
//  Example
//
//  Created by Matthias Buchetics on 28.07.18.
//  Copyright © 2018 aaa - all about apps GmbH. All rights reserved.
//

import UIKit

class MainCoordinator: NavigationCoordinator {
    
    func start() {
        let viewModel = ExampleViewModel(title: "Main")
        let viewController = createExampleViewController(viewModel: viewModel)
        
        push(viewController, animated: true)
    }
    
    private func showNext(title: String) {
        let viewModel = ExampleViewModel(title: title + ".Push")
        let viewController = createExampleViewController(viewModel: viewModel)
        
        push(viewController, animated: true)
    }
    
    private func createExampleViewController(viewModel: ExampleViewModel) -> ExampleViewController {
        let viewController = ExampleViewController.createWith(storyboard: .main, viewModel: viewModel)
        
        viewController.onNext = { [unowned self] in
            self.showNext(title: viewModel.title)
        }
        
        viewController.onMore = { [unowned self] in
            self.showMoreModal()
        }
        
        viewController.onDebug = { [unowned self] in
            self.showDebug()
        }
        
        viewController.onTabBar = { [unowned self] in
            self.showTabBar()
        }
        
        return viewController
    }
    
    private func showMore() {
        let coordinator = MoreCoordinator(navigationController: navigationController)
        coordinator.start()
        
        push(coordinator, animated: true)
    }
    
    private func showDebug() {
        let coordinator = DebugCoordinator()
        coordinator.onDismiss = { [unowned self] in
            self.dismissChildCoordinator(animated: true)
        }
        coordinator.start()
        present(coordinator, animated: true)
    }
    
    private func showMoreModal() {
        let coordinator = MoreCoordinator()
        
        coordinator.onDone = { [unowned self] in
            self.dismissChildCoordinator(animated: true)
        }
        
        coordinator.start()
        
        present(coordinator, animated: true)
    }
    
    private func showTabBar() {
        let tabBarCoordinator = ExampleTabBarCoordinator()
        tabBarCoordinator.start()
        present(tabBarCoordinator, animated: true)
    }
    
}
