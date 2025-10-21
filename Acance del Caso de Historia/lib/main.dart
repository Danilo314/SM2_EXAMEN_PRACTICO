import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 📨 Handler cuando el mensaje llega en background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    "📩 Mensaje recibido en background: ${message.notification?.title}",
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ❌ Eliminado Firebase App Check (ya no se usa)
  print("🚫 Firebase App Check desactivado para entorno de desarrollo.");

  // 🔔 Solicitar permisos para notificaciones
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('🔐 Permisos de notificaciones: ${settings.authorizationStatus}');
  await messaging.subscribeToTopic("mascotas");

  // 🔧 Inicializar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 🧠 Configurar handler de mensajes en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 📩 Escuchar mensajes en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('🔔 Mensaje recibido: ${message.notification?.title}');
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Notificaciones SOS Mascota',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  // 🧩 Actualizar token FCM del usuario autenticado (si existe)
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({'token': token});
      debugPrint("✅ Token actualizado para ${user.email}");
    }
  }

  runApp(const MyApp());
}
