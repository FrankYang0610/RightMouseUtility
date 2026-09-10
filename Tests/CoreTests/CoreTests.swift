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
        for kind in [FileKind.txt, .md] {
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

    func testPreservesBrokenSymbolicLink() throws {
        let destination = directory.appendingPathComponent("missing.txt")
        let link = directory.appendingPathComponent("Untitled.txt")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: destination)
        let next = try FileCreator.create(CreateRequest(target: directory, kind: .txt))
        XCTAssertEqual(next.lastPathComponent, "Untitled 2.txt")
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: link.path), destination.path)
    }

    func testCopiesWordTemplateWithoutOverwriting() throws {
        let template = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/Empty-DOCX.docx")
        let original = try Data(contentsOf: template)
        let request = CreateRequest(target: directory, kind: .docx)
        let first = try FileCreator.create(request, template: template)
        XCTAssertEqual(first.lastPathComponent, "Untitled.docx")
        XCTAssertEqual(try Data(contentsOf: first), original)

        let edited = Data("Keep this".utf8)
        try edited.write(to: first)
        let second = try FileCreator.create(request, template: template)
        XCTAssertEqual(second.lastPathComponent, "Untitled 2.docx")
        XCTAssertEqual(try Data(contentsOf: second), original)
        XCTAssertEqual(try Data(contentsOf: first), edited)
        XCTAssertEqual(try Data(contentsOf: template), original)
    }

    func testMissingWordTemplateFailsWithoutCreatingFile() {
        let request = CreateRequest(target: directory, kind: .docx)
        XCTAssertThrowsError(try FileCreator.create(request))
        XCTAssertThrowsError(try FileCreator.create(request, template: directory.appendingPathComponent("missing.docx")))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
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
        for kind in FileKind.allCases {
            let decoded = try XCTUnwrap(CreateRequest(url: CreateRequest(target: target, kind: kind).url))
            XCTAssertEqual(decoded.target.path, target.path)
            XCTAssertEqual(decoded.kind, kind)
        }
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
