import Foundation
import ServiceManagement

enum LoginItemRegistrar {
  static var isRegistered: Bool {
    if #available(macOS 13.0, *) {
      return SMAppService.mainApp.status == .enabled
    }
    return false
  }

  @discardableResult
  static func register() -> Bool {
    guard #available(macOS 13.0, *) else { return false }
    do {
      try SMAppService.mainApp.register()
      return SMAppService.mainApp.status == .enabled
    } catch {
      return false
    }
  }

  static func unregister() {
    guard #available(macOS 13.0, *) else { return }
    try? SMAppService.mainApp.unregister()
  }
}
