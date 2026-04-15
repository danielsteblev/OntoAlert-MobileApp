import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/home/presentation/home_screen.dart';
import 'app_session.dart';

class FastLearningApp extends StatefulWidget {
  const FastLearningApp({super.key});

  @override
  State<FastLearningApp> createState() => _FastLearningAppState();
}

class _FastLearningAppState extends State<FastLearningApp> {
  late final ApiClient _apiClient = ApiClient();
  late final AppSession _session = AppSession(_apiClient);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: _session.isAuthenticated
              ? HomeShell(session: _session, apiClient: _apiClient)
              : AuthScreen(
                  onLogin: (username, password) => _session.login(
                    username: username,
                    password: password,
                  ),
                  onRegister: (username, email, password, fullName) => _session.register(
                    username: username,
                    email: email,
                    password: password,
                    fullName: fullName,
                  ),
                ),
        );
      },
    );
  }
}
