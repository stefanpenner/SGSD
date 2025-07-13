main: SGSD.app/Contents/MacOS/SGSD

SGSD.app/Contents/MacOS/SGSD: main.swift
	swiftc main.swift -o SGSD.app/Contents/MacOS/SGSD -framework Cocoa -framework UserNotifications

clean:
	rm -rf SGSD.app/Contents/MacOS/SGSD
