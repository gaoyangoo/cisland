# Capsule Tab Bar + Info Page Redesign

**Date:** 2026-06-23
**Status:** Approved

## Overview

Redesign the bottom tab bar into a capsule/pill style, smooth tab-switching animations with dynamic height, and redesign the Info page's three-card layout.

## Part 1: Capsule Tab Bar

### Current
- `ExpandedIslandView.bottomTabBar`: simple HStack of icon+text buttons
- Active state: only color change, no background

### Target
- Semi-transparent rounded background strip (`white.opacity(0.08)`, capsule shape)
- `matchedGeometryEffect` moves a filled pill behind the active tab
- Active pill uses module's `accentColor`, shows icon + displayName
- Inactive tabs: gray icon + text
- Spring animation on selection change

### Files to modify
- `cisland/Views/ExpandedIslandView.swift` — replace `bottomTabBar`
- Can remove `cisland/Views/TabBarView.swift` and `cisland/Views/ModuleIcon.swift` if no longer referenced

## Part 2: Smooth Tab Switching & Dynamic Height

### Current
- `AppDelegate` hardcodes `tabHeights: [CGFloat] = [160, 390, 390]`
- `setFrame(..., animate: true)` — NSWindow linear animation, no content transition

### Target
- Remove hardcoded `tabHeights` from AppDelegate
- Each module's content determines its own height naturally
- SwiftUI reports height to AppDelegate via `PreferenceKey`
- AppDelegate animates window frame with `NSAnimationContext.runAnimationGroup`
- Content cross-fades: opacity transition with spring

### Files to modify
- `cisland/App/AppDelegate.swift` — replace hardcoded heights with PreferenceKey listener
- `cisland/Views/ExpandedIslandView.swift` — add GeometryReader + PreferenceKey for height

## Part 3: Info Page Three-Column Redesign

### Current
- `InfoDashboardView` in ExpandedIslandView: three VStacks with icon, title, placeholder content
- Fixed height 120px, very basic

### Target
- Three equal-width columns, no icons, no section titles
- **Music card (left):**
  - Album art (rounded rect, primary visual)
  - Song name + artist name below (single line each, truncate)
- **Calendar card (center):**
  - Horizontal week strip: Mon–Sun abbreviated labels
  - Beneath each day: colored gradient bar if events exist (different colors per calendar)
  - Bottom: current time in gradient text (e.g., purple→blue)
- **Weather card (right):**
  - Weather SF Symbol icon
  - Large temperature number
  - City name below
- Three cards equal height (~130px), `white.opacity(0.06)` background, corner radius 10
- Cards use real data from MusicService, CalendarService, WeatherService

### Files to modify
- `cisland/Views/ExpandedIslandView.swift` — rewrite `InfoDashboardView`
- May reference existing service models (MusicService, CalendarService, WeatherService) — read their APIs

## Self-Review

- **[x]** No placeholders — all sections have concrete spec
- **[x]** Internally consistent — parts 1-3 work together in ExpandedIslandView
- **[x]** Scoped — single file is the main change surface (ExpandedIslandView + AppDelegate)
- **[x]** No ambiguity — each card's content is specified
