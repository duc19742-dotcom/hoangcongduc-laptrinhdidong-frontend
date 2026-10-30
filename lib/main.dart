import 'dart:async';

import 'package:flutter/material.dart';

import 'features/auth/auth_screen.dart';
import 'features/home_screen.dart';
import 'state/session.dart';
import 'state/app_preferences.dart';

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

class _AttendanceAppState extends State<AttendanceApp>
    with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  DateTime? backgroundAt;
  @override
  void initState() {
    super.initState();
    widget.session.addListener(changed);
    widget.session.preferences.addListener(preferencesChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void preferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) backgroundAt = DateTime.now();
    if (state == AppLifecycleState.resumed) {
      if (backgroundAt != null &&
          DateTime.now().difference(backgroundAt!).inSeconds >= 60 &&
          widget.session.currentBiometrics &&
          !widget.session.authenticationInProgress) {
        unawaited(widget.session.clear());
      }
      backgroundAt = null;
    }
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
    widget.session.preferences.removeListener(preferencesChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Đức Attendance',
    debugShowCheckedModeBanner: false,
    navigatorKey: navigator,
    themeMode: widget.session.preferences.mode,
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: AccessibleTextScaler(
          MediaQuery.textScalerOf(context),
          widget.session.preferences.fontScale,
        ),
      ),
      child: child!,
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
  ThemeData appTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(widget.session.preferences.color),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xfff5f7fb)
          : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light
            ? Colors.white
            : scheme.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
        space: 24,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorMaxLines: 3,
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
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
