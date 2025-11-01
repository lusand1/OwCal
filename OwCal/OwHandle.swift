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

func owHandle() -> String {
    var fullTitle = "[***]"
    let defaults = UserDefaults.standard
    
    guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty else {
        return "[请设置工号]"
    }
    guard let hrPwd = defaults.string(forKey: "secureTextField"), !hrPwd.isEmpty else {
        return "[请设置密码]"
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
    
    let saveHistory = getStateValue(forKey: "saveHistory")
    let isCalToday = getStateValue(forKey: "isCalToday")
    
//    let jiaBanHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "cat $HOME/Desktop/加班申请.html"]).1
    if let pythonPath = UserDefaults.standard.string(forKey: "pythonPath") {
        let ntlm_crawler = """
\"import sys
import json
import base64
import requests
import subprocess  # 用于执行系统命令
from requests_ntlm import HttpNtlmAuth

def get_chrome_version():
    '''通过系统命令获取Chrome版本，失败则返回默认值'''
    try:
        # macOS下读取Chrome版本的defaults命令
        result = subprocess.run(
            ['/usr/bin/defaults', 'read', '/Applications/Google Chrome.app/Contents/Info.plist', 'CFBundleShortVersionString'],
            capture_output=True,
            text=True,
            check=True
        )
        # 提取主版本号（如从'142.0.7356.109'提取'142'）
        full_version = result.stdout.strip()
        main_version = full_version.split('.')[0]
        return f'{main_version}.0.0.0'  # 拼接成142.0.0.0格式
    except Exception:
        # 任何错误都返回默认版本
        return '141.0.0.0'

# 动态生成请求头（包含真实Chrome版本）
def get_browser_headers():
    chrome_version = get_chrome_version()
    return {
        'User-Agent': f'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{chrome_version} Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1'
    }

def ntlm_get(url, username, password):
    '''发送带有NTLM认证和浏览器头的GET请求'''
    try:
        session = requests.Session()
        session.headers.update(get_browser_headers())  # 使用动态头
        
        response = session.get(
            url,
            auth=HttpNtlmAuth(username, password),
            verify=False  # 生产环境建议启用证书验证
        )
        return {
            'status': 'success',
            'status_code': response.status_code,
            'content': response.text
        }
    except Exception as e:
        return {
            'status': 'error',
            'message': str(e)
        }

def ntlm_post(url, username, password, data=None):
    '''发送带有NTLM认证和浏览器头的POST请求'''
    try:
        session = requests.Session()
        session.headers.update(get_browser_headers())  # 使用动态头
        
        response = session.post(
            url,
            auth=HttpNtlmAuth(username, password),
            data=data,
            verify=False  # 生产环境建议启用证书验证
        )
        return {
            'status': 'success',
            'status_code': response.status_code,
            'content': response.text
        }
    except Exception as e:
        return {
            'status': 'error',
            'message': str(e)
        }

if __name__ == '__main__':
    if len(sys.argv) < 5:
        print(json.dumps({
            'status': 'error',
            'message': '参数不足: 方法(url, username, password, [data])'
        }))
        sys.exit(1)
    
    method = sys.argv[1]
    url = sys.argv[2]
    username = sys.argv[3]
    password = sys.argv[4]
    data = sys.argv[5] if len(sys.argv) > 5 else None
    
    if method.lower() == 'get':
        result = ntlm_get(url, username, password)
    elif method.lower() == 'post':
        result = ntlm_post(url, username, password, data)
    else:
        result = {'status': 'error', 'message': '不支持的方法'}
    
    print(base64.b64encode(result.get('content', '未找到楼上考勤卡机不区分上').encode('utf-8')).decode('utf-8'))\"
"""

        let jiaBanHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", pythonPath + " -c \(ntlm_crawler)" + " get \"http://hr.rsquanta.com/QSMCHR/Attn/Modify_Attandence_Assistant_Min.aspx?Flag=4&languageType=zh-CN\" \(empID) \"\(hrPwd)\" | base64 -d"]).1
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let formattedDate = dateFormatter.string(from: Date())
        let currentDay = formattedDate.suffix(2)
        
        if jiaBanHtml.contains("楼上考勤卡机不区分上") {
            if currentDay == "25" {
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
            var totalWeiQianOwMin = 0
            
            do {
                let gvAttnDoc: Document = try parse(jiaBanHtml)
                let gvAttnTable = try gvAttnDoc.select("table#gvAttn").first()!
                let gvAttnRows = try gvAttnTable.select("tr")
                let owCsvPath = URL(fileURLWithPath: desktopURL.absoluteString).appendingPathComponent("ow.csv")
                var titleShBan = "----"
                
                for i in 1..<gvAttnRows.size() {
                    let gvAttnRow = gvAttnRows.get(i)
                    let gvAttnCells = try gvAttnRow.select("td")
                    
                    if try gvAttnCells.get(3).text().hasSuffix("24") && i != 1 && i != 2 {
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
                                    let shangBanHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", pythonPath + " -c \(ntlm_crawler)" + " get \"http://hr.rsquanta.com/QSMCHR/Attn/\(onclickURL)\" \(empID) \"\(hrPwd)\" | base64 -d"]).1
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
                        
                        try "日期,上班,下班,班别,加班m,🏡🔧h,签核\n".write(to: owCsvPath, atomically: true, encoding: .utf8)
                        
                        if isCalToday.rawValue == 0 {
                            continue
                        }
                        
                        if try gvAttnCells.get(3).text().hasSuffix("25") {
                            continue
                        }
                    } else {
                        if (try gvAttnCells.get(4).text().isEmpty && !gvAttnCells.get(5).text().isEmpty) {
                            return "[\(try gvAttnCells.get(3).text())上班时间为空]"
                        } else if (try !gvAttnCells.get(4).text().isEmpty && gvAttnCells.get(5).text().isEmpty) {
                            return "[\(try gvAttnCells.get(3).text())下班时间为空]"
                        }
                    }
                    
                    if try !gvAttnCells.get(4).text().isEmpty {
                        var today_OwMin: Int
                        
                        if try gvAttnRow.attr("style").contains("White") || gvAttnRow.attr("style").contains("#EFF3FB") {
                            if let weekdayOwTime = calWeekdayOWTime(xiaBanTime: try gvAttnCells.get(5).text(), banBie: try gvAttnCells.get(7).text()) {
                                today_OwMin = weekdayOwTime
                            } else {
                                return "[计算\(try gvAttnCells.get(3).text())加班出错]"
                            }
                        } else if try gvAttnRow.attr("style").contains("Pink") || gvAttnRow.attr("style").contains("Yellow") {
                            if let weekendHolidayOwTime = calWeekendHolidayOWTime(shBanTime: try gvAttnCells.get(4).text(), xiaBanTime: try gvAttnCells.get(5).text(), banBie: try gvAttnCells.get(7).text()) {
                                today_OwMin = weekendHolidayOwTime
                            } else {
                                return "[计算\(try gvAttnCells.get(3).text())加班出错]"
                            }
                        } else {
                            return "[无法识别\(try gvAttnCells.get(3).text())是平时还是节假日]"
                        }
                        
                        // 预报加班时数
                        if let cellText = try? gvAttnCells.get(32).text(),
                           let cellValue = Double(cellText) {
                            
                            let convertedValue = Int(cellValue * 60)  // 转为Int（会自动取整）
                            
                            if today_OwMin > convertedValue {
                                today_OwMin = convertedValue  // 类型匹配，可以直接赋值
                            }
                        }
                        
                        if try gvAttnCells.get(26).text() != "Y" && totalOwMin > 0 {
                            totalWeiQianOwMin += today_OwMin
                        }
                                            
                        totalOwMin += today_OwMin
                        let today_OwHour = String(format: "%.2f", floor(Double(today_OwMin) / 60 * 100) / 100)
                        
                        let owResultRow = try "\(gvAttnCells.get(3).text()),\(gvAttnCells.get(4).text()),\(gvAttnCells.get(5).text()),\(gvAttnCells.get(7).text()),\(today_OwMin),\(today_OwHour),\(gvAttnCells.get(26).text())\n"
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
                    let csvNewContent = csvContent + "总加班,,,,\(totalOwMin),\(totalOwHour)"
                    if currentDay == "25" {
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
                let stringOwTime = String(format: "%.2f", floor(Double(totalOwMin) / 60 * 100) / 100)
                var titleOwTime = "[加班 " + stringOwTime + "H]"
                let isShowJiaBan = getStateValue(forKey: "jiaBan")
                if isShowJiaBan.rawValue == 0 {
                    titleOwTime = ""
                }
                
                // 计算原始值（保留两位小数的逻辑不变）
                let rawValue = floor(Double(totalWeiQianOwMin) / 60 * 100) / 100

                // 创建数字格式化器
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal  // 十进制数字格式
                formatter.minimumFractionDigits = 0  // 最小小数位数：0（允许整数）
                formatter.maximumFractionDigits = 2  // 最大小数位数：2（最多保留两位）
                formatter.roundingMode = .down  // 保持与floor一致的向下取整逻辑

                // 格式化并转换为字符串
                let stringWeiQianOwTime = formatter.string(from: NSNumber(value: rawValue)) ?? "\(rawValue)"
                
                var titleWeiQian = "[☒ " + stringWeiQianOwTime + "H]"
                let isShowWeiQian = getStateValue(forKey: "weiQian")
                if isShowWeiQian.rawValue == 0 {
                    titleWeiQian = ""
                }
                
                let restOwTime = round(((Double(upLimit) ?? 60) - (Double(stringOwTime) ?? 0)) * 100) / 100
                var restOwTimeStr = String(restOwTime)
                if restOwTime < 0 {
                    restOwTimeStr = "0"
                }
                var titleRestOwTime = "[剩余 " + restOwTimeStr + "H]"
                let isShowRest = getStateValue(forKey: "shengYu")
                if isShowRest.rawValue == 0 {
                    titleRestOwTime = ""
                }

                fullTitle = "\(titleShBan) \(titleOwTime) \(titleRestOwTime) \(titleWeiQian)"
            } catch {
    //            print("解析或计算加班数据时出错: \(error)")
            }
            
        } else {
            fullTitle = "[无法访问加班页面]"
        }
        
        return fullTitle
    } else {
        // 处理未获取到pythonPath的情况，例如提示用户检查Python环境
        return "请先检查Python环境"
    }
}
