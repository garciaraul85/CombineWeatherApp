/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Combine

class WeatherFetcher {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
}

// MARK: - OpenWeatherMap API
private extension WeatherFetcher {
  struct OpenWeatherAPI {
    static let scheme = "https"
    static let host = "api.openweathermap.org"
    static let path = "/data/2.5"
    static let key = "4518f18a81f134d19907d443544d0fc9"
  }
  
  func makeWeeklyForecastComponents(
    withCity city: String
  ) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/forecast"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
  
  func makeCurrentDayForecastComponents(
    withCity city: String
  ) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/weather"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
}

// You’ll use the first method for the first screen to display the weather forecast for the next five days. You’ll use the second to view more detailed weather information.
// The first parameter (WeeklyForecastResponse) refers to the type it returns if the computation is successful and, as you might have guessed, the second refers to the type if it fails (WeatherError).
protocol WeatherFetchable {
  func weeklyWeatherForecast(forCity city: String)
  -> AnyPublisher<WeeklyForecastResponse, WeatherError>
  
  func currentWeatherForecast(forCity city: String)
  -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError>
}

extension WeatherFetcher: WeatherFetchable {
  func weeklyWeatherForecast(
    forCity city: String
  ) -> AnyPublisher<WeeklyForecastResponse, WeatherError> {
    return forecast(with: makeWeeklyForecastComponents(withCity: city))
  }

  func currentWeatherForecast(
    forCity city: String
  ) -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError> {
    return forecast(with: makeCurrentDayForecastComponents(withCity: city))
  }
  
  private func forecast<T>(
    with components: URLComponents
  ) -> AnyPublisher<T, WeatherError> where T: Decodable {
    // 1: Try to create an instance of URL from the URLComponents. If this fails, return an error wrapped in a Fail value. Then, erase its type to AnyPublisher, since that’s the method’s return type.
    guard let url = components.url else {
      let error = WeatherError.network(description: "Couldn't create URL")
      return Fail(error: error).eraseToAnyPublisher()
    }

    // 2: Uses the new URLSession method dataTaskPublisher(for:) to fetch the data. This method takes an instance of URLRequest and returns either a tuple (Data, URLResponse) or a URLError.
    return session.dataTaskPublisher(for: URLRequest(url: url))
      // 3: Because the method returns AnyPublisher<T, WeatherError>, you map the error from URLError to WeatherError.
      .mapError { error in
        .network(description: error.localizedDescription)
      }
      // 4: The uses of flatMap deserves a post of their own. Here, you use it to convert the data coming from the server as JSON to a fully-fledged object. You use decode(_:) as an auxiliary function to achieve this. Since you are only interested in the first value emitted by the network request, you set .max(1).
      .flatMap(maxPublishers: .max(1)) { pair in
        decode(pair.data)
      }
      // 5: If you don’t use eraseToAnyPublisher() you’ll have to carry over the full type returned by flatMap: Publishers.FlatMap<AnyPublisher<_, WeatherError>, Publishers.MapError<URLSession.DataTaskPublisher, WeatherError>>. As a consumer of the API, you don’t want to be burdened with these details. So, to improve the API ergonomics, you erase the type to AnyPublisher. This is also useful because adding any new transformation (e.g. filter) changes the returned type and, therefore, leaks implementation details.
      .eraseToAnyPublisher()
  }
  
}
