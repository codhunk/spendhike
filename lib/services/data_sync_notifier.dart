import 'package:flutter/material.dart';

/// Global notifier for real-time UI data synchronization across screens.
/// Whenever backend data changes (new transaction, new group, profile edit),
/// calling `DataSyncNotifier.instance.notifyDataChanged()` triggers all active
/// screen listeners to re-fetch live data from MongoDB.
class DataSyncNotifier extends ChangeNotifier {
  static final DataSyncNotifier instance = DataSyncNotifier._internal();
  DataSyncNotifier._internal();

  int _version = 0;
  int get version => _version;

  void notifyDataChanged() {
    _version++;
    notifyListeners();
  }
}
