import XCTest
@testable import WealthOneCore

final class AccountProviderGroupTests: XCTestCase {
  func testProviderGroupsCollapseCaseAndWhitespaceAndSortAccountsNaturally() {
    let accounts = [
      Account(id: "10", name: "Account 10", provider: "  Main   Bank "),
      Account(id: "2", name: "Account 2", provider: "main bank"),
      Account(id: "b", name: "Brokerage", provider: "Broker"),
      Account(id: "none", name: "Cash", provider: "  "),
    ]
    let groups = AccountProviderGroup.make(accounts)
    XCTAssertEqual(groups.map(\.provider), ["Broker", "Main Bank", "Other accounts"])
    XCTAssertEqual(groups[1].accounts.map(\.id), ["2", "10"])
    XCTAssertEqual(Set(groups.flatMap(\.accounts).map(\.id)), Set(accounts.map(\.id)))
    XCTAssertEqual(Set(groups.map(\.id)).count, 3)
    XCTAssertEqual(accounts[0].provider, "  Main   Bank ", "Presentation does not alter stored metadata")
  }
  func testEmptyGroupsAndClosedAccountSelectionKeepEntryEligibility() {
    XCTAssertTrue(AccountProviderGroup.make([]).isEmpty)
    let snapshot = Snapshot(accounts: [
      Account(id: "open", name: "Open", provider: "Bank"),
      Account(id: "closed", name: "Closed", provider: "Bank", closureDates: ["2025-01-01": true]),
    ])
    let groups = AccountProviderGroup.make(snapshot.openAccounts(on: "2025-02-01"))
    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[0].accounts.map(\.id), ["open"])
  }
}
