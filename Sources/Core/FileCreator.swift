import Foundation

enum FileCreator {
    static func create(_ request: CreateRequest, template: URL? = nil) throws -> URL {
        let target = request.target
        guard target.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme) }
        let values = try target.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        let directory = values.isDirectory == true && values.isPackage != true
            ? target : target.deletingLastPathComponent()
        let data: Data
        if request.kind == .docx {
            guard let template else {
                throw CocoaError(.fileReadNoSuchFile, userInfo: [
                    NSLocalizedDescriptionKey: "The Word template is missing. Rebuild the app."
                ])
            }
            data = try Data(contentsOf: template)
        } else {
            data = Data()
        }

        for number in 1...10_000 {
            let name = number == 1 ? "Untitled" : "Untitled \(number)"
            let file = directory.appendingPathComponent(name).appendingPathExtension(request.kind.rawValue)
            do {
                try data.write(to: file, options: .withoutOverwriting)
                return file
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                continue
            }
        }
        throw CocoaError(.fileWriteFileExists)
    }
}
