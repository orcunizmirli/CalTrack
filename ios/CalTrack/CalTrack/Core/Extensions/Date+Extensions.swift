import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }

    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }

    var shortDate: String {
        formatted(as: "d MMM")
    }

    var fullDate: String {
        formatted(as: "d MMMM yyyy")
    }

    var dayOfWeek: String {
        formatted(as: "EEEE")
    }

    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self)!
    }

    static var today: Date {
        Date().startOfDay
    }

    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}

extension Double {
    var formattedCalorie: String {
        String(format: "%.0f", self)
    }

    var formattedMacro: String {
        String(format: "%.1f", self)
    }

    var formattedWeight: String {
        String(format: "%.1f", self)
    }

    var formattedPercentage: String {
        String(format: "%.1f%%", self)
    }
}
