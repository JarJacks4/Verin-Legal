import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAHzk32ercottFmSDgc6vGxVDdXqKG81uo",
            authDomain: "verin-legal-fbzp5w.firebaseapp.com",
            projectId: "verin-legal-fbzp5w",
            storageBucket: "verin-legal-fbzp5w.firebasestorage.app",
            messagingSenderId: "332424564875",
            appId: "1:332424564875:web:6a0fa180c5efa4cb6e848e"));
  } else {
    await Firebase.initializeApp();
  }
}
