//
//  CheckNewVersion.swift
//  OwCal
//
//  Created by dog on 2024/9/9.
//

import Foundation
import AppKit

func checkUpdate() {
    // 检查更新
    DispatchQueue.global(qos: .background).async {
        // 这里执行的操作不会阻塞主线程
        if !serverURL.isEmpty {
            let serverVersionString = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m 3 '\(serverURL)' | grep '<td>Ver_' | awk -F'<td>Ver_|</td>' '{print $2}'"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
//            print("serverVersionString:", serverVersionString)
            let currentVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知版本"
//            print("currentVersionString:", currentVersionString)

            if let serverVersion = Double(serverVersionString), let currentVersion = Double(currentVersionString) {
                appUpdate = false
                if serverVersion > currentVersion {
                    appUpdate = true
                    DispatchQueue.main.async {
                        let defaults = UserDefaults.standard
                        let emoji = defaults.string(forKey: "emojiComboBox") ?? "🍎"
                        if let appDelegate = NSApp.delegate as? AppDelegate, let button = appDelegate.statusItem?.button {
                            button.title = emoji + "[请使用最新版本]"
                        }
                    }
                    let appURL = serverURL.split(separator: ":")[1]
                    _ = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m3 -o ~/Downloads/垃圾软件\(serverVersion).zip 'http:\(appURL):8888/垃圾软件.zip'"]).1
                    let isDownloadSuccess = run_shell(launchPath: "/bin/bash", arguments: ["-c", "[[ -f /Users/dog/Downloads/垃圾软件\(serverVersion).zip ]] && echo Yes || echo No"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
//                    print(isDownloadSuccess)
                    if isDownloadSuccess == "Yes" {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.messageText = "检测到新版本\(currentVersion)->\(serverVersion)"
                            alert.informativeText = "已下载到Downloads文件夹，请覆盖旧版本\n\n更新日志：优化了一些细节，减少了App体积"
                            alert.addButton(withTitle: "确定")
                            alert.runModal()
                        }
                    } else {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.messageText = "检测到新版本\(currentVersion)->\(serverVersion)"
                            alert.informativeText = "下载失败\n\n更新日志：优化了一些细节，减少了App体积"
                            alert.addButton(withTitle: "确定")
                            alert.runModal()
                        }
                    }
                } else {
                    appUpdate = false
//                    print("No need update")
                }
            } else {
//                print("获取版本号失败")
            }
        }
    }
}
