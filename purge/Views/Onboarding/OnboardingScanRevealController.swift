import Combine
import Foundation
import SwiftUI

@MainActor
final class OnboardingScanRevealController: ObservableObject {
  @Published private(set) var revealedItems: [OnboardingScanFinding] = []
  @Published private(set) var simulatedProgress: Double = 0
  @Published private(set) var isRevealComplete = false

  private var revealTask: Task<Void, Never>?
  private let placeholderQueue: [OnboardingScanFinding] = [
    OnboardingScanFinding(title: "Safari Caches", formattedSize: "1.2 GB"),
    OnboardingScanFinding(title: "Xcode DerivedData", formattedSize: "4.8 GB"),
    OnboardingScanFinding(title: "Docker build cache", formattedSize: "6.1 GB"),
    OnboardingScanFinding(title: "Chrome caches", formattedSize: "890 MB"),
    OnboardingScanFinding(title: "System logs", formattedSize: "420 MB"),
    OnboardingScanFinding(title: "npm caches", formattedSize: "2.3 GB"),
    OnboardingScanFinding(title: "Homebrew caches", formattedSize: "1.5 GB"),
    OnboardingScanFinding(title: "iOS Simulator data", formattedSize: "3.4 GB"),
  ]

  func startReveal(
    itemProvider: @escaping () -> [OnboardingScanFinding],
    scanFinished: @escaping () -> Bool,
    onReadyForResults: @escaping () -> Void
  ) {
    cancel()
    revealedItems = []
    simulatedProgress = 0
    isRevealComplete = false

    revealTask = Task {
      var queueIndex = 0
      let totalSteps = placeholderQueue.count

      while !Task.isCancelled {
        let realItems = itemProvider()
        let next: OnboardingScanFinding
        if queueIndex < realItems.count {
          next = realItems[queueIndex]
        } else if queueIndex < placeholderQueue.count {
          next = placeholderQueue[queueIndex]
        } else {
          break
        }

        let targetProgress = Double(queueIndex + 1) / Double(totalSteps)
        withAnimation(.easeOut(duration: 0.4)) {
          revealedItems.append(next)
        }
        withAnimation(.linear(duration: 0.55)) {
          simulatedProgress = targetProgress
        }
        queueIndex += 1

        if queueIndex >= totalSteps {
          isRevealComplete = true
          break
        }

        try? await Task.sleep(nanoseconds: 550_000_000)
      }

      withAnimation(.easeInOut(duration: 0.4)) {
        simulatedProgress = 1
      }
      isRevealComplete = true

      let deadline = Date().addingTimeInterval(30)
      while !Task.isCancelled && Date() < deadline {
        if scanFinished() {
          onReadyForResults()
          return
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
      }
      onReadyForResults()
    }
  }

  func cancel() {
    revealTask?.cancel()
    revealTask = nil
  }

  deinit {
    revealTask?.cancel()
  }
}
