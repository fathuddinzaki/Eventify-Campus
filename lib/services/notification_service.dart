import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/event_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service — call once in main.dart
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on Android 13+
    await _requestPermissions();

    _isInitialized = true;
    if (kDebugMode) print('[NotificationService] Initialized successfully');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('[NotificationService] Tapped: ${response.payload}');
    }
  }

  // =============================================
  // NOTIFICATION CHANNEL CONFIGURATION
  // =============================================

  static const _eventChannel = AndroidNotificationDetails(
    'eventify_events',
    'Event Notifications',
    channelDescription: 'Notifikasi saat event dibuat, diubah, atau dihapus',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF6366F1),
    enableVibration: true,
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'eventify_reminders',
    'Event Reminders',
    channelDescription: 'Pengingat sebelum event dimulai',
    importance: Importance.max,
    priority: Priority.max,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFFF59E0B),
    enableVibration: true,
  );

  // =============================================
  // INSTANT NOTIFICATIONS
  // =============================================

  /// Show notification when a new event is created
  Future<void> showEventCreatedNotification(EventModel event) async {
    await _plugin.show(
      event.id.hashCode,
      '✅ Event Baru Ditambahkan',
      '${event.name} — ${event.category}\n📍 ${event.location}',
      const NotificationDetails(
        android: _eventChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'event_created:${event.id}',
    );
  }

  /// Show notification when an event is updated
  Future<void> showEventUpdatedNotification(EventModel event) async {
    await _plugin.show(
      event.id.hashCode + 1000,
      '✏️ Event Diperbarui',
      '${event.name} telah diperbarui\n📍 ${event.location}',
      const NotificationDetails(
        android: _eventChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'event_updated:${event.id}',
    );
  }

  /// Show notification when an event is deleted
  Future<void> showEventDeletedNotification(String eventName) async {
    await _plugin.show(
      eventName.hashCode + 2000,
      '🗑️ Event Dihapus',
      '"$eventName" telah dihapus dari daftar event',
      const NotificationDetails(
        android: _eventChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'event_deleted',
    );
  }

  // =============================================
  // SCHEDULED REMINDER NOTIFICATIONS
  // =============================================

  /// Schedule a reminder notification 1 day before event
  Future<void> scheduleEventReminder(EventModel event) async {
    final reminderTime = event.date.subtract(const Duration(days: 1));

    // Don't schedule if reminder time already passed
    if (reminderTime.isBefore(DateTime.now())) {
      if (kDebugMode) print('[NotificationService] Reminder time already passed for: ${event.name}');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    try {
      await _plugin.zonedSchedule(
        event.id.hashCode + 5000, // Unique ID for reminder
        '⏰ Pengingat Event Besok!',
        '${event.name} akan dilaksanakan besok\n📍 ${event.location}',
        scheduledDate,
        const NotificationDetails(
          android: _reminderChannel,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'event_reminder:${event.id}',
      );

      if (kDebugMode) {
        print('[NotificationService] Reminder scheduled for: ${event.name} at $scheduledDate');
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Failed to schedule reminder: $e');
    }
  }

  /// Schedule a reminder notification 1 hour before event
  Future<void> scheduleEventReminderHourBefore(EventModel event) async {
    final reminderTime = event.date.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    try {
      await _plugin.zonedSchedule(
        event.id.hashCode + 6000,
        '🔔 Event Dimulai 1 Jam Lagi!',
        '${event.name}\n📍 ${event.location}',
        scheduledDate,
        const NotificationDetails(
          android: _reminderChannel,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'event_reminder_hour:${event.id}',
      );
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Failed to schedule 1h reminder: $e');
    }
  }

  /// Cancel all reminders for a specific event
  Future<void> cancelEventReminders(String eventId) async {
    try {
      await _plugin.cancel(eventId.hashCode + 5000);
      await _plugin.cancel(eventId.hashCode + 6000);
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Error in cancelEventReminders: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Error in cancelAll: $e');
    }
  }

  /// Get list of pending (scheduled) notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
