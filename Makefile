main: SGSD.app/Contents/MacOS/SGSD
	codesign --force --deep --sign - --entitlements SGSD.app/Contents/SGSD.entitlements SGSD.app

SGSD.app/Contents/MacOS/SGSD: main.swift
	mkdir -p SGSD.app/Contents/MacOS/
	swiftc main.swift -o SGSD.app/Contents/MacOS/SGSD -framework Cocoa -framework UserNotifications

clean:
	git clean -fdx

run: main
	open SGSD.app

reset: 
	tccutil reset All net.iamstef.SGSD
