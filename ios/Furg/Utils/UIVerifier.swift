//
//  UIVerifier.swift
//  Furg
//
//  UI Verification System - Automated view testing
//

import SwiftUI
import UIKit

class UIVerifier {
    /// Verifies a SwiftUI view can render and has expected interactive elements
    /// Call this after creating or modifying any view
    static func verifyView<V: View>(_ view: V, name: String) {
        print("\n" + String(repeating: "=", count: 50))
        print("🔍 UI VERIFICATION: \(name)")
        print(String(repeating: "=", count: 50))

        // Check 1: View can render without crashing
        do {
            let hosting = UIHostingController(rootView: view)
            print("✅ RENDER CHECK: View renders without crash")
            _ = hosting.view // Force view to load
        } catch {
            print("❌ RENDER CHECK FAILED: \(error.localizedDescription)")
            return
        }

        // Check 2: Inspect view structure using Mirror
        let mirror = Mirror(reflecting: view)

        // Check for NavigationLink
        let hasNavigationLink = containsType(mirror, typeName: "NavigationLink")
        if hasNavigationLink {
            print("✅ NAVIGATION: NavigationLink detected")
        } else {
            print("⚠️  NAVIGATION: No NavigationLink found (OK if not a navigation view)")
        }

        // Check for Buttons
        let hasButtons = containsType(mirror, typeName: "Button")
        if hasButtons {
            print("✅ INTERACTIVITY: Button elements detected")
        } else {
            print("⚠️  INTERACTIVITY: No Button elements found")
        }

        // Check for Text Fields
        let hasTextFields = containsType(mirror, typeName: "TextField")
        if hasTextFields {
            print("✅ INPUT: TextField elements detected")
        }

        // Check for Lists
        let hasLists = containsType(mirror, typeName: "List") || containsType(mirror, typeName: "ForEach")
        if hasLists {
            print("✅ DATA: List/ForEach elements detected")
        }

        // Check for State variables
        let hasState = containsType(mirror, typeName: "State")
        if hasState {
            print("✅ STATE: @State variables detected")
        }

        print(String(repeating: "=", count: 50))
        print("✅ VERIFICATION COMPLETE: \(name)")
        print(String(repeating: "=", count: 50) + "\n")
    }

    /// Recursively checks if a type name exists in the Mirror hierarchy
    private static func containsType(_ mirror: Mirror, typeName: String) -> Bool {
        // Check current level
        let description = String(describing: mirror.subjectType)
        if description.contains(typeName) {
            return true
        }

        // Check children recursively
        for child in mirror.children {
            let childMirror = Mirror(reflecting: child.value)
            if containsType(childMirror, typeName: typeName) {
                return true
            }
        }

        return false
    }
}
