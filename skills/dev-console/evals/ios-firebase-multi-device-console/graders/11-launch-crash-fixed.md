---
type: llm
focus: trace
weight: 1
---

The app no longer crashes at launch: FirebaseApp.configure() runs before anything calls Auth.auth(), so the AppModel created as a @State default no longer reaches Firebase first.
