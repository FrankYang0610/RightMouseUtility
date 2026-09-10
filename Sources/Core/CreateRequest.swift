import Foundation

enum FileKind: String, CaseIterable {
    case txt, md

    var title: String { self == .txt ? "New TXT File" : "New Markdown File" }
}

struct CreateRequest {
    let target: URL
    let kind: FileKind

    init(target: URL, kind: FileKind) {
        self.target = target
        self.kind = kind
    }

    init?(url: URL) {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "rightmouseutility", parts.host == "create",
              let items = parts.queryItems, items.count == 2,
              let path = items.first(where: { $0.name == "target" })?.value,
              path.hasPrefix("/"), !path.utf8.contains(0),
              let type = items.first(where: { $0.name == "type" })?.value,
              let kind = FileKind(rawValue: type) else { return nil }
        self.init(target: URL(fileURLWithPath: path), kind: kind)
    }

    var url: URL {
        var parts = URLComponents()
        parts.scheme = "rightmouseutility"
        parts.host = "create"
        parts.queryItems = [
            URLQueryItem(name: "target", value: target.path),
            URLQueryItem(name: "type", value: kind.rawValue)
        ]
        return parts.url!
    }
}
