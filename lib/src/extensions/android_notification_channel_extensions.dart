import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_messaging_handler/src/models/notification_channel_data.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../extensions/notification_importance_enum_extensions.dart';

extension NotificationChannelDataFlutterLocalNotifications
    on NotificationChannelData {
  /// Converts this model into the Android channel object expected by
  /// `flutter_local_notifications`.
  AndroidNotificationChannel toAndroidNotificationChannel() {
    return AndroidNotificationChannel(
      id,
      name,
      description: description,
      groupId: groupId,
      importance: importance.getConvertedImportance,
      playSound: playSound,
      sound: soundPath != null
          ? RawResourceAndroidNotificationSound(soundPath)
          : null,
      enableVibration: enableVibration,
      vibrationPattern: vibrationPattern,
      showBadge: showBadge,
      enableLights: enableLights,
      ledColor: ledColor,
    );
  }
}

extension AndroidNotificationChannelCopyWith on AndroidNotificationChannel {
  AndroidNotificationChannel copyWith({
    String? id,
    String? name,
    String? description,
    String? groupId,
    Importance? importance,
    bool? playSound,
    AndroidNotificationSound? sound,
    bool? enableVibration,
    Int64List? vibrationPattern,
    bool? showBadge,
    bool? enableLights,
    Color? ledColor,
  }) {
    return AndroidNotificationChannel(
      id ?? this.id,
      name ?? this.name,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      importance: importance ?? this.importance,
      playSound: playSound ?? this.playSound,
      sound: sound ?? this.sound,
      enableVibration: enableVibration ?? this.enableVibration,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      showBadge: showBadge ?? this.showBadge,
      enableLights: enableLights ?? this.enableLights,
      ledColor: ledColor ?? this.ledColor,
    );
  }
}
