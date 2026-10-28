# VXDeck — Initial MVP Scope

**Project:** `vx_deck`  
**Platform:** macOS only  
**Status:** Initial scope for agent discovery and implementation planning  
**Goal:** A lightweight, manually curated application launcher displayed as a floating popup.

## 1. Problem & vision

macOS 26's replacement for the old Launchpad does not meet the user's preference for manually arranging applications spatially. The goal is **not** to recreate Launchpad or Spotlight. VXDeck is a compact, user-curated **collection board**: open a popup, see selected apps grouped by collection, and launch any app with one click.

## 2. Core experience / happy path

1. User launches or activates VXDeck from its Dock icon.
2. A borderless floating popup appears promptly above normal windows, at a sensible position on the current display.
3. The popup displays collections stacked vertically. Each collection has a title and a wrapping grid of application icons with short labels, as in the supplied wireframe.
4. User clicks an app icon once; macOS launches or activates that app.
5. The popup hides after launching an app by default. Clicking outside or pressing Escape also hides it. Hiding does **not** quit VXDeck.
6. Activating VXDeck again shows the saved layout immediately.

**UX clarification:** The exact behavior of auto-hiding after launching was not settled in the discussion. Treat the default above as a provisional MVP choice, and keep it easy to change. Do not implement elaborate preferences solely for this.

## 3. Functional scope — MVP

### 3.1 Popup behavior
- A single borderless floating popup; no normal title bar or traffic-light controls.
- Dock activation shows or re-shows the popup; activating while already visible should not create duplicates.
- Hide on outside click and Escape, subject to correct drag-and-drop handling.
- Popup is scrollable vertically when collections exceed available screen height.
- Fixed or sensible adaptive width for MVP; no requirement for user-controlled resizing.
- Correct activation/focus when launching another app; do not steal focus back.
- Support re-opening reliably after popup is dismissed.

### 3.2 Collections
- Create, rename, and delete collections.
- Display collections vertically, each with an icon grid that wraps to multiple rows.
- Manually reorder collections if practical; otherwise explicitly defer with rationale.
- Deleting a collection removes **only its VXDeck configuration**, never installed apps.

### 3.3 Application selection and launch
- Explicit **Add App** flow: select an installed `.app` from Applications or another user-selected location, with a simple native picker or app list.
- Show each selected app's actual macOS icon and readable name.
- Launch/activate selected app with one click through supported macOS APIs.
- Remove app from a collection without uninstalling or modifying the app.
- Allow an app to appear in more than one collection if simple; document chosen behavior.
- Store a stable identifier where possible (e.g. bundle ID) plus a fallback path; handle moved/missing apps gracefully without silently launching a different app.
- No automatic population of the main board with every installed app.

### 3.4 Manual arrangement
- Drag to reorder app icons within a collection.
- Drag apps between collections.
- Persist the resulting order.
- Avoid accidental launch while dragging.
- Provide a clear **Edit Mode** for adding, removing, and rearranging; while editing, do not hide the popup unexpectedly on routine focus changes or during a drag.

### 3.5 Persistence
- Save collections, app references, and ordering locally.
- Restore the same layout after quitting/restarting VXDeck or rebooting macOS.
- Use a simple local format (JSON is sufficient); write atomically where practical to avoid corrupting the layout on interrupted saves.
- No account, cloud sync, backend, or telemetry.

## 4. Non-goals

- Rebuilding the full-screen Launchpad or multi-page Launchpad experience.
- Spotlight replacement, fuzzy search, global file indexing, or full-system search.
- App installation, uninstallation, updates, package management, or process monitoring.
- Modifying Dock internals or replacing the Dock.
- The separate **Dock App Groups** idea (placing a group among normal Dock apps).
- Windows support, mobile support, cloud sync, multi-device sync.
- Menu bar integration, auto-start at login, global hotkey, themes, and complex settings in the first iteration.
- Requiring administrator privileges or sensitive system permissions without clear justification.

## 5. Proposed implementation approach (not a hard requirement)

- **Preferred:** SwiftUI for the board, AppKit for popup/window activation and macOS app APIs (e.g. `NSPanel`, `NSWorkspace`).
- **Build constraint:** Prefer an agent-operated terminal workflow using Swift Package Manager and installed Xcode Command Line Tools, **without requiring full Xcode IDE if feasible**.
- **Discovery gate:** Before committing to implementation, verify whether the installed CLT/macOS SDK can compile, link, bundle, and run the needed SwiftUI/AppKit application on this machine. If full Xcode or additional tooling is actually required, report the precise blocker and alternatives; do not silently assume it is installed.
- Build a real launchable `.app` bundle; running `swift build` alone is not equivalent to a complete usable macOS app.
- Keep architecture minimal; no server, database server, or unnecessary abstractions.

## 6. Safety constraints

- **Read/launch only:** VXDeck must not alter installed `.app` bundles or files within them.
- Deleting collections or shortcuts only changes VXDeck's own saved configuration.
- No shell-based launching with unsanitized app paths; prefer native macOS launch APIs.
- No destructive filesystem operations, admin permissions, accessibility permissions, or broad disk access unless explicitly justified and approved.
- On missing/uninstalled apps, show a clear unavailable state and let user remove or reselect the reference.

## 7. Acceptance criteria

1. Launch VXDeck from Dock → exactly one popup appears, with no title bar.
2. Create at least three collections; add several real apps to each.
3. Icons and names reflect the selected apps.
4. Single-click an icon → correct app launches/activates.
5. Click outside / Escape → popup hides; Dock activation reopens it.
6. Reorder icons within a collection and move one between collections; positions remain after restart.
7. Edit Mode does not close mid-drag or inadvertently launch an app.
8. Remove a shortcut or collection → installed applications remain untouched.
9. Rename/move/remove a referenced app → VXDeck fails gracefully, without crashes or silently launching an unintended target.
10. Long collections scroll correctly and the popup remains usable on the current display.
11. Confirm a runnable `.app` is produced and manually test on the actual macOS machine; a successful build alone is insufficient.

## 8. Agent handoff — first task

1. Inspect the current macOS version, installed CLT/Swift toolchain, and feasibility of SwiftUI + AppKit without full Xcode.
2. Recommend the smallest viable architecture and flag genuine technical blockers.
3. Build a **vertical slice** first: launchable `.app` → Dock activation → floating popup → one collection → select one `.app` → click to launch → hide/reopen → persist.
4. Only after the vertical slice is verified, add multiple collections, Edit Mode, drag-and-drop, and persistence of ordering.
5. Run appropriate checks and report exactly what was manually verified vs. only compiled or unit-tested.
6. Follow existing workspace/global `AGENTS.md` rules. Do not commit, push, or release unless separately instructed.

## 9. Open decisions (do not silently expand scope)

- Popup placement: screen center vs. near Dock icon; prefer reliable placement over imitating a native Dock popover.
- Hide after app launch: provisional **yes**, but user may choose to keep it open for batch launching.
- Collection reordering: MVP if straightforward; otherwise backlog.
- Duplicate app shortcuts across collections: permit if implementation stays simple.

**Product principle:** Organize only the applications the user chooses, keep them visible in named collections, and open any app in one click. Avoid building another Launchpad.
