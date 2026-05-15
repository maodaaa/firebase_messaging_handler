---
layout: page
title: Scheduling
---

# Scheduling

The package exposes one-time and recurring local notification scheduling on top of `flutter_local_notifications`.

Scheduling is best paired with:

- notification channels
- quiet hours
- analytics callbacks

## Timezone handling

Scheduled notifications use the device timezone. During initialization, the package loads timezone data, reads the device timezone with `flutter_timezone`, and sets `tz.local` before any `zonedSchedule` call.

If your app supports reminders or alarms, call `refreshLocalTimezone()` when the app resumes before rescheduling reminders. This keeps reminder times aligned when users travel or manually change their system timezone.

```dart
final String? timezone =
    await FirebaseMessagingHandler.instance.refreshLocalTimezone();

final diagnostics =
    await FirebaseMessagingHandler.instance.runDiagnostics();

print(timezone);
print(diagnostics.metadata['configuredTimezone']);
```

## One-time schedule

```dart
await FirebaseMessagingHandler.instance.scheduleNotification(
  id: 1001,
  title: 'Reminder',
  body: 'Time to check in.',
  scheduledDate: DateTime.now().add(const Duration(minutes: 10)),
  payload: {'route': '/check-in'},
);
```

## Recurring schedule

```dart
await FirebaseMessagingHandler.instance.scheduleRecurringNotification(
  id: 2001,
  title: 'Daily check-in',
  body: 'Take a moment for yourself.',
  repeatInterval: 'daily',
  hour: 9,
  minute: 0,
  payload: {'route': '/check-in'},
);
```

For selected weekdays such as Monday, Wednesday, and Friday, schedule one weekly notification per selected day with a stable ID for each day.

```dart
await FirebaseMessagingHandler.instance.scheduleWeeklyNotification(
  id: 3001,
  title: 'Monday check-in',
  body: 'Take a moment for yourself.',
  weekday: DateTime.monday,
  hour: 9,
  minute: 0,
  payload: {'route': '/check-in'},
);
```
