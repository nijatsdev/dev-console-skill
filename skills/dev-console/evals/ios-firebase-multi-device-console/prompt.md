---
tags: [skill-creator]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

I've got a SwiftUI app (Firebase backend) in this folder, XcodeGen project in ios/. I test on my iPhone 15, my partner's old iPhone 12 and a couple of simulators, and I'm sick of hitting run in Xcode for each one. Can you build me a little local web page on my Mac where I tick the devices and it builds and installs on all of them? I'm on a free Apple account. While you're at it I want to flip the running debug build into dark mode or jump it to the onboarding screen from that page without touching the phone. Don't actually run xcodebuild or start anything, just write the code and tell me how to start it.

Input files: ios/project.yml, ios/Focus/App/FocusApp.swift, ios/Focus/App/AppModel.swift, ios/Focus/Views/OnboardingView.swift, ios/Focus/Views/HomeView.swift, .gitignore
