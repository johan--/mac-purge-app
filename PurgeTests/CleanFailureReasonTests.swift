import Foundation
import Testing
@testable import purge

@Suite("CleanFailureReason error mapping")
struct CleanFailureReasonTests {
    @Test func dropsFileNotFoundPOSIX() {
        let error = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))
        #expect(CleanFailureReason.from(error: error) == nil)
    }

    @Test func dropsFileNotFoundCocoa() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError)
        #expect(CleanFailureReason.from(error: error) == nil)
    }

    @Test(arguments: [
        (NSPOSIXErrorDomain, Int(EACCES), CleanFailureReason.needsFullDiskAccess),
        (NSPOSIXErrorDomain, Int(EPERM), CleanFailureReason.needsFullDiskAccess),
        (NSPOSIXErrorDomain, Int(EBUSY), CleanFailureReason.inUse),
        (NSPOSIXErrorDomain, Int(EROFS), CleanFailureReason.systemProtected),
        (NSCocoaErrorDomain, NSFileWriteNoPermissionError, CleanFailureReason.needsFullDiskAccess),
        (NSCocoaErrorDomain, NSFileWriteVolumeReadOnlyError, CleanFailureReason.systemProtected),
    ])
    func mapsKnownErrors(domain: String, code: Int, expected: CleanFailureReason) {
        let error = NSError(domain: domain, code: code)
        #expect(CleanFailureReason.from(error: error) == expected)
    }

    @Test func mapsUnknownErrors() {
        let error = NSError(domain: "TestDomain", code: 999)
        #expect(CleanFailureReason.from(error: error) == .unknown)
    }
}

@Suite("TimeTagline fact part")
struct TimeTaglineFactPartTests {
    @Test func selectionExposesFactAndQuip() {
        let defaults = UserDefaults(suiteName: "TimeTaglineTests.fact")!
        defaults.removePersistentDomain(forName: "TimeTaglineTests.fact")

        let selection = TimeTagline.select(for: 2, defaults: defaults)
        #expect(selection.factPart == "done in 2 seconds")
        #expect(selection.line == "\(selection.factPart) · \(selection.quip)")
        #expect(TimeTagline.quips(for: 2).contains(selection.quip))
    }
}
