//
//  OwHandle.swift
//  OwCal
//
//  Created by dog on 2024/7/29.
//

import Foundation
import AppKit

// 获取CheckBox的UserDefaults的值或默认值
func getStateValue(forKey key: String, defaultValue: Int = 1) -> NSControl.StateValue {
    let defaults = UserDefaults.standard
    if let value = defaults.object(forKey: key) as? Int {
        return .init(rawValue: value)
    } else {
        return .init(rawValue: defaultValue)
    }
}

func owHandle() -> (String, String, String) {
    var fullTitle = "[***]"
    var owDataStr = ""
    let defaults = UserDefaults.standard
    
    guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty else {
        return ("[请设置工号]", "", "")
    }
    guard let hrPwd = defaults.string(forKey: "secureTextField"), !hrPwd.isEmpty else {
        return ("[请设置密码]", "", "")
    }
    
    let upLimit = defaults.string(forKey: "upperLimit") ?? "60"
    let fileManager = FileManager.default
    let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
    let folderPath = defaults.string(forKey: "folderPath") ?? desktopURL.appendingPathComponent("加班历史记录").path
    
    DispatchQueue.global(qos: .background).async {
        let autoNet = getStateValue(forKey: "autoNet")
        if autoNet.rawValue == 1 {
            networkAuth(id: empID, pwd: hrPwd)
        }
    }
    
    guard let rawExecutablePath = Bundle.main.path(forResource: ".test.data", ofType: nil) else {
//        print("无法找到二进制可执行文件")
        return ("[找不到数据文件]", "", "")
    }
    let executablePath = rawExecutablePath.replacingOccurrences(of: " ", with: "\\ ")
    
    var mealTitle = "[报餐 U]"
    DispatchQueue.global(qos: .background).async {
        let autoMeal = getStateValue(forKey: "autoMeal")
        if autoMeal.rawValue == 1 {
            mealTitle = "[报餐 " + mealEat(id: empID, pwd: hrPwd, execFilePath: executablePath) + "]"
        }
        DispatchQueue.main.async {
            if let appDelegate = NSApp.delegate as? AppDelegate, let button = appDelegate.statusItem?.button {
                if button.title.contains("[报餐 U]") {
                    button.title = button.title.replacingOccurrences(of: "[报餐 U]", with: mealTitle)
                }
            }
        }
    }
    
    let saveHistory = getStateValue(forKey: "saveHistory")
    let isCalToday = getStateValue(forKey: "isCalToday")
    
//    let jiaBanHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "cat $HOME/Desktop/加班申请.html"]).1
    let jiaBanHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", executablePath + " \(empID) '\(hrPwd)' get 'http://hr.rsquanta.com/QSMCHR/Attn/Modify_Attandence_Assistant_Min.aspx?Flag=4&languageType=zh-CN' | base64 -d"]).1
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    let formattedDate = dateFormatter.string(from: Date())
    let currentDay = formattedDate.suffix(2)
    
    if jiaBanHtml.contains("楼上考勤卡机不区分上") {
        if currentDay == "26" {
            DispatchQueue.global(qos: .background).async {
                if saveHistory.rawValue == 1 {
                    let filePath = URL(fileURLWithPath: folderPath).appendingPathComponent("\(formattedDate)_Record.html")
                    if !fileManager.fileExists(atPath: filePath.path) {
                        do {
                            try jiaBanHtml.write(to: filePath, atomically: true, encoding: .utf8)
    //                        print("解码后的内容已写入到 \(filePath.path)")
                        } catch {
    //                        print("写入文件时发生错误: \(error)")
                        }
                    }
                }                
            }
        }
        
        // 分析加班数据
        var totalOwMin = 0
        var v_totalOwMin = 0
        
        do {
            let gvAttnDoc: Document = try parse(jiaBanHtml)
            let gvAttnTable = try gvAttnDoc.select("table#gvAttn").first()!
            let gvAttnRows = try gvAttnTable.select("tr")
            let owCsvPath = URL(fileURLWithPath: desktopURL.absoluteString).appendingPathComponent("ow.csv")
            var titleShBan = "----"
            
            for i in 1..<gvAttnRows.size() {
                let gvAttnRow = gvAttnRows.get(i)
                let gvAttnCells = try gvAttnRow.select("td")
                
                if try gvAttnCells.get(3).text().hasSuffix("25") && i != 1 && i != 2 {
                    break
                }
                
                if try gvAttnCells.get(4).text().isEmpty {
                    if  try gvAttnCells.get(13).text().contains(":") {
                        try gvAttnCells.get(4).text(gvAttnCells.get(13).select("[id$='_gvtxtStrehrTime']").get(0).attr("value"))
                    } else {
                        try gvAttnCells.get(4).text(gvAttnCells.get(13).text())
                    }
                }
                
                if try gvAttnCells.get(5).text().isEmpty {
                    if  try gvAttnCells.get(14).text().contains(":") {
                        try gvAttnCells.get(5).text(gvAttnCells.get(14).select("[id$='_gvtxtEnrehrTime']").get(0).attr("value"))
                    } else {
                        try gvAttnCells.get(5).text(gvAttnCells.get(14).text())
                    }
                }
                
                if i == 1 {
                    if try gvAttnCells.get(4).text().isEmpty {
                        DispatchQueue.global(qos: .background).async {
                            do {
                                var onclickShBan = "----"
                                let onclickHtml = try gvAttnCells.get(3).select("span").first()!
                                let onclickURL = try onclickHtml.attr("onclick").split(separator: "'")[1]
                                let shangBanHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", executablePath + " \(empID) '\(hrPwd)' get 'http://hr.rsquanta.com/QSMCHR/Attn/\(onclickURL)' | base64 -d"]).1
                                //                            let shangBanHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "cat $HOME/Desktop/刷卡记录查询.html"]).1
                                let gvRderDoc: Document = try parse(shangBanHtml)
                                // 使用选择器选择包含特定日期的 tr 元素
                                let selector = "tr:contains(\(try gvAttnCells.get(3).text()))"
                                let elements = try gvRderDoc.select(selector)
                                var faceTime = "----"
                                for element in elements.array() {
                                    if try element.text().contains("人脸识别刷卡") {
                                        faceTime = try element.select("td").get(2).text()
                                    }
                                    
                                    if try element.text().contains("考勤机刷卡") && faceTime != "----" {
                                        onclickShBan = try element.select("td").get(2).text()
                                        break
                                    }
                                }
                                DispatchQueue.main.async {
                                    if let appDelegate = NSApp.delegate as? AppDelegate, let button = appDelegate.statusItem?.button {
                                        if button.title.contains("[上班 --:--]") {
                                            onclickShBan = "[上班 " + onclickShBan.prefix(2) + ":" + onclickShBan.suffix(2) + "]"
                                            button.title = button.title.replacingOccurrences(of: "[上班 --:--]", with: onclickShBan)
                                        }
                                    }
                                }
                            } catch {
                                print("捕获到错误: \(error)")
                            }
                        }
                    } else {
                        titleShBan = try gvAttnCells.get(4).text()
                    }
                    
                    try "日期,上班,下班,迟到,班别,请假,加班a,加班v,🏡🔧v\n".write(to: owCsvPath, atomically: true, encoding: .utf8)
                    
                    if isCalToday.rawValue == 0 {
                        continue
                    }
                    
                    if try gvAttnCells.get(3).text().hasSuffix("26") {
                        continue
                    }
                }
                
                if try !gvAttnCells.get(4).text().isEmpty || gvAttnCells.get(12).text() == "Y" {
                    var v_total_lev = 0
                    var owTime: Int
                    var lateTime = try gvAttnCells.get(6).text()
                    
                    if try gvAttnCells.get(12).text() == "Y" {
                        let levHtml = try run_shell(launchPath: "/bin/bash", arguments: ["-c", executablePath + " \(empID) '\(hrPwd)' get 'http://hr.rsquanta.com/QSMCHR/Attn/View_Leav.aspx?emplid=\(empID)&wrkdat=\(gvAttnCells.get(3).text())' | base64 -d"]).1
                        let gvLeavDoc = try parse(levHtml)
                        let gvLeavTable = try gvLeavDoc.select("table#gvLeav").first()!
                        let gvLeavRows = try gvLeavTable.select("tr")
                        
                        for j in 1..<gvLeavRows.size() {
                            let gvLeavRow = gvLeavRows.get(j)
                            let gvLeavCells = try gvLeavRow.select("td")
                            if try (gvLeavCells.get(3).text() == "0800" && gvAttnCells.get(7).text() == "D") || (gvLeavCells.get(3).text() == "0900" && gvAttnCells.get(7).text() == "T") {
                                lateTime = "0"
                            }
                            if try !gvLeavRow.text().contains("公假") && !gvLeavRow.text().contains("年休假") && !gvLeavRow.text().contains("补休假") && !gvLeavRow.text().contains("保健假") {
                                guard let leavTime = Double(try gvLeavCells.get(7).text()) else {
                                    return ("[无法识别\(try gvAttnCells.get(3).text())请假状况]", "", "")
                                }
                                v_total_lev += Int(leavTime * 60)
                            }
                        }
                    }
                    
                    if try gvAttnRow.attr("style").contains("White") || gvAttnRow.attr("style").contains("#EFF3FB") {
                        if let weekdayOwTime = calWeekdayOWTime(xiaBanTime: try gvAttnCells.get(5).text(), banBie: try gvAttnCells.get(7).text()) {
                            owTime = weekdayOwTime
                        } else {
                            return ("[计算\(try gvAttnCells.get(3).text())加班出错]", "", "")
                        }
                    } else if try gvAttnRow.attr("style").contains("Pink") || gvAttnRow.attr("style").contains("Yellow") {
                        if let weekendHolidayOwTime = calWeekendHolidayOWTime(shBanTime: try gvAttnCells.get(4).text(), xiaBanTime: try gvAttnCells.get(5).text(), banBie: try gvAttnCells.get(7).text()) {
                            owTime = weekendHolidayOwTime
                        } else {
                            return ("[计算\(try gvAttnCells.get(3).text())加班出错]", "", "")
                        }
                    } else {
                        return ("[无法识别\(try gvAttnCells.get(3).text())是平时还是节假日]", "", "")
                    }
                    
                    guard let lateTimeInt = Int(lateTime) else {
                        return ("[无法识别\(try gvAttnCells.get(3).text())迟到状况]", "", "")
                    }
                    let v_owTime = owTime - lateTimeInt - v_total_lev
                    
                    totalOwMin += owTime
                    v_totalOwMin += v_owTime
                    let today_vOwHour = String(format: "%.2f", floor(Double(v_owTime) / 60 * 100) / 100)
                    
                    let leavTitle = v_total_lev == 0 ? "" : String(Double(v_total_lev)/60)
                    let owResultRow = try "\(gvAttnCells.get(3).text()),\(gvAttnCells.get(4).text()),\(gvAttnCells.get(5).text()),\(lateTime),\(gvAttnCells.get(7).text()),\(leavTitle),\(owTime),\(v_owTime),\(today_vOwHour)\n"
//                    print(owResultRow, terminator: "")
                    
                    if let csvContent = try? String(contentsOf: owCsvPath, encoding: .utf8) {
                        let csvNewContent = csvContent + owResultRow
                        try csvNewContent.write(to: owCsvPath, atomically: true, encoding: .utf8)
                    } else {
//                        print("无法读取文件内容")
                    }
                }
            }
            
            if let csvContent = try? String(contentsOf: owCsvPath, encoding: .utf8) {
                let totalOwHour = String(format: "%.2f", floor(Double(totalOwMin) / 60 * 100) / 100)
                let v_totalOwHour = String(format: "%.2f", floor(Double(v_totalOwMin) / 60 * 100) / 100)
                let csvNewContent = csvContent + "总加班,,,,,,\(totalOwHour),\(v_totalOwMin),\(v_totalOwHour)"
                owDataStr = csvNewContent
                if currentDay == "26" {
                    DispatchQueue.global(qos: .background).async {
                        if saveHistory.rawValue == 1 {
                            let filePath = URL(fileURLWithPath: folderPath).appendingPathComponent("\(formattedDate)_ow.csv")
                            if !fileManager.fileExists(atPath: filePath.path) {
                                do {
                                    try csvNewContent.write(to: filePath, atomically: true, encoding: .utf8)
            //                        print("解码后的内容已写入到 \(filePath.path)")
                                } catch {
            //                        print("写入文件时发生错误: \(error)")
                                }
                            }
                        }
                    }
                }
                try csvNewContent.write(to: owCsvPath, atomically: true, encoding: .utf8)
//                print("总加班: \(totalOwMin), 总有效加班: \(v_totalOwMin)")
            }
            
            titleShBan = "[上班 " + titleShBan.prefix(2) + ":" + titleShBan.suffix(2) + "]"
            let isShowShBan = getStateValue(forKey: "shangBan")
            if isShowShBan.rawValue == 0 {
                titleShBan = ""
            }
            let stringOwTime = String(format: "%.2f", floor(Double(v_totalOwMin) / 60 * 100) / 100)
            var titleOwTime = "[加班 " + stringOwTime + "H]"
            let isShowJiaBan = getStateValue(forKey: "jiaBan")
            if isShowJiaBan.rawValue == 0 {
                titleOwTime = ""
            }
            
            let restOwTime = round(((Double(upLimit) ?? 60) - (Double(stringOwTime) ?? 0)) * 100) / 100
            var titleRestOwTime = "[剩余 " + String(restOwTime) + "H]"
            let isShowRest = getStateValue(forKey: "shengYu")
            if isShowRest.rawValue == 0 {
                titleRestOwTime = ""
            }
            
            let isShowMeal = getStateValue(forKey: "meal")
            if isShowMeal.rawValue == 0 {
                mealTitle = ""
            }

            fullTitle = "\(titleShBan) \(titleOwTime) \(titleRestOwTime) \(mealTitle)"
        } catch {
//            print("解析或计算加班数据时出错: \(error)")
        }
        
    } else {
        fullTitle = "[无法访问加班页面]"
    }
    
    return (fullTitle, jiaBanHtml, owDataStr)
}
