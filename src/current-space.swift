#!/usr/bin/env swift
//
// Detects the current macOS space (desktop) number.
// Uses private Core Graphics APIs.
//

import Foundation

// Private CGS functions for space management
@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ connection: Int32) -> CFArray

@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ connection: Int32) -> Int

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int32

func getCurrentSpaceNumber() -> Int? {
    let conn = CGSMainConnectionID()
    let activeSpaceID = CGSGetActiveSpace(conn)

    guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [[String: Any]] else {
        return nil
    }

    // Iterate through displays to find our space
    for display in displays {
        guard let spaces = display["Spaces"] as? [[String: Any]] else {
            continue
        }

        for (index, space) in spaces.enumerated() {
            if let spaceID = space["id64"] as? Int, spaceID == activeSpaceID {
                return index + 1  // 1-indexed
            }
            // Fallback to regular id
            if let spaceID = space["ManagedSpaceID"] as? Int, spaceID == activeSpaceID {
                return index + 1
            }
        }
    }

    return nil
}

func getTotalSpaces() -> Int {
    let conn = CGSMainConnectionID()

    guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [[String: Any]] else {
        return 0
    }

    var total = 0
    for display in displays {
        if let spaces = display["Spaces"] as? [[String: Any]] {
            total += spaces.count
        }
    }

    return total
}

// Main
if let currentSpace = getCurrentSpaceNumber() {
    let totalSpaces = getTotalSpaces()
    print("\(currentSpace)/\(totalSpaces)")
} else {
    fputs("Error: Could not detect current space\n", stderr)
    exit(1)
}
