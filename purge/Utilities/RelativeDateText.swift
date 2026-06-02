import Foundation

func relativeDateText(for date: Date, referenceDate: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDate(date, inSameDayAs: referenceDate) {
        return "Today"
    }
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate),
       calendar.isDate(date, inSameDayAs: tomorrow) {
        return "Tomorrow"
    }
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate),
       calendar.isDate(date, inSameDayAs: yesterday) {
        return "Yesterday"
    }

    let relative = relativeDateFormatter.localizedString(for: date, relativeTo: referenceDate)
    guard let first = relative.first else { return relative }
    return first.uppercased() + String(relative.dropFirst())
}

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    formatter.formattingContext = .beginningOfSentence
    return formatter
}()
