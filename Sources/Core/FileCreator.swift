import Darwin
import Foundation

enum FileCreator {
    static func create(_ request: CreateRequest) throws -> URL {
        let target = request.target
        guard target.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme) }
        let values = try target.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        let directory = values.isDirectory == true && values.isPackage != true
            ? target : target.deletingLastPathComponent()

        for number in 1...10_000 {
            let name = number == 1 ? "Untitled" : "Untitled \(number)"
            let file = directory.appendingPathComponent(name).appendingPathExtension(request.kind.rawValue)
            // Exclusive creation also protects existing files and symbolic links.
            let descriptor = file.withUnsafeFileSystemRepresentation {
                Darwin.open($0!, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0o666)
            }
            if descriptor >= 0 {
                Darwin.close(descriptor)
                return file
            }
            let code = errno
            if code != EEXIST {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [NSFilePathErrorKey: file.path])
            }
        }
        throw CocoaError(.fileWriteFileExists)
    }
}
