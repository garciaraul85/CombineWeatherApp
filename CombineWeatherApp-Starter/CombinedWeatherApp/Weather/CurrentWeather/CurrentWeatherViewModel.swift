import SwiftUI
import Combine

// 1: Make CurrentWeatherViewModel conform to ObservableObject and Identifiable.
class CurrentWeatherViewModel: ObservableObject, Identifiable {
  // 2: Expose an optional CurrentWeatherRowViewModel as the data source.
  @Published var dataSource: CurrentWeatherRowViewModel?
  
  let city: String
  private let weatherFetcher: WeatherFetchable
  private var disposables = Set<AnyCancellable>()
  
  init(city: String, weatherFetcher: WeatherFetchable) {
    self.weatherFetcher = weatherFetcher
    self.city = city
  }
  
  func refresh() {
    weatherFetcher
      .currentWeatherForecast(forCity: city)
      // 3: Transform new values to a CurrentWeatherRowViewModel as they come in the form of a CurrentWeatherForecastResponse.
      .map(CurrentWeatherRowViewModel.init)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { [weak self] value in
        guard let self = self else { return }
        switch value {
          case .failure:
            self.dataSource = nil
          case .finished:
            break
        }
      }, receiveValue: { [weak self] weather in
        guard let self = self else { return }
        self.dataSource = weather
      })
      .store(in: &disposables)
  }
}
