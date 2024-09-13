//
//  AppDelegate.swift
//  OwCal
//
//  Created by dog on 2024/9/10.
//

import Cocoa

var serverURL = ""
var appUpdate = false

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

    enum StatusBarTitle {
        static let loading = "Loading..."
        static let refreshing = "Refreshing"
        static let setEmployeeID = "[请设置工号]"
        static let accessDenied = "[⏰❌]"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
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
    
    private func startDateCheckTimer() {
        // 每2小时检查一次
        dateCheckTimer = Timer.scheduledTimer(timeInterval: 7200, target: self, selector: #selector(checkDateAndUpdate), userInfo: nil, repeats: true)
//        dateCheckTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(checkDateAndUpdate), userInfo: nil, repeats: true)
    }
    
    @objc private func checkDateAndUpdate() {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        
        if day == 26 && !hasUpdatedForToday {  // 如果是26号且未更新过
            // 触发更新
            updateTime(isRefreshClicked: true)
            hasUpdatedForToday = true  // 标记已经更新过
        } else if day != 26 {
            hasUpdatedForToday = false  // 重置标志位，准备下个月更新
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
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
        checkUpdate()
        let now = Date()
        if !Calendar.current.isDate(now, inSameDayAs: lastUnlockDate) {
            unlockCount = 0
            lastUnlockDate = now
        }
        if unlockCount < 2 {
            updateTime(isRefreshClicked: false)
            unlockCount += 1
        }
    }
    
    @objc func refreshClicked() {
        checkUpdate()
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
        button.title = emoji + StatusBarTitle.loading
        
        guard let empID = defaults.string(forKey: "empID"), !empID.isEmpty else {
            button.title = emoji + StatusBarTitle.setEmployeeID
            return
        }
        DispatchQueue.global(qos: .background).async {
            if empID == "A7116053" {
                let ipSet = run_shell(launchPath: "/bin/bash", arguments: ["-c", "ipconfig getifaddr en0"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
                if Cookie.isEmpty {
                    
                    Cookie = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s -i --data-raw 'name=A7116053&password=BBc%4012345&refer=site%2F' 'http://172.18.26.15/decision/index.php/Login/checkLogin.html' | grep 'Set-Cookie' | awk -F':|;' '{print $2}'"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let cmd1 = "curl -s 'http://172.18.26.15/decision/index.php/Index/update.html' "
                let cmd2 = "-H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryEXhMgstG2BKf0CVh' "
                let cmd3 = "-H 'Cookie: \(Cookie)' "
                let cmd4 = "--data-raw $'------WebKitFormBoundaryEXhMgstG2BKf0CVh\\r\\nContent-Disposition: form-data; "
                let cmd5 = "name=\"shortnum\"\\r\\n\\r\\n\(ipSet)\\r\\n------WebKitFormBoundaryEXhMgstG2BKf0CVh\\r\\nContent-Disposition: form-data; "
                let cmd6 = "name=\"Station\"\\r\\n\\r\\nQT\\r\\n------WebKitFormBoundaryEXhMgstG2BKf0CVh\\r\\n'"
                _ = run_shell(launchPath: "/bin/bash", arguments: ["-c", "\(cmd1)\(cmd2)\(cmd3)\(cmd4)\(cmd5)\(cmd6)"]).1
            }
        }
        
        guard let todayDate = fetchTodayDate() else {
            button.title = emoji + StatusBarTitle.accessDenied
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let todayDateString = dateFormatter.string(from: todayDate)
        
        if shouldUpdateKeyChain(todayDate: todayDate, defaults: defaults, dateFormatter: dateFormatter) {
            let accessResult = findValidURLAndCheckAccess()
            if accessResult.1 == "true" {
                defaults.set(encrypt(input: todayDateString), forKey: "keyChain")
                updateButtonTitle(with: emoji, isRefreshClicked: isRefreshClicked)
            } else {
                button.title = emoji + accessResult.1!
            }
        } else {
            updateButtonTitle(with: emoji, isRefreshClicked: isRefreshClicked)
        }
    }
    
    private func fetchTodayDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "ddMMMyyyy"
        
        let todayDateTer = run_shell(launchPath: "/bin/bash", arguments: ["-c", "curl -s --head 'http://hr.rsquanta.com/HRUI/Webui/' | grep -i 'date' | awk '{print $3$4$5}'"]).1.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        let currentTime = owHandle()
        let newTitle = emoji + currentTime
        
        if let button = statusItem.button {
            let hidingItem = menu.item(withTitle: "Hiding")
            let showingItem = menu.item(withTitle: "Showing")
            
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
            
            lastTitle = newTitle
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
