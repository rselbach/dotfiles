# Bug Fixes for Jabber

## Summary
Found and will fix 4 legitimate bugs/issues in the Jabber audio dictation app:
1. **HIGH**: OutputManager returns wrong accessibility permission status
2. **MEDIUM**: ModelManager silently ignores deletion errors
3. **LOW**: NotificationService has redundant weak capture
4. **LOW**: Error message could be clearer about app state

## Fixes

### 1. OutputManager.checkAccessibilityPermission() - HIGH PRIORITY
**File**: `Sources/Jabber/Services/OutputManager.swift:38-48`

**Bug**: Function returns the *old* permission status, not the updated one after prompting user.

**Fix**:
```swift
func checkAccessibilityPermission() -> Bool {
    let trusted = AXIsProcessTrusted()

    if !trusted {
        // Prompt user to grant permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // Check again - permission might be granted now
        // Note: If just granted, may require app relaunch to take effect
        return AXIsProcessTrusted()
    }

    return true
}
```

### 2. ModelManager.deleteModel() - MEDIUM PRIORITY
**File**: `Sources/Jabber/Services/ModelManager.swift:106-109, 147-156`

**Bug**: Silent returns when model folder doesn't exist - caller can't tell if deletion succeeded or model wasn't found.

**Fix**: Throw error instead of silent return.

Lines 106-109:
```swift
guard let modelPath = Constants.ModelPaths.localModelFolder(for: modelId) else {
    throw ModelError.modelNotFound(modelId: modelId)
}

guard FileManager.default.fileExists(atPath: modelPath.path) else {
    throw ModelError.modelNotFound(modelId: modelId)
}
```

Add new error case to ModelError enum (after line 148):
```swift
enum ModelError: Error, LocalizedError {
    case cannotDeleteActiveModel
    case modelNotFound(modelId: String)

    var errorDescription: String? {
        switch self {
        case .cannotDeleteActiveModel:
            return "Cannot delete the currently active model. Please select a different model first."
        case .modelNotFound(let modelId):
            return "Model '\(modelId)' not found or already deleted."
        }
    }
}
```

### 3. NotificationService - LOW PRIORITY
**File**: `Sources/Jabber/Services/NotificationService.swift:34`

**Issue**: Redundant `[weak self]` capture in inner Task (outer closure already captures weakly).

**Fix**: Remove redundant capture:
```swift
Task { @MainActor in  // No [weak self] needed
    self?.isAuthorized = granted
    if !granted {
        self?.logger.info("User denied notification permissions, will use alert fallback")
    }
}
```

### 4. AppDelegate error message - LOW PRIORITY
**File**: `Sources/Jabber/AppDelegate.swift:80`

**Issue**: Error message doesn't clearly state dictation is unavailable until model loads.

**Fix**: Change line 80 from:
```swift
alert.informativeText = "The transcription model could not be loaded: \(error.localizedDescription)\n\nPlease check your internet connection and try restarting the app."
```

To:
```swift
alert.informativeText = "The transcription model could not be loaded: \(error.localizedDescription)\n\nDictation is unavailable until a model loads successfully. Please check your internet connection and try restarting the app."
```

## Testing Plan
1. Test accessibility permission grant/deny flow
2. Test model deletion with corrupted/missing model folders
3. Test model load failure and verify error message clarity
4. End-to-end dictation test (clipboard + paste modes)

## Files to Modify
- `Sources/Jabber/Services/OutputManager.swift`
- `Sources/Jabber/Services/ModelManager.swift`
- `Sources/Jabber/Services/NotificationService.swift`
- `Sources/Jabber/AppDelegate.swift`
