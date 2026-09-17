import 'package:flutter/material.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _filterStatus = '';
  String get filterStatus => _filterStatus;
  set filterStatus(String value) {
    _filterStatus = value;
  }

  String _filterMatterType = '';
  String get filterMatterType => _filterMatterType;
  set filterMatterType(String value) {
    _filterMatterType = value;
  }

  String _sortOption = '';
  String get sortOption => _sortOption;
  set sortOption(String value) {
    _sortOption = value;
  }

  List<String> _filteredList = [];
  List<String> get filteredList => _filteredList;
  set filteredList(List<String> value) {
    _filteredList = value;
  }

  void addToFilteredList(String value) {
    filteredList.add(value);
  }

  void removeFromFilteredList(String value) {
    filteredList.remove(value);
  }

  void removeAtIndexFromFilteredList(int index) {
    filteredList.removeAt(index);
  }

  void updateFilteredListAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    filteredList[index] = updateFn(_filteredList[index]);
  }

  void insertAtIndexInFilteredList(int index, String value) {
    filteredList.insert(index, value);
  }
}
