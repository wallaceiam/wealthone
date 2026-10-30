import Foundation
import XCTest
@testable import WealthOneCore

final class LegacyReduxDecoderTests: XCTestCase {
    func testInstalledLZStringReduxFixturePreservesUnicodeAndDecimals() throws {
        let data = Data(base64Encoded: "eyJwb3J0Zm9saW8iOiJcIuGvoeChgeSGrOGEltaQ4bag4rim46Kg4rij45Wg4pag4pyPyKDhqLHnhqDhm6DipqHGtOaApuebvsSG5pCg4Yir5oO84Luz5bmELm7moq3jpYjQsMiz3qDgtovmtrlA5aWS4pWk55KozoLiorTkhqDkoqDVoOGPr+WquuC6nOOQoeCxhOaTiuahkuOWj+GTheK1puWbqsOe5ryh46mExargsKDlnLXgpqrXo8mD5LGgbCbhsaDhpqDgraDkoKPjj4fitKzgpKnjkZzkhaLigK7knrDkoKLmrJLhh4HgooA746G20K9m2IDlh6Hhh7HlmYnmiqDgrKDhlr/miaTmgKPhp7figKHmuq3CsOGxguGyiuONn+eckiAgXCIiLCJnb2FsIjoiXCLhr6HgoKPkhazegOacpOWgvuaUsNeg4oyg5LCh5YKg4a2YzZDkgZLkgLfCvuWxheKAqybDnuKAoCBcIiJ9")!
        let snapshot = try LegacyReduxDecoder.decode(String(decoding: data, as: UTF8.self))
        XCTAssertEqual(snapshot.accounts.first?.name, "Savings 💷")
        XCTAssertEqual(snapshot.records.first?.totals["a"], Decimal(string: "123.45"))
    }
    func testMalformedCompressedDataThrows() {
        XCTAssertThrowsError(try LegacyReduxDecoder.decode("{\"portfolio\":\"bad compressed data\"}"))
    }
}
