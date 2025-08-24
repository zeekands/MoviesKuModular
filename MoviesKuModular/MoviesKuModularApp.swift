import SwiftUI

@main
public struct MoviesKuModularApp: App {
  @State private var hasSeenOnboarding: Bool
  @StateObject private var diContainer: DIContainer
  @StateObject private var appRouter: AppRouter
  
  public init() {
    let routerInstance = AppRouter()
    let containerInstance = DIContainer(appRouter: routerInstance)
    routerInstance.diContainer = containerInstance
    _appRouter = StateObject(wrappedValue: routerInstance)
    _diContainer = StateObject(wrappedValue: containerInstance)
    let hasSeen = containerInstance.onboardingService.hasSeenOnboarding()
    _hasSeenOnboarding = State(wrappedValue: hasSeen)
  }
  
  public var body: some Scene {
    WindowGroup {
      if !hasSeenOnboarding {
        diContainer.makeOnboardingView {
          hasSeenOnboarding = true
        }
        .onOpenURL { url in
          _ = appRouter.handleDeeplink(url: url)
        }
      } else {
        AppRootViewControllerRepresentable(
          appRouter: appRouter,
          diContainer: diContainer
        )
        .preferredColorScheme(.light)
        .onOpenURL { url in
          _ = appRouter.handleDeeplink(url: url)
        }
      }
    }
  }
}
