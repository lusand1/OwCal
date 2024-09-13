//
//  ShellRun.swift
//  OwCal
//
//  Created by dog on 2024/7/29.
//

import Foundation

func run_shell(launchPath:String,arguments:[String]? = nil) -> (Int, String) {
    let task = Process();
    task.launchPath = launchPath
    var environment = ProcessInfo.processInfo.environment
    environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    task.environment = environment
    if arguments != nil {
        task.arguments = arguments!
    }

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = String(data: data, encoding: String.Encoding.utf8)!
    task.waitUntilExit()
    pipe.fileHandleForReading.closeFile()

    // print("DEBUG 24: run_shell finish.")
    return (Int(task.terminationStatus),output)
}
