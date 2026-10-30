import Foundation
import XCTest

@testable import WealthOneCore

final class GoalDraftTests: XCTestCase {
  func testBirthRoundTripRestoresImportedRepresentationsAndAbsence() throws {
    for original: [String: Value] in [
      ["birthDate": .decimal(Decimal(string: "283564800000.125")!), "currentAge": .decimal(47)],
      ["birthDate": .string("1978-12-26")],
      [:],
    ] {
      var draft = GoalDraft(original: original)
      draft.setBirth(day: "1980-01-01", originalDisplayedDay: "1978-12-26", currentAge: 46)
      XCTAssertEqual(try draft.changes(currentAge: 46)["birthDate"], .string("1980-01-01"))
      draft.setBirth(day: "1978-12-26", originalDisplayedDay: "1978-12-26", currentAge: 47)
      XCTAssertTrue(try draft.changes(currentAge: 47).isEmpty)
      XCTAssertEqual(draft.original, original)
      XCTAssertFalse(draft.isDirty)
    }
  }
  func testContributionValidationTracksBothDirectionsOfEarningsChanges() throws {
    var draft = GoalDraft()
    draft.setText("12000", for: "earnings")
    draft.setText("2000.125", for: "contributions")
    XCTAssertEqual(draft.invalidKeys(currentAge: 47), ["contributions"])
    XCTAssertThrowsError(try draft.changes(currentAge: 47))
    draft.setText("36000", for: "earnings")
    XCTAssertTrue(draft.invalidKeys(currentAge: 47).isEmpty)
    XCTAssertEqual(
      try draft.changes(currentAge: 47)["contributions"], .decimal(Decimal(string: "2000.125")!))
    draft.setText("12000", for: "earnings")
    XCTAssertEqual(draft.invalidKeys(currentAge: 47), ["contributions"])
    XCTAssertThrowsError(try draft.changes(currentAge: 47))
  }
  func testRetirementValidationTracksAgeChangesAndReversion() throws {
    var draft = GoalDraft()
    draft.setText("50", for: "retirementAge")
    XCTAssertTrue(draft.invalidKeys(currentAge: 47).isEmpty)
    XCTAssertEqual(draft.invalidKeys(currentAge: 55), ["retirementAge"])
    XCTAssertThrowsError(try draft.changes(currentAge: 55))
    XCTAssertTrue(draft.invalidKeys(currentAge: 47).isEmpty)
    XCTAssertEqual(try draft.changes(currentAge: 47)["retirementAge"], .decimal(50))
  }
  func testDeletingAndRetypingEarningsAlwaysProducesLegalSliderConstraints() {
    var draft = GoalDraft(original: ["earnings": .decimal(55000), "contributions": .decimal(2000)])
    for text in [
      "5500", "550", "55", "5", "", "0", "6", "60", "600", "6000", "60000", "-", "invalid",
    ] {
      draft.setText(text, for: "earnings")
      let slider = draft.slider("contributions", fallback: 0, preferredStep: 50, currentAge: 47)
      XCTAssertTrue(slider.value.isFinite)
      XCTAssertTrue(slider.range.contains(slider.value))
      if let step = slider.step {
        XCTAssertGreaterThan(step, 0)
        XCTAssertLessThanOrEqual(step, slider.range.upperBound - slider.range.lowerBound)
      } else {
        XCTAssertEqual(slider.range.lowerBound, slider.range.upperBound)
      }
    }
    XCTAssertNil(draft.slider("retirementAge", fallback: 65, preferredStep: 1, currentAge: 75).step)
    XCTAssertNil(draft.slider("retirementAge", fallback: 65, preferredStep: 1, currentAge: 90).step)
  }
  func testZeroEarningsOnlyAllowsZeroContributionAndNoSlider() throws {
    var draft = GoalDraft()
    draft.setText("0", for: "earnings")
    draft.setText("1", for: "contributions")
    XCTAssertEqual(draft.invalidKeys(currentAge: 47), ["contributions"])
    XCTAssertThrowsError(try draft.changes(currentAge: 47))
    XCTAssertNil(draft.slider("contributions", fallback: 0, preferredStep: 50, currentAge: 47).step)
    draft.setText("0", for: "contributions")
    XCTAssertTrue(draft.invalidKeys(currentAge: 47).isEmpty)
    XCTAssertEqual(try draft.changes(currentAge: 47)["contributions"], .decimal(0))
  }
  func testBirthRoundTripSaveAndReopenKeepsOriginalStoredGoal() throws {
    let original: [String: Value] = [
      "birthDate": .string("1978-12-26"), "currentAge": .decimal(47),
      "earnings": .decimal(Decimal(string: "55000.123456789")!),
    ]
    let store = try EventStore()
    try store.replace(Snapshot(goal: original))
    var draft = GoalDraft(original: store.projection.snapshot.goal)
    draft.setBirth(day: "1960-01-01", originalDisplayedDay: "1978-12-26", currentAge: 66)
    draft.setText("50", for: "retirementAge")
    XCTAssertTrue(draft.invalidKeys(currentAge: 66).contains("retirementAge"))
    draft.setBirth(day: "1978-12-26", originalDisplayedDay: "1978-12-26", currentAge: 47)
    let changes = try draft.changes(currentAge: 47)
    XCTAssertEqual(changes, ["retirementAge": .decimal(50)])
    try store.append(
      .edit(.goal, generation: store.projection.generation(for: .goal)!, fields: changes))
    let reopened = try EventStore(envelope: store.envelope)
    XCTAssertEqual(reopened.projection.snapshot.goal["birthDate"], original["birthDate"])
    XCTAssertEqual(reopened.projection.snapshot.goal["currentAge"], original["currentAge"])
    XCTAssertEqual(reopened.projection.snapshot.goal["earnings"], original["earnings"])
    XCTAssertEqual(reopened.projection.snapshot.goal["retirementAge"], .decimal(50))
  }
  func testUntouchedImportedValuesRemainUnchangedOutsideEditorRanges() throws {
    let original: [String: Value] = [
      "earnings": .decimal(Decimal(string: "250000.123456789")!),
      "contributions": .decimal(Decimal(string: "17000.123456789")!),
      "retirementAge": .decimal(90), "pension": .decimal(Decimal(string: "12.3456789")!),
    ]
    var draft = GoalDraft(original: original)
    XCTAssertTrue(draft.invalidKeys(currentAge: 47).isEmpty)
    _ = draft.slider("contributions", fallback: 0, preferredStep: 50, currentAge: 47)
    XCTAssertTrue(try draft.changes(currentAge: 47).isEmpty)
    draft.setText("40", for: "lifeStyle")
    XCTAssertEqual(try draft.changes(currentAge: 47), ["lifeStyle": .decimal(40)])
    XCTAssertEqual(draft.original, original)
  }
}
