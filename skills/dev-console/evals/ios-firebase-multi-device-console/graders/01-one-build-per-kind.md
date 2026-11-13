---
type: llm
focus: trace
weight: 1
---

The build step compiles once per device kind (one build for phones, one for simulators) and then installs on every picked device of that kind; a per-phone build happens only as a fallback, for example to register a phone that is not in the signing profile yet.
