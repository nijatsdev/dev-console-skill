---
tags: [skill-creator]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

my app (SwiftUI, it's in this folder) has like 14 screens incl 3 onboarding steps, a paywall and a bunch of sheets. when I'm designing I keep having to tap through onboarding on my phone to get to the screen I'm tweaking. I want to sit at my laptop and click "paywall" or "onboarding step 3" and have the running debug build on my phone or the simulator jump there, and send me back a screenshot so I can see it on the laptop. theres also a "simulate offline" switch in NetworkClient I'd like to flip from the laptop. write the mac side and the app side, dont run anything

Input files: Lumen/App/LumenApp.swift, Lumen/App/Router.swift, Lumen/Views/Screens.swift, Lumen/Net/NetworkClient.swift
