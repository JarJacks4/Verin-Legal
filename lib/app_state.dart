import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _accessToken = prefs.getString('ff_accessToken') ?? _accessToken;
    });
    _safeInit(() {
      _refreshToken = prefs.getString('ff_refreshToken') ?? _refreshToken;
    });
    _safeInit(() {
      _tokenExpiresAt = prefs.containsKey('ff_tokenExpiresAt')
          ? DateTime.fromMillisecondsSinceEpoch(
              prefs.getInt('ff_tokenExpiresAt')!)
          : _tokenExpiresAt;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

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

  String _accessToken = '';
  String get accessToken => _accessToken;
  set accessToken(String value) {
    _accessToken = value;
    prefs.setString('ff_accessToken', value);
  }

  String _refreshToken = '';
  String get refreshToken => _refreshToken;
  set refreshToken(String value) {
    _refreshToken = value;
    prefs.setString('ff_refreshToken', value);
  }

  DateTime? _tokenExpiresAt;
  DateTime? get tokenExpiresAt => _tokenExpiresAt;
  set tokenExpiresAt(DateTime? value) {
    _tokenExpiresAt = value;
    value != null
        ? prefs.setInt('ff_tokenExpiresAt', value.millisecondsSinceEpoch)
        : prefs.remove('ff_tokenExpiresAt');
  }

  String _clioAccessToken = '';
  String get clioAccessToken => _clioAccessToken;
  set clioAccessToken(String value) {
    _clioAccessToken = value;
  }

  String _clioRefreshToken = '';
  String get clioRefreshToken => _clioRefreshToken;
  set clioRefreshToken(String value) {
    _clioRefreshToken = value;
  }

  DateTime? _clioTokenExpiresAt;
  DateTime? get clioTokenExpiresAt => _clioTokenExpiresAt;
  set clioTokenExpiresAt(DateTime? value) {
    _clioTokenExpiresAt = value;
  }

  String _smokeballAccessToken = '';
  String get smokeballAccessToken => _smokeballAccessToken;
  set smokeballAccessToken(String value) {
    _smokeballAccessToken = value;
  }

  String _smokeballRefreshToken = '';
  String get smokeballRefreshToken => _smokeballRefreshToken;
  set smokeballRefreshToken(String value) {
    _smokeballRefreshToken = value;
  }

  String _smokeballCodeVerifier = '';
  String get smokeballCodeVerifier => _smokeballCodeVerifier;
  set smokeballCodeVerifier(String value) {
    _smokeballCodeVerifier = value;
  }

  String _myCaseAccessToken = '';
  String get myCaseAccessToken => _myCaseAccessToken;
  set myCaseAccessToken(String value) {
    _myCaseAccessToken = value;
  }

  String _myCaseRefreshToken = '';
  String get myCaseRefreshToken => _myCaseRefreshToken;
  set myCaseRefreshToken(String value) {
    _myCaseRefreshToken = value;
  }

  DateTime? _myCaseTokenExpiresAt;
  DateTime? get myCaseTokenExpiresAt => _myCaseTokenExpiresAt;
  set myCaseTokenExpiresAt(DateTime? value) {
    _myCaseTokenExpiresAt = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
