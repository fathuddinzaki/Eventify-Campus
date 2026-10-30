import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../services/database_helper.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final EventService _eventService = EventService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool _notificationsEnabled = true;
  UserModel? _currentUser;
  List<EventModel> _events = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  // Subscriptions
  StreamSubscription<List<EventModel>>? _eventsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  bool get notificationsEnabled => _notificationsEnabled;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<EventModel> get events => _events;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Filtered event list based on search and category tab
  List<EventModel> get filteredEvents {
    return _events.where((event) {
      final matchesSearch = event.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.pic.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.location.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'Semua' || 
          event.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Get statistics
  int get totalEventsCount => _events.length;
  int get activeEventsCount => _events.where((e) => e.status == 'Aktif').length;
  int get completedEventsCount => _events.where((e) => e.status == 'Selesai').length;

  AppState() {
    _initializeState();
  }

  // Initial load
  Future<void> _initializeState() async {
    _isLoading = true;
    notifyListeners();

    // Load notification preference
    _notificationsEnabled = await DatabaseHelper.isNotificationEnabled();

    // Try to auto-login cached user
    await refreshCurrentUser();

    // Load events
    await loadEventsData();

    _isLoading = false;
    notifyListeners();
  }

  // Refresh User State
  Future<void> refreshCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  // Load events from Firestore (real-time stream)
  Future<void> loadEventsData() async {
    // Cancel active stream subscription if any
    await _eventsSubscription?.cancel();

    // Load real-time stream from Cloud Firestore
    _eventsSubscription = _eventService.getEventsStream().listen((fetchedEvents) {
      _events = fetchedEvents;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error loading events: $error');
    });
  }

  // Search & Filter actions
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // --- NOTIFICATION ACTIONS ---

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await DatabaseHelper.setNotificationEnabled(enabled);

    if (!enabled) {
      // Cancel all pending notifications
      await _notificationService.cancelAll();
    } else {
      // Reschedule reminders for all active events
      for (final event in _events.where((e) => e.status == 'Aktif')) {
        await _notificationService.scheduleEventReminder(event);
        await _notificationService.scheduleEventReminderHourBefore(event);
      }
    }

    notifyListeners();
  }

  // --- AUTH ACTIONS ---

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      // Reload events to sync
      await loadEventsData();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String nim,
    required String major,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
        nim: nim,
        major: major,
      );
      // Reload events
      await loadEventsData();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    await _notificationService.cancelAll();
    _currentUser = null;
    _eventsSubscription?.cancel();
    _events = [];
    notifyListeners();
  }

  // --- CRUD ACTIONS ---

  Future<void> addEvent({
    required String name,
    required String pic,
    required DateTime date,
    required String location,
    required String description,
    required String status,
    required String category,
  }) async {
    final newEvent = EventModel(
      id: FirebaseFirestore.instance.collection('events').doc().id,
      name: name,
      pic: pic,
      date: date,
      location: location,
      description: description,
      status: status,
      category: category,
      createdAt: DateTime.now(),
    );

    await _eventService.addEvent(newEvent);

    // Send notification
    if (_notificationsEnabled) {
      await _notificationService.showEventCreatedNotification(newEvent);

      // Schedule reminders if event is active
      if (status == 'Aktif') {
        await _notificationService.scheduleEventReminder(newEvent);
        await _notificationService.scheduleEventReminderHourBefore(newEvent);
      }
    }
  }

  Future<void> updateEvent({
    required String id,
    required String name,
    required String pic,
    required DateTime date,
    required String location,
    required String description,
    required String status,
    required String category,
    required DateTime createdAt,
  }) async {
    final updatedEvent = EventModel(
      id: id,
      name: name,
      pic: pic,
      date: date,
      location: location,
      description: description,
      status: status,
      category: category,
      createdAt: createdAt,
    );

    await _eventService.updateEvent(updatedEvent);

    // Send notification
    if (_notificationsEnabled) {
      await _notificationService.showEventUpdatedNotification(updatedEvent);

      // Reschedule reminders
      await _notificationService.cancelEventReminders(id);
      if (status == 'Aktif') {
        await _notificationService.scheduleEventReminder(updatedEvent);
        await _notificationService.scheduleEventReminderHourBefore(updatedEvent);
      }
    }
  }

  Future<void> deleteEvent(String id) async {
    // Find event name before deletion for notification
    final eventName = _events.firstWhere(
      (e) => e.id == id,
      orElse: () => EventModel(
        id: '', name: 'Event', pic: '', date: DateTime.now(),
        location: '', description: '', status: '', category: '', createdAt: DateTime.now(),
      ),
    ).name;

    await _eventService.deleteEvent(id);

    // Send notification & cancel reminders
    if (_notificationsEnabled) {
      await _notificationService.showEventDeletedNotification(eventName);
      await _notificationService.cancelEventReminders(id);
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
