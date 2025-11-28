# Xcode Project Settings Guide

## When Creating New Project

### Testing System
**Choose: XCTest** ✅

- **XCTest** - Standard iOS testing framework (recommended)
  - Built into Xcode
  - Works with Swift and Objective-C
  - Easy to write unit tests and UI tests
  - You can add tests later if needed

- Other options (if available):
  - **None** - Only if you're absolutely sure you won't write tests
  - Usually XCTest is the best choice

### Storage
**Choose: None** ✅

- **None** - No local database framework
  - ✅ **Recommended for this project**
  - We use backend API (PostgreSQL) for all data storage
  - Data is fetched from server, not stored locally
  - Simpler project setup

- Other options (NOT needed for this project):
  - **Core Data** - Local SQLite database (we don't need this)
  - **CloudKit** - Apple's cloud storage (we use our own backend)
  - **SwiftData** - New framework (not needed, we have backend)

### Why These Choices?

**Storage: None**
- All data (users, pairs, love events) is stored on backend
- App only caches data temporarily in memory
- No need for local database
- Simpler architecture

**Testing System: XCTest**
- Standard choice for iOS projects
- You can add tests later if needed
- Doesn't hurt to have it enabled
- Easy to remove test targets later if you don't use them

## Complete Settings Summary

When creating project, use these settings:

| Setting | Value | Reason |
|---------|-------|--------|
| Product Name | `LoveConnection` | App name |
| Team | Your team or None | For signing |
| Organization ID | `com.yourcompany` | Bundle identifier prefix |
| Interface | **SwiftUI** | We use SwiftUI |
| Language | **Swift** | We use Swift |
| Storage | **None** ✅ | Backend handles storage |
| Testing System | **XCTest** ✅ | Standard testing |
| Include Tests | Optional | Can add later |

## After Project Creation

If you accidentally chose wrong options:

### Change Storage (if you chose Core Data by mistake)
1. Delete `LoveConnection.xcdatamodeld` file if it exists
2. Remove Core Data imports from code
3. That's it - we don't use Core Data

### Change Testing System
- Usually can't change after creation
- But you can delete test targets if you don't need them
- Or just ignore them if you don't write tests

## What We Actually Use for Storage

- **Backend API** - All persistent data
- **Keychain** - Secure token storage (already implemented)
- **UserDefaults** - Optional app preferences (not used currently)
- **In-memory** - Temporary data during app session

No local database needed! 🎉

