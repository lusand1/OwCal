//
//  AppDelegate.swift
//  OwCal
//
//  Created by dog on 2024/9/10.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: NSWindowController?
    var statusItem: NSStatusItem!
    var unlockCount = 0
    var lastUnlockDate = Date()
    var viewController: ViewController?
    var lastTitle = ""
    let menu = NSMenu()
    var dateCheckTimer: Timer?
    var hasUpdatedForToday = false  // 添加一个标志位
    // 在类属性中添加标志位（避免重复弹窗）
    var hasShownModuleAlert = false
    // 在类属性中添加存储缺失模块的数组
    var missingModules: [String] = []

    enum StatusBarTitle {
        static let loading = "Loading..."
        static let refreshing = "Refreshing"
        static let setEmployeeID = "[请设置工号]"
        static let accessDenied = "[无法获取当前时间]"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        checkPythonEnvironment()
        configureStatusItem()
        configureMenu()
        addScreenUnlockObserver()
        startDateCheckTimer()  // 启动定时器
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        dateCheckTimer?.invalidate()  // 停止定时器
    }

    // 修改检查Python环境的方法
    func checkPythonEnvironment() {
        // 每次检查前清空缺失模块数组
        missingModules.removeAll()
        
        let pythonPathTask = Process()
        pythonPathTask.launchPath = "/bin/bash"
        pythonPathTask.arguments = ["-l", "-c", "which python3"]
        
        let pythonPathPipe = Pipe()
        pythonPathTask.standardOutput = pythonPathPipe
        let errorPipe = Pipe()
        pythonPathTask.standardError = errorPipe
        
        do {
            try pythonPathTask.run()
            pythonPathTask.waitUntilExit()
            
            if pythonPathTask.terminationStatus == 0 {
                let data = pythonPathPipe.fileHandleForReading.readDataToEndOfFile()
                if let pythonPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
//                    print("Python3 路径: \(pythonPath)")
                    // 在 checkPythonEnvironment 方法中，当获取到 pythonPath 后添加
                    UserDefaults.standard.set(pythonPath, forKey: "pythonPath")
                    
                    // 检查模块（先不弹窗，只收集缺失的）
                    checkPythonModule(moduleName: "requests", pythonPath: pythonPath)
                    checkPythonModule(moduleName: "requests_ntlm", pythonPath: pythonPath)
                    
                    // 所有模块检查完成后，统一弹窗
                    if !missingModules.isEmpty {
                        showMissingModulesAlert(pythonPath: pythonPath)
                    }
                }
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMsg = String(data: errorData, encoding: .utf8) ?? "未知错误"
                showAlert(title: "Python3 不可用", message: "无法找到Python3环境，请先安装Python3。\n错误信息：\(errorMsg)")
            }
        } catch {
            showAlert(title: "检查失败", message: "检查Python3环境时发生错误：\(error.localizedDescription)")
        }
    }

    // 修改模块检查方法（只收集缺失模块，不单独弹窗）
    private func checkPythonModule(moduleName: String, pythonPath: String) {
        let moduleCheckTask = Process()
        moduleCheckTask.launchPath = "/bin/bash"
        moduleCheckTask.arguments = ["-l", "-c", "\(pythonPath) -c 'import \(moduleName)' 2>/dev/null && echo 'installed' || echo 'missing'"]
        
        let modulePipe = Pipe()
        moduleCheckTask.standardOutput = modulePipe
        
        do {
            try moduleCheckTask.run()
            moduleCheckTask.waitUntilExit()
            
            let data = modulePipe.fileHandleForReading.readDataToEndOfFile()
            if let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if result == "missing" {
                    missingModules.append(moduleName)  // 添加到缺失数组
                    print("模块 \(moduleName) 未安装")
                }
            }
        } catch {
            showAlert(title: "检查失败", message: "检查模块 \(moduleName) 时发生错误：\(error.localizedDescription)")
        }
    }

    // 新增：统一显示缺失模块的弹窗
    private func showMissingModulesAlert(pythonPath: String) {
        DispatchQueue.main.async {
            let moduleList = self.missingModules.joined(separator: "、")
            var installCommands = ""
            
            // 生成安装命令（多个模块可以合并安装）
            if self.missingModules.count > 1 {
                installCommands = "\(pythonPath) -m pip install \(self.missingModules.joined(separator: " "))"
            } else {
                installCommands = "\(pythonPath) -m pip install \(self.missingModules.first!)"
            }
            
            let alert = NSAlert()
            alert.messageText = "缺少必要模块"
            alert.informativeText = "检测到以下模块未安装：\n\(moduleList)\n\n请使用以下命令安装：\n\(installCommands)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "知道了")
            alert.runModal()
        }
    }

    // 新增：弹窗提示工具
    private func showAlert(title: String, message: String) {
        // 确保在主线程弹窗
        DispatchQueue.main.async {
            // 避免重复弹窗
            guard !self.hasShownModuleAlert else { return }
            self.hasShownModuleAlert = true
            
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "知道了")
            alert.runModal()
        }
    }
    
    private func startDateCheckTimer() {
        // 每2小时检查一次
        dateCheckTimer = Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(checkDateAndUpdate), userInfo: nil, repeats: true)
//        dateCheckTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(checkDateAndUpdate), userInfo: nil, repeats: true)
    }
    
    @objc private func checkDateAndUpdate() {
        let calendar = Calendar.current
        let now = Date()
        let day = calendar.component(.day, from: Date())
        
        if day == 25 && !hasUpdatedForToday {  // 如果是25号且未更新过
            // 触发更新
            updateTime(isRefreshClicked: true)
            hasUpdatedForToday = true  // 标记已经更新过
        } else if day != 25 {
            hasUpdatedForToday = false  // 重置标志位，准备下个月更新
        }
        
        // 新增：判断是否在每天6:45-8:00之间
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // 检查当前时间是否在目标时间段内
        let isInTimeRange: Bool
        if hour == 6 {
            // 6点时，需要分钟数≥45
            isInTimeRange = minute >= 45
        } else if hour == 7 {
            // 7点整段都在范围内
            isInTimeRange = true
        } else if hour == 8 {
            // 8点整段都在范围内
            isInTimeRange = true
        } else {
            isInTimeRange = false
        }
    
        // 如果在时间范围内，且autoNet开启，则执行网络认证
        if isInTimeRange {
            let autoNet = getStateValue(forKey: "autoNet")
            if autoNet.rawValue == 1 {
                let defaults = UserDefaults.standard
                guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty,
                      let hrPwd = defaults.string(forKey: "hrPwd"), !hrPwd.isEmpty else {
                    return
                }
                DispatchQueue.global(qos: .background).async {
                    networkAuth(id: empID, pwd: hrPwd)
                }
            }
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let defaults = UserDefaults.standard
        let emoji = defaults.string(forKey: "emojiComboBox") ?? "🍎"
        if let button = statusItem.button {
            button.title = emoji + StatusBarTitle.loading
        }
        updateTime(isRefreshClicked: false)
        statusItem.menu = menu
    }
    
    private func configureMenu() {
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshClicked), keyEquivalent: "R"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(settingsClicked), keyEquivalent: "S"))
        menu.addItem(NSMenuItem(title: "Hiding", action: #selector(toggleHiding), keyEquivalent: "H"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "Q"))
    }
    
    private func addScreenUnlockObserver() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }
    
    @objc func screenDidUnlock() {
        let now = Date()
        if !Calendar.current.isDate(now, inSameDayAs: lastUnlockDate) {
            unlockCount = 0
            lastUnlockDate = now
        }
        if unlockCount < 2 {
            let defaults = UserDefaults.standard
            let emoji = defaults.string(forKey: "emojiComboBox") ?? "🍎"
            if let button = statusItem.button {
                button.title = emoji + StatusBarTitle.loading
            }
            updateTime(isRefreshClicked: false)
            unlockCount += 1
        }
    }
    
    @objc func refreshClicked() {
        let defaults = UserDefaults.standard
        let emoji = defaults.string(forKey: "emojiComboBox") ?? "🍎"
        guard let button = statusItem.button else { return }
        button.title = emoji + StatusBarTitle.refreshing
        updateTime(isRefreshClicked: true)
    }
    
    @objc func settingsClicked() {
        showMainWindow()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitClicked() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func updateTime(isRefreshClicked: Bool) {
        let defaults = UserDefaults.standard
        let emoji = defaults.string(forKey: "emojiComboBox") ?? "🍎"
        
        guard let button = statusItem.button else { return }
        guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty else {
            button.title = emoji + StatusBarTitle.setEmployeeID
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                guard let todayDate = self.fetchTodayDate() else {
                    button.title = emoji + StatusBarTitle.accessDenied
                    return
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let todayDateString = dateFormatter.string(from: todayDate)
                
                if self.shouldUpdateKeyChain(todayDate: todayDate, defaults: defaults, dateFormatter: dateFormatter) {
                    let accessResult = checkAccess()
                    if accessResult == "true" {
                        defaults.set(encrypt(input: todayDateString), forKey: "keyChain")
                        self.updateButtonTitle(with: emoji, isRefreshClicked: isRefreshClicked)
                    } else {
                        button.title = emoji + accessResult
                    }
                } else {
                    self.updateButtonTitle(with: emoji, isRefreshClicked: isRefreshClicked)
                }
            }
        }
    }
    
    private func fetchTodayDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "ddMMMyyyy"
        
        let todayDateTer = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -m7 --head 'http://172.20.170.176/homepage/login.html' | grep -i 'date' | awk '{print $3$4$5}'"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let todayDate = dateFormatter.date(from: todayDateTer) else {
            return nil
        }
        
        let calendar = Calendar.current
        guard let futureDate = calendar.date(from: DateComponents(year: 2035, month: 1, day: 1)) else {
            return nil
        }
        
        if todayDate > futureDate || Date() > futureDate {
            return nil
        }
        
        return todayDate
    }

    private func shouldUpdateKeyChain(todayDate: Date, defaults: UserDefaults, dateFormatter: DateFormatter) -> Bool {
        dateFormatter.dateFormat = "yyyyMMdd"
        
        if let keyChainString = defaults.string(forKey: "keyChain") {
            let lastCheckDateString = decrypt(input: keyChainString)
            if let lastCheckDate = dateFormatter.date(from: lastCheckDateString) {
                let dayDifference = Calendar.current.dateComponents([.day], from: lastCheckDate, to: todayDate).day ?? 0
                return dayDifference >= 30 || dayDifference < 0
            }
        }
        
        return true
    }
    
    private func updateButtonTitle(with emoji: String, isRefreshClicked: Bool) {
        DispatchQueue.global(qos: .background).async {
            let currentTime = owHandle()
            let newTitle = emoji + currentTime
            DispatchQueue.main.async {
                if let button = self.statusItem.button {
                    let hidingItem = self.menu.item(withTitle: "Hiding")
                    let showingItem = self.menu.item(withTitle: "Showing")
                    
                    if hidingItem != nil && showingItem == nil {
                        button.title = newTitle
                    } else if hidingItem == nil && showingItem != nil && isRefreshClicked {
                        button.title = newTitle
                    } else if hidingItem == nil && showingItem == nil {
                        button.title = newTitle
                    }
                    
                    if isRefreshClicked {
                        showingItem?.title = "Hiding"
                    }
                    
                    self.lastTitle = newTitle
                }
            }
        }
    }
    
    @objc func toggleHiding() {
        guard let button = statusItem.button else { return }
        if let hidingItem = menu.item(withTitle: "Hiding") {
            hidingItem.title = "Showing"
            lastTitle = button.title
            let defaults = UserDefaults.standard
            button.title = defaults.string(forKey: "emojiComboBox") ?? "🍎"
        } else if let showingItem = menu.item(withTitle: "Showing") {
            showingItem.title = "Hiding"
            button.title = lastTitle
        }
    }
    
    func showMainWindow() {
        // 如果窗口控制器已经存在，直接显示窗口并返回
        if let existingWindowController = mainWindowController {
            existingWindowController.showWindow(nil)
            return
        }
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let newWindowController = storyboard.instantiateController(withIdentifier: "MainWindowController") as? NSWindowController {
            mainWindowController = newWindowController
            newWindowController.showWindow(nil)
            viewController = newWindowController.contentViewController as? ViewController
        }
    }
}
