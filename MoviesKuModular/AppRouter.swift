//
//  AppRouter.swift
//  MoviesKuModular
//
//  Created by zeekands on 24/08/25.
//


import Foundation
import Combine
import SwiftUI
import UIKit
import SharedDomain
import FeatureMovies
import FeatureTVShows
import FeatureFavorite
import FeatureSearch

@MainActor
public final class AppRouter: ObservableObject, @preconcurrency AppNavigatorProtocol {
  public var diContainer: DIContainer!
  @Published public var tabRootNavigationControllers: [AppTab: UINavigationController] = [:]
  @Published public var currentSheetRoute: AppRoute?
  @Published public var activeTab: AppTab = .movies
  @Published public var globalRoute: AppRoute?
  @Published public var globalPath = NavigationPath()
  
  public init() {
    for tab in AppTab.allCases {
      let navController = UINavigationController()
      navController.navigationBar.prefersLargeTitles = false
      tabRootNavigationControllers[tab] = navController
    }
  }
  
  public func handleDeeplink(url: URL) -> Bool {
    guard let deeplink = Deeplink.from(url: url) else {
      print("AppRouter: Could not parse deeplink from URL: \(url)")
      return false
    }
    
    print("AppRouter: Handling deeplink: \(deeplink)")
    dismissGlobalRoute()
    dismissSheet()
    
    switch deeplink {
      case .movieDetail(let id):
        selectTab(.movies)
        popToRoot(inTab: .movies)
        navigate(to: .movieDetail(movieId: id), inTab: .movies)
        
      case .tvShowDetail(let id):
        // Pindah ke tab TV Shows
        selectTab(.tvShows)
        popToRoot(inTab: .tvShows)
        navigate(to: .tvShowDetail(tvShowId: id), inTab: .tvShows)
        
      case .search(_):
        selectTab(.movies)
        popToRoot(inTab: .movies)
        navigate(to: .search, inTab: .movies)
        
      case .tab(_): break
        
    }
    
    return true
  }
  
  public func navigate(to route: AppRoute, inTab tab: AppTab, hideTabBar: Bool = false) {
    guard let navController = tabRootNavigationControllers[tab] else {
      print("AppRouter Error: Navigation controller not found for tab \(tab)")
      return
    }
    let hostingController: UIHostingController<AnyView>
    switch route {
      case .search:
        hostingController = UIHostingController(rootView: AnyView(diContainer.makeSearchView()))
      case .movieDetail(let movieId):
        hostingController = UIHostingController(rootView: AnyView(diContainer.makeMovieDetailView(movieId: movieId)))
      case .tvShowDetail(let tvShowId):
        hostingController = UIHostingController(rootView: AnyView(diContainer.makeTVShowDetailView(tvShowId: tvShowId)))
      default:
        fatalError("AppRouter: Unhandled push route \(route).")
    }
    navController.navigationBar.isTranslucent = false
    navController.navigationBar.backgroundColor = UIColor.systemBackground
    hostingController.hidesBottomBarWhenPushed = hideTabBar
    navController.pushViewController(hostingController, animated: true)
  }
  
  public func pop(inTab tab: AppTab) {
    tabRootNavigationControllers[tab]?.popViewController(animated: true)
  }
  
  public func popToRoot(inTab tab: AppTab) {
    tabRootNavigationControllers[tab]?.popToRootViewController(animated: true)
  }
  
  public func presentSheet(_ route: AppRoute) {
    currentSheetRoute = route
  }
  
  public func dismissSheet() {
    currentSheetRoute = nil
  }
  
  public func selectTab(_ tab: AppTab) {
    activeTab = tab
  }
  
  public func presentGlobalRoute(_ route: AppRoute) {
    globalPath = NavigationPath()
    globalPath.append(route)
    globalRoute = route
    print("AppRouter: Presenting global route: \(route). GlobalPath count: \(globalPath.count)")
  }
  
  public func dismissGlobalRoute() {
    globalPath = NavigationPath()
    globalRoute = nil
    print("AppRouter: Dismissing global route.")
  }
  
  public func makeRootViewController(for tab: AppTab, diContainer: DIContainer) -> UIViewController {
    let rootView: AnyView
    switch tab {
      case .movies:
        rootView = AnyView(diContainer.makeMoviesListView())
      case .tvShows:
        rootView = AnyView(diContainer.makeTVShowsListView())
      case .favorites:
        rootView = AnyView(diContainer.makeFavoritesListView())
      case .about:
        rootView = AnyView(diContainer.makeAboutView())
    }
    let hostingController = UIHostingController(rootView: rootView)
    let navController = tabRootNavigationControllers[tab]!
    navController.navigationBar.isTranslucent = false
    navController.navigationBar.backgroundColor = UIColor.systemBackground
    navController.navigationBar.prefersLargeTitles = true
    navController.setViewControllers([hostingController], animated: false)
    hostingController.tabBarItem = UITabBarItem(
      title: tab.rawValueTitle,
      image: UIImage(systemName: tab.iconName),
      selectedImage: UIImage(systemName: tab.iconName + ".fill")
    )
    return navController
  }
  
  @ViewBuilder
  public func view(for route: AppRoute, diContainer: DIContainer) -> some View {
    switch route {
      case .movieDetail(_), .tvShowDetail(_), .movieList(_), .tvShowList(_), .favoritesList(_), .about:
        EmptyView()
      case .search:
        diContainer.makeSearchView()
    }
  }
}

public struct AppRootViewControllerRepresentable: UIViewControllerRepresentable {
  @ObservedObject var appRouter: AppRouter
  @ObservedObject var diContainer: DIContainer
  
  public func makeUIViewController(context: Context) -> UITabBarController {
    let tabBarController = UITabBarController()
    let moviesNavController = appRouter.makeRootViewController(for: .movies, diContainer: diContainer)
    let tvShowsNavController = appRouter.makeRootViewController(for: .tvShows, diContainer: diContainer)
    let favoritesNavController = appRouter.makeRootViewController(for: .favorites, diContainer: diContainer)
    let aboutNavController = appRouter.makeRootViewController(for: .about, diContainer: diContainer)
    tabBarController.viewControllers = [
      moviesNavController,
      tvShowsNavController,
      favoritesNavController,
      aboutNavController
    ]
    tabBarController.tabBar.isTranslucent = false
    tabBarController.tabBar.backgroundColor = UIColor.systemBackground
    let coordinator = context.coordinator
    coordinator.tabBarController = tabBarController
    tabBarController.delegate = coordinator
    tabBarController.selectedIndex = appRouter.activeTab.index
    
    return tabBarController
  }
  
  public func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
    if uiViewController.selectedIndex != appRouter.activeTab.index {
      uiViewController.selectedIndex = appRouter.activeTab.index
    }
  }
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(appRouter: appRouter)
  }
  
  public class Coordinator: NSObject, UITabBarControllerDelegate {
    var appRouter: AppRouter
    weak var tabBarController: UITabBarController?
    var cancellables: Set<AnyCancellable> = []
    
    init(appRouter: AppRouter) {
      self.appRouter = appRouter
      super.init()
      
      appRouter.$activeTab
        .receive(on: DispatchQueue.main)
        .sink { [weak self] newTab in
          guard let self, let tabBar = self.tabBarController else { return }
          if tabBar.selectedIndex != newTab.index {
            tabBar.selectedIndex = newTab.index
          }
        }
        .store(in: &cancellables)
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
      if let index = tabBarController.viewControllers?.firstIndex(of: viewController),
         let tab = AppTab(rawValue: index) {
        appRouter.activeTab = tab
      }
    }
  }
}
