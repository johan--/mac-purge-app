import Foundation

func displayDirectoryPath(for directoryURL: URL) -> String {
    let directory = directoryURL.standardizedFileURL
    let path = directory.path
    let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
    guard path.hasPrefix(home) else { return path }
    let remainder = String(path.dropFirst(home.count))
    if remainder.isEmpty { return "~" }
    return "~" + remainder
}
