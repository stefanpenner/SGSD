import Cocoa
import UserNotifications

let DURATION: Int = 5

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var remainingTime: Int = DURATION
    var isRunning: Bool = false
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🙉"

        // Monitor mouse events to differentiate click types
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self = self, let button = self.statusItem.button, event.window == button.window else { return event }
            
            if event.type == .rightMouseDown || (event.type == .leftMouseDown && event.modifierFlags.contains(.control)) {
                let menu = NSMenu()
                let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                menu.addItem(quitItem)
                self.statusItem.menu = menu
                button.performClick(nil)
                self.statusItem.menu = nil // Clear menu after use
                return nil // Consume the event
            } else if event.type == .leftMouseDown {
                self.toggleTimer()
                return nil // Consume the event
            }
            return event // Pass through unhandled events
        }

        // Set up notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error { print("Notification authorization error: \(error)") }
            if !granted { print("Notification permission denied") }
        }
        
        // Register notification category
        let category = UNNotificationCategory(identifier: "SGSD", actions: [], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    @objc func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            remainingTime = DURATION
            statusItem.button?.title = "🙉"
            isRunning = false
        } else {
            remainingTime = DURATION
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            isRunning = true
            updateTimer() // Update title immediately
        }
    }

    @objc func updateTimer() {
        remainingTime -= 1
        let mins = remainingTime / 60
        let secs = remainingTime % 60
        statusItem.button?.title = String(format: "🙈 %02d:%02d", mins, secs)
        if remainingTime <= 0 {
            timer?.invalidate()
            isRunning = false
            remainingTime = DURATION
            statusItem.button?.title = "🙉"
            let content = UNMutableNotificationContent()
            content.title = "SGSD"
            content.body = "Time is up! Take a break :)"
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "SGSD"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "SGSD", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error { print("Notification delivery error: \(error)") }
                else { print("Notification scheduled successfully") }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
