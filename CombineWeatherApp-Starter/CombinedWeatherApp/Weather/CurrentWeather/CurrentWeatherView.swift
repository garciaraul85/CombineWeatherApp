import SwiftUI

// You inject a ViewModel in the View and access its public API.
struct CurrentWeatherView: View {
  @ObservedObject var viewModel: CurrentWeatherViewModel

  init(viewModel: CurrentWeatherViewModel) {
    self.viewModel = viewModel
  }
  
  // You’ll notice the use of the onAppear(perform:) method. This takes a function of type () -> Void and executes it when the view appears. In this case, you call refresh() on the View Model so the dataSource can be refreshed.
  var body: some View {
    List(content: content)
      .onAppear(perform: viewModel.refresh)
      .navigationBarTitle(viewModel.city)
      .listStyle(GroupedListStyle())
  }
  
}

// This adds the remaining UI bits.
private extension CurrentWeatherView {
  func content() -> some View {
    if let viewModel = viewModel.dataSource {
      return AnyView(details(for: viewModel))
    } else {
      return AnyView(loading)
    }
  }

  func details(for viewModel: CurrentWeatherRowViewModel) -> some View {
    CurrentWeatherRow(viewModel: viewModel)
  }

  var loading: some View {
    Text("Loading \(viewModel.city)'s weather...")
      .foregroundColor(.gray)
  }
}
