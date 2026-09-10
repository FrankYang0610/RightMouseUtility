import Foundation
import XCTest
@testable import RightMouseCore

final class CoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testCreatesEmptyFiles() throws {
        for kind in FileKind.allCases {
            let file = try FileCreator.create(CreateRequest(target: directory, kind: kind))
            XCTAssertEqual(file.lastPathComponent, "Untitled.\(kind.rawValue)")
            XCTAssertEqual(try Data(contentsOf: file), Data())
        }
    }

    func testPreservesExistingFile() throws {
        let first = directory.appendingPathComponent("Untitled.txt")
        try Data("Keep this".utf8).write(to: first)
        let next = try FileCreator.create(CreateRequest(target: directory, kind: .txt))
        XCTAssertEqual(next.lastPathComponent, "Untitled 2.txt")
        XCTAssertEqual(try String(contentsOf: first), "Keep this")
    }

    func testPreservesSymbolicLink() throws {
        let destination = directory.appendingPathComponent("source.txt")
        try Data("Keep this".utf8).write(to: destination)
        let link = directory.appendingPathComponent("Untitled.txt")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: destination)
        let next = try FileCreator.create(CreateRequest(target: directory, kind: .txt))
        XCTAssertEqual(next.lastPathComponent, "Untitled 2.txt")
        XCTAssertEqual(try String(contentsOf: destination), "Keep this")
    }

    func testCreatesBesideSelectedFile() throws {
        let selected = directory.appendingPathComponent("notes.txt")
        try Data().write(to: selected)
        let file = try FileCreator.create(CreateRequest(target: selected, kind: .md))
        XCTAssertEqual(file.deletingLastPathComponent().path, directory.path)
    }

    func testMissingTargetFails() {
        let target = directory.appendingPathComponent("missing")
        XCTAssertThrowsError(try FileCreator.create(CreateRequest(target: target, kind: .txt)))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testRequestRoundTrip() throws {
        let target = directory.appendingPathComponent("A & B #100% + \u{1F4C4}")
        let decoded = try XCTUnwrap(CreateRequest(url: CreateRequest(target: target, kind: .md).url))
        XCTAssertEqual(decoded.target.path, target.path)
        XCTAssertEqual(decoded.kind, .md)
    }

    func testRejectsInvalidRequests() {
        for value in [
            "https://create?target=/tmp&type=txt",
            "rightmouseutility://delete?target=/tmp&type=txt",
            "rightmouseutility://create?target=relative&type=txt",
            "rightmouseutility://create?target=/tmp&type=exe",
            "rightmouseutility://create?target=/tmp&type=txt&type=md",
            "rightmouseutility://create?target=/tmp%00hidden&type=txt"
        ] {
            XCTAssertNil(CreateRequest(url: URL(string: value)!))
        }
    }
}
