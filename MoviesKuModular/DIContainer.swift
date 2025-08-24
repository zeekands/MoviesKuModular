//
//  DIContainer.swift
//  MoviesKuModular
//
//  Created by zeekands on 24/08/25.
//


import Foundation
import FeatureOnboarding
import SwiftData
import SharedDomain
import SharedData
import FeatureMovies
import FeatureTVShows
import FeatureFavorite
import FeatureSearch
import SwiftUI

@MainActor
public final class DIContainer: ObservableObject {
  public let appRouter: AppRouter
  public let realmDataSource: RealmDataSource
  public let movieLocalDataSource: MovieLocalDataSourceProtocol
  public let tvShowLocalDataSource: TVShowLocalDataSourceProtocol
  public let movieNetworkDataSource: MovieNetworkDataSourceProtocol
  public let tvShowNetworkDataSource: TVShowNetworkDataSourceProtocol
  public let apiClient: TMDBAPIClient
  
  // MARK: - Repositories
  public let movieRepository: MovieRepositoryProtocol
  public let tvShowRepository: TVShowRepositoryProtocol
  public let genreRepository: GenreRepositoryProtocol
  
  // MARK: - Use Cases (Movies)
  public let getPopularMoviesUseCase: GetPopularMoviesUseCaseProtocol
  public let getTrendingMoviesUseCase: GetTrendingMoviesUseCaseProtocol
  public let getMovieDetailUseCase: GetMovieDetailUseCaseProtocol
  public let searchMoviesUseCase: SearchMoviesUseCaseProtocol
  
  // MARK: - Use Cases (TVShows)
  public let getPopularTVShowsUseCase: GetPopularTVShowsUseCaseProtocol
  public let getTrendingTVShowsUseCase: GetTrendingTVShowsUseCaseProtocol
  public let getTVShowDetailUseCase: GetTVShowDetailUseCaseProtocol
  public let searchTVShowsUseCase: SearchTVShowsUseCaseProtocol
  
  // MARK: - Use Cases (Shared)
  public let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol
  
  // MARK: - Use Cases (Favorites)
  public let getFavoriteMoviesUseCase: GetFavoriteMoviesUseCaseProtocol
  public let getFavoriteTVShowsUseCase: GetFavoriteTVShowsUseCaseProtocol
  
  // MARK: - Services
  let onboardingService: OnboardingPersistenceService
  
  // MARK: - Initialization
  public init(appRouter: AppRouter) {
    self.appRouter = appRouter
    guard let accessToken = Bundle.main.infoDictionary?["TMDB_ACCESS_TOKEN"] as? String,
          let baseURL = Bundle.main.infoDictionary?["TMDB_BASE_URL"] as? String else {
      fatalError("TMDB_ACCESS_TOKEN or TMDB_BASE_URL not found in Info.plist. Please configure xcconfig and Info.plist.")
    }
    self.apiClient = TMDBAPIClient(accessToken: accessToken, baseURL: baseURL)
    self.realmDataSource = RealmDataSource()
    self.onboardingService = UserDefaultsOnboardingService()
    self.movieLocalDataSource = MovieLocalDataSource(realmDataSource: realmDataSource)
    self.tvShowLocalDataSource = TVShowLocalDataSource(realmDataSource: realmDataSource)
    self.movieNetworkDataSource = MovieNetworkDataSource(apiClient: apiClient)
    self.tvShowNetworkDataSource = TVShowNetworkDataSource(apiClient: apiClient)
    
    self.movieRepository = MovieRepositoryImpl(
      localDataSource: movieLocalDataSource,
      networkDataSource: movieNetworkDataSource,
      genreLocalDataSource: movieLocalDataSource
    )
    self.tvShowRepository = TVShowRepositoryImpl(
      localDataSource: tvShowLocalDataSource,
      networkDataSource: tvShowNetworkDataSource,
      genreLocalDataSource: movieLocalDataSource
    )
    self.genreRepository = GenreRepositoryImpl(
      apiClient: apiClient,
      movieLocalDataSource: movieLocalDataSource,
      tvShowLocalDataSource: tvShowLocalDataSource
    )
    
    self.getPopularMoviesUseCase = GetPopularMovies(repository: movieRepository)
    self.getTrendingMoviesUseCase = GetTrendingMovies(repository: movieRepository)
    self.getMovieDetailUseCase = GetMovieDetail(repository: movieRepository)
    self.searchMoviesUseCase = SearchMovies(repository: movieRepository)
    
    self.getPopularTVShowsUseCase = GetPopularTVShows(repository: tvShowRepository)
    self.getTrendingTVShowsUseCase = GetTrendingTVShows(repository: tvShowRepository)
    self.getTVShowDetailUseCase = GetTVShowDetail(repository: tvShowRepository)
    self.searchTVShowsUseCase = SearchTVShows(repository: tvShowRepository)
    
    self.toggleFavoriteUseCase = ToggleFavorite(movieRepository: movieRepository, tvShowRepository: tvShowRepository)
    
    self.getFavoriteMoviesUseCase = GetFavoriteMovies(repository: movieRepository)
    self.getFavoriteTVShowsUseCase = GetFavoriteTVShows(repository: tvShowRepository)
    appRouter.diContainer = self
  }
  
  public func makeMoviesListViewModel() -> MovieListViewModel {
    MovieListViewModel(
      getPopularMoviesUseCase: getPopularMoviesUseCase,
      getTrendingMoviesUseCase: getTrendingMoviesUseCase,
      getMovieDetailUseCase: getMovieDetailUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
      appNavigator: appRouter
    )
  }
  
  public func makeMovieDetailViewModel(movieId: Int) -> MovieDetailViewModel {
    MovieDetailViewModel(
      movieId: movieId,
      getMovieDetailUseCase: getMovieDetailUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
      appNavigator: appRouter
    )
  }
  
  public func makeTVShowsListViewModel() -> TVShowListViewModel {
    TVShowListViewModel(
      getPopularTVShowsUseCase: getPopularTVShowsUseCase,
      getTrendingTVShowsUseCase: getTrendingTVShowsUseCase,
      getTVShowDetailUseCase: getTVShowDetailUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
      appNavigator: appRouter
    )
  }
  
  public func makeTVShowDetailViewModel(tvShowId: Int) -> TVShowDetailViewModel {
    TVShowDetailViewModel(
      tvShowId: tvShowId,
      getTVShowDetailUseCase: getTVShowDetailUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
      appNavigator: appRouter
    )
  }
  
  public func makeFavoritesListViewModel() -> FavoritesListViewModel {
    FavoritesListViewModel(
      getFavoriteMoviesUseCase: getFavoriteMoviesUseCase,
      getFavoriteTVShowsUseCase: getFavoriteTVShowsUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
      appNavigator: appRouter
    )
  }
  
  public func makeSearchViewModel() -> SearchViewModel {
    SearchViewModel(
      searchMoviesUseCase: searchMoviesUseCase,
      searchTVShowsUseCase: searchTVShowsUseCase,
      getMovieDetailUseCase: getMovieDetailUseCase,
      getTVShowDetailUseCase: getTVShowDetailUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
      appNavigator: appRouter
    )
  }
  
  public func makeMoviesListView() -> some View {
    let viewModel = makeMoviesListViewModel()
    return MovieListView(viewModel: viewModel)
  }
  
  public func makeMovieDetailView(movieId: Int) -> some View {
    let viewModel = makeMovieDetailViewModel(movieId: movieId)
    return MovieDetailView(viewModel: viewModel)
  }
  
  public func makeAboutView() -> some View {
    return AboutView()
  }
  
  public func makeTVShowsListView() -> some View {
    let viewModel = makeTVShowsListViewModel()
    return TVShowListView(viewModel: viewModel)
  }
  
  public func makeTVShowDetailView(tvShowId: Int) -> some View {
    let viewModel = makeTVShowDetailViewModel(tvShowId: tvShowId)
    return TVShowDetailView(viewModel: viewModel)
  }
  
  public func makeFavoritesListView() -> some View {
    let viewModel = makeFavoritesListViewModel()
    return FavoritesListView(viewModel: viewModel)
  }
  
  public func makeSearchView() -> some View {
    let viewModel = makeSearchViewModel()
    return SearchView(viewModel: viewModel)
  }
  
  func makeOnboardingView(onFinish: @escaping () -> Void) -> some View {
    let viewModel = OnboardingViewModel(
      pages: [
        .init(imageName: "film", title: "Welcome", description: "Discover movies and TV shows easily."),
        .init(imageName: "star", title: "Favorite", description: "Save your favorite movies and TV shows."),
        .init(imageName: "magnifyingglass", title: "Search", description: "Find what you love quickly.")
      ],
      onFinish: onFinish,
      onboardingService: onboardingService
    )
    return OnboardingView(viewModel: viewModel)
  }
}
