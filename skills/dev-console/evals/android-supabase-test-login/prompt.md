---
tags: [skill-creator]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Android app (Kotlin, Compose) on Supabase, project is in this folder. I have about 20 test accounts and a few hundred real beta users in the same Supabase project. I want a page on my Mac where I pick a test account and the debug build on my Pixel 8 (over USB or wifi) or the emulator logs in as that person, no password typing. I have the service role key. Also show me the open rows in the `reports` table on that page. Write the code, don't run it, and tell me where to put the key.

Input files: settings.gradle.kts, app/build.gradle.kts, app/src/main/AndroidManifest.xml, app/src/main/java/com/example/kite/MainActivity.kt, app/src/main/java/com/example/kite/Supabase.kt, .gitignore
