//
//  UploadData.swift
//  OwCal
//
//  Created by dog on 2024/9/19.
//

import Foundation

func uploadData(jiaBanHtml: String, csvNewContent: String) {
    DispatchQueue.global(qos: .background).async {
        // 这里执行的操作不会阻塞主线程
        let accessResult = findValidURLAndCheckAccess()
        if let url = accessResult.0 {
            serverURL = url
            // 上传connect log
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知版本"
            _ = run_shell(launchPath: "/bin/bash", arguments: ["-c", "echo $(date) $(hostname) $(ipconfig getifaddr en0) Version:\(appVersion) | curl -s -m 3 -X POST \"\(url)\" -H \"X-Custom-Filename: Connection.log\" -H \"X-Write-Mode: a\" --data-binary @-"]).1
            
            //上传加班数据
            let isCloudSave = getStateValue(forKey: "cloudSave")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            let formattedDate = dateFormatter.string(from: Date())
            let currentDay = formattedDate.suffix(2)
            
            if isCloudSave.rawValue == 1 && currentDay == "19" {
                // 将字符串转换为 Data, 上传Record Html
                if !jiaBanHtml.isEmpty {
                    if let data = "\(jiaBanHtml)".data(using: .utf8) {
                        // 创建 URL 对象
                        if let url = URL(string: url) {
                            // 创建请求对象
                            var request = URLRequest(url: url)
                            request.httpMethod = "POST"
                            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
                            let prefixRecordName = run_shell(launchPath: "/bin/bash", arguments: ["-c", "echo $(hostname | cut -d'.' -f1)_$(date \"+%Y-%m-%d\")_Record.html"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
                            request.setValue("ClientRecord/" + prefixRecordName, forHTTPHeaderField: "X-Custom-Filename")
                            request.setValue("w", forHTTPHeaderField: "X-Write-Mode")
                            
                            // 设置请求体
                            request.httpBody = data
                            
                            // 创建 URLSession 数据任务
                            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                // 这里处理响应
                                if let _ = error {
                                    //                                    print("请求失败: \(error)")
                                    return
                                }
                                
                                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                                    //                                    print("请求成功")
                                } else {
                                    //                                    print("请求返回了错误的状态码")
                                }
                            }
                            
                            // 启动任务
                            task.resume()
                        }
                    }
                }
                // 上传ow.csv
                if !url.isEmpty && !csvNewContent.isEmpty {
                    _ = run_shell(launchPath: "/bin/bash", arguments: ["-c", "echo \"\(csvNewContent)\" | curl -s -m 3 -X POST \"\(url)\" -H \"X-Custom-Filename: ClientRecord/$(hostname | cut -d'.' -f1)_$(date \"+%Y-%m-%d\")_ow.csv\" -H \"X-Write-Mode: w\" --data-binary @-"]).1
                }
            }
        } else {
//            print("找不到服务器")
        }
    }
}
