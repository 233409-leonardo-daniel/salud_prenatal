import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/login/presentation/providers/login_provider.dart';
import '../../features/login/presentation/pages/login_state.dart';
import '../../app.dart';

class SessionTimeoutListener extends StatefulWidget {
  final Widget child;

  const SessionTimeoutListener({super.key, required this.child});

  @override
  State<SessionTimeoutListener> createState() => _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends State<SessionTimeoutListener> with WidgetsBindingObserver {
  Timer? _timer;
  static const _timeoutDuration = Duration(minutes: 20);
  static const _prefsKey = 'last_activity_timestamp';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loginProvider = context.watch<LoginProvider>();
    final isLoggedIn = loginProvider.status == LoginStatus.success;

    if (isLoggedIn != _isLoggedIn) {
      _isLoggedIn = isLoggedIn;
      if (_isLoggedIn) {
        _startTimer();
        _saveLastActivity();
      } else {
        _cancelTimer();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isLoggedIn) return;

    if (state == AppLifecycleState.paused) {
      _saveLastActivity();
    } else if (state == AppLifecycleState.resumed) {
      _checkTimeoutOnResume();
    }
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer(_timeoutDuration, _logout);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleInteraction() {
    if (_isLoggedIn) {
      _startTimer();
      _saveLastActivity();
    }
  }

  Future<void> _saveLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _checkTimeoutOnResume() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(_prefsKey);
    if (lastTime != null) {
      final difference = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastTime));
      if (difference >= _timeoutDuration) {
        _logout();
      } else {
        final remaining = _timeoutDuration - difference;
        _cancelTimer();
        _timer = Timer(remaining, _logout);
      }
    } else {
      _logout();
    }
  }

  void _logout() {
    _cancelTimer();
    
    // Log out using provider
    final loginProvider = context.read<LoginProvider>();
    loginProvider.reset();

    // Navigate to login using static navigatorKey to bypass context limitations
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);

    // Show alert snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu sesión ha expirado por inactividad de 20 minutos'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handleInteraction(),
      onPointerMove: (_) => _handleInteraction(),
      child: widget.child,
    );
  }
}
