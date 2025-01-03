//
//  FindServerCheckAccess.swift
//  OwCal
//
//  Created by dog on 2024/8/16.
//

import Cocoa

var Cookie = ""

func checkAccess() -> String {
    let defaults = UserDefaults.standard
    guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty else {
        return "请设置工号"
    }
    
    Cookie = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m3 -i --data-raw 'name=A7116053&password=BBc%4012345&refer=site%2F' 'http://172.18.26.15/decision/index.php/Login/checkLogin.html' | grep 'Set-Cookie' | awk -F':|;' '{print $2}'"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
    if Cookie.isEmpty {
        return "HWTE主页连接失败"
    }
    let serverInfoHtml = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m3 -L 'http://172.18.26.15/decision/index.php/Login/checkLogin.html' -H 'Cookie: \(Cookie)' --data-raw 'name=A7116053&password=BBc%4012345&refer=site%2F'"]).1
    
    if !serverInfoHtml.contains("基本信息") {
        return "HWTE主页连接失败"
    }
    
    let htmlEmpID = " " + empID + ","
    if serverInfoHtml.contains(htmlEmpID) {
        return "true"
    } else {
        return "请申请权限"
    }
}
