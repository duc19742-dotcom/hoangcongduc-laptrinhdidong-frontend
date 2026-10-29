import 'dart:async';

import 'package:flutter/material.dart';

import 'features/auth/auth_screen.dart';
import 'features/home_screen.dart';
import 'state/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  runApp(AttendanceApp(session));
  unawaited(session.restore());
}

class AttendanceApp extends StatefulWidget {
  final Session session;
  const AttendanceApp(this.session, {super.key});
  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends State<AttendanceApp> {
  final navigator = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    widget.session.addListener(changed);
  }

  void changed() {
    if (!widget.session.initializing && widget.session.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.currentState?.popUntil((r) => r.isFirst);
      });
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Đức Attendance',
    debugShowCheckedModeBanner: false,
    navigatorKey: navigator,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff155eef)),
      scaffoldBackgroundColor: const Color(0xfff5f7fb),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff5f7fb),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xffe7ecf3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorMaxLines: 3,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffdce3ed)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffdce3ed)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
    home: AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => widget.session.initializing
          ? const SplashScreen()
          : widget.session.user == null
          ? AuthScreen(widget.session)
          : HomeScreen(widget.session, key: ValueKey(widget.session.user!.id)),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fingerprint_rounded, size: 76, color: Color(0xff155eef)),
          SizedBox(height: 20),
          Text(
            'Đức Attendance',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
