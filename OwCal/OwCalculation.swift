//
//  OwCalculation.swift
//  OwCal
//
//  Created by dog on 2024/7/29.
//

import Foundation

func isValidTimeFormat(_ time: String) -> Bool {
    let timeRegex = "^([01][0-9]|2[0-3])[0-5][0-9]$"
    let timePredicate = NSPredicate(format:"SELF MATCHES %@", timeRegex)
    return timePredicate.evaluate(with: time)
}

func calWeekdayOWTime(xiaBanTime: String, banBie: String) -> Int? {
    if !isValidTimeFormat(xiaBanTime) {
        return 0
    }
    // 定义开始时间字符串
    let startTimeString: String
    switch banBie {
    case "D":
        startTimeString = "1730"
    case "T":
        startTimeString = "1830"
    default:
        return nil // 如果banBie不是D/T，返回nil表示错误
    }
    
    // 创建DateFormatter
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HHmm"
    
    // 使用guard语句解析时间字符串
    guard let startTime = dateFormatter.date(from: startTimeString),
          let endTime = dateFormatter.date(from: xiaBanTime) else {
        return nil // 如果无法解析时间字符串，返回nil表示错误
    }
    
    // 检查下班时间是否早于规定的开始时间
    if endTime < startTime {
        return 0
    }
    
    // 计算时间差
    let calendar = Calendar.current
    let components = calendar.dateComponents([.minute], from: startTime, to: endTime)
    return components.minute // 如果 components.minute 为 nil，将会返回 nil
}

func calWeekendHolidayOWTime(shBanTime: String, xiaBanTime: String, banBie: String) -> Int? {
    if !isValidTimeFormat(shBanTime) || !isValidTimeFormat(xiaBanTime) {
        return 0
    }
    
    // Helper function to convert time string to Date
    func timeStringToDate(_ time: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        return dateFormatter.date(from: time)
    }
    
    // Helper function to calculate minutes between two time strings
    func minutesBetween(start: String, end: String) -> Int? {
        guard let startDate = timeStringToDate(start), let endDate = timeStringToDate(end) else {
            return nil // 转换失败时返回nil
        }
        return Int(endDate.timeIntervalSince(startDate) / 60)
    }
    
    // Guard statements to ensure shBanTime and xiaBanTime can be converted to integers
    guard let shBanTimeInt = Int(shBanTime), let xiaBanTimeInt = Int(xiaBanTime) else {
        return nil // 解析失败时返回nil
    }
    
    // Constants for time strings
    let time0900 = "0900"
    let time1300 = "1300"
    let time1400 = "1400"
    let time1800 = "1800"
    let time1830 = "1830"
    let time0800 = "0800"
    let time1200 = "1200"
    let time1700 = "1700"
    let time1730 = "1730"
    
    switch banBie {
    case "T":
        switch shBanTimeInt {
        case ..<900:
            if xiaBanTimeInt < 900 {
                return 0
            } else if xiaBanTimeInt < 1300 {
                return minutesBetween(start: time0900, end: xiaBanTime)
            } else if xiaBanTimeInt < 1400 {
                return 320
            } else if xiaBanTimeInt < 1800 {
                return minutesBetween(start: time0900, end: xiaBanTime)?.advanced(by: -60)
            } else if xiaBanTimeInt < 1830 {
                return 480
            } else {
                return minutesBetween(start: time0900, end: xiaBanTime)?.advanced(by: -90)
            }
        case ..<1300:
            if xiaBanTimeInt < 1300 {
                return minutesBetween(start: shBanTime, end: xiaBanTime)
            } else if xiaBanTimeInt < 1400 {
                return minutesBetween(start: shBanTime, end: time1300)
            } else if xiaBanTimeInt < 1800 {
                return minutesBetween(start: shBanTime, end: xiaBanTime)?.advanced(by: -60)
            } else if xiaBanTimeInt < 1830 {
                return minutesBetween(start: shBanTime, end: time1800)?.advanced(by: -60)
            } else {
                return minutesBetween(start: shBanTime, end: xiaBanTime)?.advanced(by: -90)
            }
        case ..<1400:
            if xiaBanTimeInt < 1400 {
                return 0
            } else if xiaBanTimeInt < 1800 {
                return minutesBetween(start: time1400, end: xiaBanTime)
            } else if xiaBanTimeInt < 1830 {
                return 240
            } else {
                return minutesBetween(start: time1400, end: xiaBanTime)?.advanced(by: -30)
            }
        case ..<1800:
            if xiaBanTimeInt < 1800 {
                return minutesBetween(start: shBanTime, end: xiaBanTime)
            } else if xiaBanTimeInt < 1830 {
                return minutesBetween(start: shBanTime, end: time1800)
            } else {
                return minutesBetween(start: shBanTime, end: xiaBanTime)?.advanced(by: -30)
            }
        case ..<1830:
            if xiaBanTimeInt < 1830 {
                return 0
            } else {
                return minutesBetween(start: time1830, end: xiaBanTime)
            }
        default:
            return minutesBetween(start: shBanTime, end: xiaBanTime)
        }
        
    case "D":
        switch shBanTimeInt {
        case ..<800:
            if xiaBanTimeInt < 800 {
                return 0
            } else if xiaBanTimeInt < 1200 {
                return minutesBetween(start: time0800, end: xiaBanTime)
            } else if xiaBanTimeInt < 1300 {
                return 320
            } else if xiaBanTimeInt < 1700 {
                return minutesBetween(start: time0800, end: xiaBanTime)?.advanced(by: -60)
            } else if xiaBanTimeInt < 1730 {
                return 480
            } else {
                return minutesBetween(start: time0800, end: xiaBanTime)?.advanced(by: -90)
            }
        case ..<1200:
            if xiaBanTimeInt < 1200 {
                return minutesBetween(start: shBanTime, end: xiaBanTime)
            } else if xiaBanTimeInt < 1300 {
                return minutesBetween(start: shBanTime, end: time1200)
            } else if xiaBanTimeInt < 1700 {
                return minutesBetween(start: shBanTime, end: xiaBanTime)?.advanced(by: -60)
            } else if xiaBanTimeInt < 1730 {
                return minutesBetween(start: shBanTime, end: time1700)?.advanced(by: -60)
            } else {
                return minutesBetween(start: shBanTime, end: xiaBanTime)?.advanced(by: -90)
            }
        case ..<1300:
            if xiaBanTimeInt < 1300 {
                return 0
            } else if xiaBanTimeInt < 1700 {
                return minutesBetween(start: time1300, end: xiaBanTime)
            } else if xiaBanTimeInt < 1730 {
                return 240
            } else {
                return minutesBetween(start: time1300, end: xiaBanTime)?.advanced(by: -30)
            }
        case ..<1700:
            if xiaBanTimeInt < 1700 {
                return minutesBetween(start: shBanTime, end: xiaBanTime)
            } else if xiaBanTimeInt < 1730 {
                return minutesBetween(start: shBanTime, end: time1700)
            } else {
                return minutesBetween(start: shBanTime, end: xiaBanTime)?.advanced(by: -30)
            }
        case ..<1730:
            if xiaBanTimeInt < 1730 {
                return 0
            } else {
                return minutesBetween(start: time1730, end: xiaBanTime)
            }
        default:
            return minutesBetween(start: shBanTime, end: xiaBanTime)
        }
        
    default:
        return nil // banBie不是D/T时返回nil
    }
}
