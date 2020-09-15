import SwiftUI

// This entity will act as a factory to create screens that are needed when navigating from the WeeklyWeatherView.
enum WeeklyWeatherBuilder {
  static func makeCurrentWeatherView(
    withCity city: String,
    weatherFetcher: WeatherFetchable
  ) -> some View {
    let viewModel = CurrentWeatherViewModel(
      city: city,
      weatherFetcher: weatherFetcher)
    return CurrentWeatherView(viewModel: viewModel)
  }
}
