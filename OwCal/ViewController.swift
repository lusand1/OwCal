//
//  ViewController.swift
//  OwCal
//
//  Created by dog on 2024/9/10.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    var popover: NSPopover!
    @IBOutlet weak var autoNet: NSButton!
    @IBOutlet weak var autoMeal: NSButton!
    @IBOutlet weak var saveHistory: NSButton!
    @IBOutlet weak var isCalToday: NSButton!
    
    @IBOutlet weak var shangBan: NSButton!
    @IBOutlet weak var jiaBan: NSButton!
    @IBOutlet weak var shengYu: NSButton!
    @IBOutlet weak var meal: NSButton!
    
    @IBOutlet weak var empID: NSTextField!
    @IBOutlet weak var secureTextField: NSSecureTextField!
    @IBOutlet weak var plainTextField: NSTextField!
    @IBOutlet weak var toggleButton: NSButton!
    @IBOutlet weak var upperLimit: NSTextField!
    @IBOutlet weak var folderPath: NSTextField!
    @IBOutlet weak var emojiComboBox: NSComboBox!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // 创建并设置 popover 的内容视图
        popover = NSPopover()
        popover.behavior = .transient
        // 创建并设置 popover 的内容视图
        let popoverViewController = NSViewController()
        popoverViewController.view = NSView(frame: NSRect(x: 0, y: 0, width: 85, height: 25))
        let label = NSTextField(labelWithString: "请输入数字")
        label.textColor = .red
        label.alignment = .center // 文字居中显示
        label.frame = NSRect(x: 0, y: 1, width: 85, height: 20) // 设置 popover 大小
        popoverViewController.view.addSubview(label)
        popover.contentViewController = popoverViewController

        secureTextField.delegate = self
        plainTextField.delegate = self
        empID.delegate = self
        upperLimit.delegate = self
        plainTextField.isHidden = true
        if #available(macOS 11.0, *) {
            toggleButton.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Hide")
        } else {
            toggleButton.image = NSImage(named: "eye.slash")
        }
        
        loadSettings()
        
        let emojis = ["🍎", "🥝", "🤡", "❤️"]
        emojiComboBox.addItems(withObjectValues: emojis)
        emojiComboBox.completes = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func loadSettings() {
        // 使用默认值的方式获取UserDefaults中的值，并判断是0还是未设置
        autoNet.state = defaults.object(forKey: "autoNet") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "autoNet")) : .on
        autoMeal.state = defaults.object(forKey: "autoMeal") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "autoMeal")) : .on
        saveHistory.state = defaults.object(forKey: "saveHistory") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "saveHistory")) : .on
        isCalToday.state = defaults.object(forKey: "isCalToday") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "isCalToday")) : .on
        shangBan.state = defaults.object(forKey: "shangBan") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "shangBan")) : .on
        jiaBan.state = defaults.object(forKey: "jiaBan") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "jiaBan")) : .on
        shengYu.state = defaults.object(forKey: "shengYu") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "shengYu")) : .on
        meal.state = defaults.object(forKey: "meal") != nil ? NSControl.StateValue(rawValue: defaults.integer(forKey: "meal")) : .on
        
        // 加载文本框状态
        empID.stringValue = defaults.string(forKey: "empID") ?? ""
        secureTextField.stringValue = defaults.string(forKey: "secureTextField") ?? ""
        plainTextField.stringValue = secureTextField.stringValue
        upperLimit.stringValue = defaults.string(forKey: "upperLimit") ?? "60"
        folderPath.stringValue = defaults.string(forKey: "folderPath") ?? "/Users/dog/Desktop/加班历史记录"
        emojiComboBox.stringValue = defaults.string(forKey: "emojiComboBox") ?? "🍎"
    }

    
    func saveSettings() {
        // 保存复选框状态
        defaults.set(autoNet.state.rawValue, forKey: "autoNet")
        defaults.set(autoMeal.state.rawValue, forKey: "autoMeal")
        defaults.set(saveHistory.state.rawValue, forKey: "saveHistory")
        defaults.set(isCalToday.state.rawValue, forKey: "isCalToday")
        defaults.set(shangBan.state.rawValue, forKey: "shangBan")
        defaults.set(jiaBan.state.rawValue, forKey: "jiaBan")
        defaults.set(shengYu.state.rawValue, forKey: "shengYu")
        defaults.set(meal.state.rawValue, forKey: "meal")
        
        // 保存文本框状态
        defaults.set(empID.stringValue, forKey: "empID")
        defaults.set(secureTextField.stringValue, forKey: "secureTextField")
        defaults.set(upperLimit.stringValue, forKey: "upperLimit")
        defaults.set(folderPath.stringValue, forKey: "folderPath")
        defaults.set(emojiComboBox.stringValue, forKey: "emojiComboBox")
    }
    
    @IBAction func togglePasswordVisibility(_ sender: NSButton) {
        if plainTextField.isHidden {
            plainTextField.stringValue = secureTextField.stringValue
            plainTextField.isHidden = false
            secureTextField.isHidden = true
            if #available(macOS 11.0, *) {
                toggleButton.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Show")
            } else {
                toggleButton.image = NSImage(named: "eye")
            }
        } else {
            secureTextField.stringValue = plainTextField.stringValue
            secureTextField.isHidden = false
            plainTextField.isHidden = true
            if #available(macOS 11.0, *) {
                toggleButton.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Hide")
            } else {
                toggleButton.image = NSImage(named: "eye.slash")
            }
        }
        saveSettings()
    }
    
    @IBAction func chooseFolderButtonTapped(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            folderPath.stringValue = url.path
            saveSettings()
        }
    }
    
    @IBAction func emojiSelected(_ sender: NSComboBox) {
        var selectedEmoji: String
        if let emoji = sender.objectValue as? String, emoji.count <= 1 {
            selectedEmoji = emoji
        } else {
            selectedEmoji = "🤡"
            sender.objectValue = "🤡"
        }
        
        if let appDelegate = NSApp.delegate as? AppDelegate, let button = appDelegate.statusItem?.button {
            let oldTitle = button.title
            if oldTitle.count > 1, oldTitle[oldTitle.index(after: oldTitle.startIndex)] == "[" {
                button.title = selectedEmoji + oldTitle.dropFirst().description
            } else if oldTitle.first == "[", !selectedEmoji.isEmpty {
                button.title = selectedEmoji + oldTitle
            } else if oldTitle.count == 1 {
                button.title = selectedEmoji
            }
        }
        saveSettings()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField == secureTextField {
                plainTextField.stringValue = secureTextField.stringValue
            } else if textField == plainTextField {
                secureTextField.stringValue = plainTextField.stringValue
            } else if textField == upperLimit {
                if let _ = Double(upperLimit.stringValue) {
                    // 输入符合期望，隐藏 popover
                    if popover.isShown {
                        popover.performClose(self)
                    }
                } else {
                    // 输入不符合期望，显示 popover
                    if !popover.isShown {
                        popover.show(relativeTo: textField.bounds, of: textField, preferredEdge: .maxY)
                    }
                }
            }
            saveSettings()
        }
    }
    
    @IBAction func checkboxToggled(_ sender: NSButton) {
        saveSettings()
    }
}
