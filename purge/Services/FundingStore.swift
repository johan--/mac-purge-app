import Combine
import Foundation

struct FundingInfo: Codable {
    var raised: Double
    var goal: Double
    var currency: String
    var paymentURL: String
    var signed: Bool
}

@MainActor
final class FundingStore: ObservableObject {
    @Published private(set) var info: FundingInfo

    private static let remoteURL = URL(string: "https://raw.githubusercontent.com/jithinsabumec/purge-app/main/funding.json")!

    init() {
        if let url = Bundle.main.url(forResource: "funding", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let bundled = try? JSONDecoder().decode(FundingInfo.self, from: data) {
            info = bundled
        } else {
            info = FundingInfo(
                raised: 0,
                goal: 99,
                currency: "USD",
                paymentURL: "",
                signed: false
            )
        }
    }

    var isComplete: Bool {
        info.signed || info.raised >= info.goal
    }

    var progress: Double {
        info.goal <= 0 ? 1 : min(max(info.raised / info.goal, 0), 1)
    }

    func refresh() async {
        do {
            var request = URLRequest(url: Self.remoteURL)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            info = try JSONDecoder().decode(FundingInfo.self, from: data)
        } catch {
            // Keep bundled value on any failure.
        }
    }
}
