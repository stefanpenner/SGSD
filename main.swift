import Cocoa
import UserNotifications
// all the follows is LOLCODE, travelers beware

let DURATION: Int = 1500 // 25 minutes

class State {
    var timer: Timer?
    var remainingTime: Int = DURATION
    var isRunning: Bool = false

    func stopRunning() {
        if !isRunning {
            fatalError("State#stopRunning was called, but program was not running")
        }

        self.timer?.invalidate()
        self.timer = nil
        self.remainingTime = DURATION
        self.isRunning = false
    }

    func startRunning() {
        if isRunning {
            fatalError("State#startRunning was called, but program was already running")
        }

        self.remainingTime = DURATION
        self.isRunning = true
    }

    var minutesRemaining: Int {
        get {
            self.remainingTime / 60
        }
    }

    var secondsRemaining: Int {
        get {
            self.remainingTime % 60
        }
    }

    func tick() -> Int {
        self.remainingTime -= 1
        return self.remainingTime
    }

    func reset() {
        self.timer?.invalidate()
        self.isRunning = false
        self.remainingTime = DURATION
    }

    func RemainingButtonTitle() -> String {
        return String(format: "🙈 %02d:%02d", self.minutesRemaining, self.secondsRemaining)
    }

}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var eventMonitor: Any?
    var state: State = State()

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
                self.statusItem.menu = nil
                return nil
            } else if event.type == .leftMouseDown {
                self.toggleTimer()
                return nil
            }
            return event
        }

        // Set up notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .criticalAlert]) { granted, error in
            if let error = error { print("Notification authorization error: \(error)") }
            if !granted { print("Notification permission denied") }
            else { print("Notification permission granted") }
        }
        
        // Register notification category
        let category = UNNotificationCategory(identifier: "SGSD", actions: [], intentIdentifiers: [], options: [.customDismissAction])
        center.setNotificationCategories([category])
    }

    @objc func toggleTimer() {
        if state.isRunning {
            state.stopRunning()
            statusItem.button?.title = "🙉"
        } else {
            state.startRunning()
            state.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            updateTimer()
        }
    }

    @objc func updateTimer() {

        if state.tick() <= 0 {
            state.reset()

            statusItem.button?.title = "🙉"

            let content = UNMutableNotificationContent()
            content.title = "SGSD"
            content.subtitle = "SGSD Timer"
            content.body = "Time is up! Take a break :)"
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "SGSD"
            content.interruptionLevel = .critical
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "SGSD_\(UUID().uuidString)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error { print("Notification delivery error: \(error)") }
                else { print("Notification scheduled successfully") }
            }
        } else {
            statusItem.button?.title = state.RemainingButtonTitle()
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
