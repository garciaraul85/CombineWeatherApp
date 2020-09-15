import SwiftUI
import Combine

// 1: Make WeeklyWeatherViewModel conform to ObservableObject and Identifiable. Conforming to these means that the WeeklyWeatherViewModel‘s properties can be used as bindings.
class WeeklyWeatherViewModel: ObservableObject, Identifiable {
  // 2: The properly delegate @Published modifier makes it possible to observe the city property.
  @Published var city: String = ""
  
  // 3: You’ll keep the View’s data source in the ViewModel. This is in contrast to what you might be used to doing in MVC. Because the property is marked @Published, the compiler automatically synthesizes a publisher for it. SwiftUI subscribes to that publisher and redraws the screen when you change the property.
  @Published var dataSource: [DailyWeatherRowViewModel] = []
  
  private let weatherFetcher: WeatherFetchable
  
  // 4: Think of disposables as a collection of references to requests. Without keeping these references, the network requests you’ll make won’t be kept alive, preventing you from getting responses from the server.
  private var disposables = Set<AnyCancellable>()
  
  init(weatherFetcher: WeatherFetchable) {
    self.weatherFetcher = weatherFetcher
  }
  
  func fetchWeather(forCity city: String) {
    // 1: Start by making a new request to fetch the information from the OpenWeatherMap API. Pass the city name as the argument
    weatherFetcher.weeklyWeatherForecast(forCity: city)
      .map { response in
        // 2: Map the response (WeeklyForecastResponse object) to an array of DailyWeatherRowViewModel objects. This entity represents a single row in the list.
        response.list.map(DailyWeatherRowViewModel.init)
      }

      // 3: The OpenWeatherMap API returns multiple temperatures for the same day depending on the time of the day, so remove the duplicates.
      .map(Array.removeDuplicates)

      // 4: Although fetching data from the server, or parsing a blob of JSON, happens on a background queue, updating the UI must happen on the main queue. With receive(on:), you ensure the update you do in steps 5, 6 and 7 occurs in the right place.
      .receive(on: DispatchQueue.main)

      // 5: Start the publisher via sink(receiveCompletion:receiveValue:). This is where you update dataSource accordingly. It’s important to notice that handling a completion — either a successful or failed one — happens separately from handling values.
      .sink(
        receiveCompletion: { [weak self] value in
          guard let self = self else { return }
          switch value {
          case .failure:
            // 6: In the event of a failure, set dataSource as an empty array.
            self.dataSource = []
          case .finished:
            break
          }
        },
        receiveValue: { [weak self] forecast in
          guard let self = self else { return }

          // 7: Update dataSource when a new forecast arrives.
          self.dataSource = forecast
      })

      // 8: Finally, add the cancellable reference to the disposables set. As previously mentioned, without keeping this reference alive, the network publisher will terminate immediately.
      .store(in: &disposables)
  }
  
}
