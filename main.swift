import Cocoa
import UserNotifications

var TIMEOUT: Int = 5

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var remainingTime: Int = TIMEOUT
    var isRunning: Bool = false
    var startPauseMenuItem: NSMenuItem!
    var stopMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🙉"

        let menu = NSMenu()
        startPauseMenuItem = NSMenuItem(title: "Start Timer", action: #selector(startPauseTimer), keyEquivalent: "")
        stopMenuItem = NSMenuItem(title: "Stop Timer", action: #selector(stopTimer), keyEquivalent: "")
        stopMenuItem.isEnabled = false
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        menu.addItem(startPauseMenuItem)
        menu.addItem(stopMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    @objc func startPauseTimer() {
        if startPauseMenuItem.title == "Pause Timer" {
            timer?.invalidate()
            startPauseMenuItem.title = "Continue Timer"
            isRunning = false
        } else {
            if startPauseMenuItem.title == "Start Timer" {
                remainingTime = TIMEOUT
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            startPauseMenuItem.title = "Pause Timer"
            isRunning = true
            stopMenuItem.isEnabled = true
        }
    }

    @objc func stopTimer() {
        timer?.invalidate()
        remainingTime = TIMEOUT
        statusItem.button?.title = "🙉"
        startPauseMenuItem.title = "Start Timer"
        isRunning = false
        stopMenuItem.isEnabled = false
    }

    @objc func updateTimer() {
        remainingTime -= 1
        let mins = remainingTime / 60
        let secs = remainingTime % 60
        statusItem.button?.title = String(format: "🙈 %02d:%02d", mins, secs)
        if remainingTime <= 0 {
            let content = UNMutableNotificationContent()
            content.title = "SGSD"
            content.body = "Time is up! Take a break :)"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "SGSD", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            stopTimer()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
