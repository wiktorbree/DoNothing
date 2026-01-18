
# DoNothing

A simple, offline-first iOS/iPadOS 12-week stimulus detox challenge app.

## How to Run
1. Open `DoNothing.xcodeproj` in Xcode 15+.
2. Ensure the deployment target is set to iOS 17.0+.
3. Run on Simulator or Device.

## Assumptions
- **Start Date**: The challenge does **not** start immediately. It begins only after the first successful session is completed.
- **Timer Rules**: The timer cannot be paused. Stopping the timer early marks the day as **failed**.
- **Calendar**: The calendar always displays the full month view, regardless of whether you have started the challenge or have data.
- **Time Zone**: All dates are normalized to the local start of day.
- **Freeze Logic**: A "bad" rating for 3 consecutive days triggers a freeze suggestion.
- **Backgrounding**: The timer uses system clock comparison (`Date()`), so it is accurate even if the app is backgrounded.

## Project Structure
- `Features/`: Contains UI screens grouped by feature (Home, Timer, Calendar, etc.).
- `Services/`: Core logic (`ChallengeEngine`) and system integrations (`NotificationManager`).
- `Models/`: SwiftData models (`ChallengeState`, `DayLog`).
- `Utils/`: Helpers.

## Reminders
To change the default reminder behavior, look at `Services/NotificationManager.swift`.
To change the default reminder time, go to `Settings` in the app.
