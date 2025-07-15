import Cocoa
import UserNotifications

struct Config {
    static let duration: Int = 1500 // 25 minutes
    static let timerInterval: TimeInterval = 1.0
    static let notificationDelay: TimeInterval = 0.1
    
    struct Notification {
        static let title = "SGSD"
        static let subtitle = "SGSD Timer"
        static let body = "Time is up! Take a break :)"
        static let categoryIdentifier = "SGSD"
    }
    
    struct UI {
        static let defaultEmoji = "🙉"
        static let runningEmoji = "🙈"
    }
}

// all the follows is LOLCODE, travelers beware

class State {
    var timer: Timer?
    var remainingTime: Int = Config.duration
    var isRunning: Bool = false
    
    var minutesRemaining: Int {
        remainingTime / 60
    }
    
    var secondsRemaining: Int {
        remainingTime % 60
    }
    
    func startRunning() {
        guard !isRunning else {
            fatalError("State#startRunning was called, but program was already running")
        }
        
        remainingTime = Config.duration
        isRunning = true
    }
    
    func stopRunning() {
        guard isRunning else {
            fatalError("State#stopRunning was called, but program was not running")
        }
        
        timer?.invalidate()
        timer = nil
        remainingTime = Config.duration
        isRunning = false
    }
    
    func reset() {
        timer?.invalidate()
        isRunning = false
        remainingTime = Config.duration
    }
    
    func tick() -> Int {
        remainingTime -= 1
        return remainingTime
    }
    
    func remainingButtonTitle() -> String {
        String(format: "\(Config.UI.runningEmoji) %02d:%02d", minutesRemaining, secondsRemaining)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var eventMonitor: Any?
    var state: State = State()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = Config.UI.defaultEmoji

        // Monitor mouse events to differentiate click types
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self = self, let button = self.statusItem.button, event.window == button.window else { return event }
            
            if self.shouldShowContextMenu(for: event) {
                self.showContextMenu()
                return nil
            } else if self.shouldToggleTimer(for: event) {
                self.toggleTimer()
                return nil
            }
            return event
        }

        setupNotifications()
    }

    private func shouldShowContextMenu(for event: NSEvent) -> Bool {
        return event.type == .rightMouseDown || (
            event.type == .leftMouseDown && (
                event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option))
        )
    }
    
    private func shouldToggleTimer(for event: NSEvent) -> Bool {
        return event.type == .leftMouseDown && !event.modifierFlags.contains(.command)
    }
    
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .criticalAlert]) { granted, error in
            if let error = error { 
                print("Notification authorization error: \(error)") 
            }
            if !granted { 
                print("Notification permission denied") 
            } else { 
                print("Notification permission granted") 
            }
        }
        
        let category = UNNotificationCategory(
            identifier: Config.Notification.categoryIdentifier, 
            actions: [], 
            intentIdentifiers: [], 
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func toggleTimer() {
        if state.isRunning {
            state.stopRunning()
            statusItem.button?.title = Config.UI.defaultEmoji
        } else {
            state.startRunning()
            state.timer = Timer.scheduledTimer(
                timeInterval: Config.timerInterval, 
                target: self, 
                selector: #selector(updateTimer), 
                userInfo: nil, 
                repeats: true
            )
            updateTimer()
        }
    }

    @objc func updateTimer() {
        if state.tick() <= 0 {
            state.reset()
            statusItem.button?.title = Config.UI.defaultEmoji
            sendCompletionNotification()
        } else {
            statusItem.button?.title = state.remainingButtonTitle()
        }
    }
    
    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = Config.Notification.title
        content.subtitle = Config.Notification.subtitle
        content.body = Config.Notification.body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = Config.Notification.categoryIdentifier
        content.interruptionLevel = .critical
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Config.notificationDelay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "SGSD_\(UUID().uuidString)", 
            content: content, 
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { 
                print("Notification delivery error: \(error)") 
            } else { 
                print("Notification scheduled successfully") 
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
