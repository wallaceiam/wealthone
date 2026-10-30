import Foundation
import WealthOneCore

actor ExchangeRateProvider {
  private var cached: (date: Date, quote: ExchangeRateQuote)?
  func quote(refresh: Bool = false) async throws -> ExchangeRateQuote {
    if !refresh, let cached, Date().timeIntervalSince(cached.date) < 3600 { return cached.quote }
    let url = URL(string: "https://www.bankofcanada.ca/valet/observations/group/FX_RATES_DAILY/json?recent=1")!
    var request = URLRequest(url: url)
    request.timeoutInterval = 20
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw CoreError.invalid("Exchange rates could not be fetched. Enter a manual rate or try again.")
    }
    let quote = try ExchangeRateQuote.bankOfCanada(data)
    cached = (Date(), quote)
    return quote
  }
}
