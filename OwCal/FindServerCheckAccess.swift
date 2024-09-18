//
//  FindServerCheckAccess.swift
//  OwCal
//
//  Created by dog on 2024/8/16.
//

import Cocoa

var Cookie = ""

func findValidURLAndCheckAccess() -> (String?, String?) {
    let defaults = UserDefaults.standard
    guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty else {
        return (nil, "请设置工号")
    }
    
    Cookie = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m4 -i --data-raw 'name=A7116053&password=BBc%4012345&refer=site%2F' 'http://172.18.26.15/decision/index.php/Login/checkLogin.html' | grep 'Set-Cookie' | awk -F':|;' '{print $2}'"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let serverInfoHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m4 -L 'http://172.18.26.15/decision/index.php/Login/checkLogin.html' -H 'Cookie: \(Cookie)' --data-raw 'name=A7116053&password=BBc%4012345&refer=site%2F'"]).1
    let serverInfo = serverInfoHtml.replacingOccurrences(of: "'", with: "'\\''")
    let serverIP = run_shell(launchPath: "/bin/bash", arguments: ["-c", "echo '\(serverInfo)' | grep -o 'name=\"shortnum\" value=\".*' | awk -F 'value=\"|\">' {'print $2'}"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if serverIP.isEmpty {
        return (nil, "找不到服务器")
    }
    
    let serverAddress = "http://\(serverIP):8888/?filename=/Users/dog/AccessList/list.xlsx"
    let accessListHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m4 '\(serverAddress)'"]).1
    
    let htmlEmpID = "<td>" + empID + "</td>"
    if accessListHtml.contains(htmlEmpID) {
        return (serverAddress, "true")
    } else {
        return (serverAddress, "请申请权限")
    }
}
//func findValidURLAndCheckAccess() -> (String?, String?)? {
//    let defaults = UserDefaults.standard
//    guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty else {
//        return (nil, "请设置工号")
//    }
//
//    let timeout: TimeInterval = 5.0
//    let dispatchGroup = DispatchGroup()
//    let queue = DispatchQueue.global(qos: .userInitiated)
//    var result: (String?, String?)?
//
//    let config = URLSessionConfiguration.default
//    config.timeoutIntervalForRequest = timeout
//    config.timeoutIntervalForResource = timeout
//    let session = URLSession(configuration: config)
//
//    for i in 48...50 {
//        for j in 0...255 {
//            let urlString = "http://172.18.\(i).\(j):8888/?filename=/Users/dog/AccessList/list.xlsx"
//            guard let url = URL(string: urlString) else { continue }
//
//            dispatchGroup.enter()
//            queue.async {
//                let request = URLRequest(url: url)
//                let task = session.dataTask(with: request) { data, _, error in
//                    if let error = error {
//                        // Handle error if needed
//                        _ = error
////                        print("URL 无效: \(urlString), 错误: \(error)")
//                    } else if let data = data, let content = String(data: data, encoding: .utf8) {
////                        print("URL 有效: \(urlString)")
////                        print(content)
//                        let htmlEmpID = "<td>" + empID + "</td>"
////                        print(content.contains(htmlEmpID))
//                        if content.contains(htmlEmpID) {
//                            result = (urlString, "true")
//                        } else {
//                            result = (urlString, "请申请权限")
//                        }
//                    } else {
//                        // URL或data无效，正常情况下不会执行到这里
//                        result = (urlString, "权限检查失败")
//                    }
//                    dispatchGroup.leave()
//                }
//                task.resume()
//            }
//        }
//    }
//
//    let waitResult = dispatchGroup.wait(timeout: .now() + timeout)
//    if waitResult == .timedOut && result == nil {
//        result = (nil, "找不到服务器")
//    }
//
//    return result
//}
