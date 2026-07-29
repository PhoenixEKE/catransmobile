import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:catrans_app/core/config/app_config.dart';
import 'package:catrans_app/core/navigation/app_router.dart';
import 'package:catrans_app/services/auth_service.dart';

void main() {
  // Serves clean paths (e.g. /personnel) instead of hash fragments on web.
  // No-op on non-web platforms. Requires the staging/production web server
  // to fall back unknown paths to index.html (see LOT 6.8B1 report §2).
  usePathUrlStrategy();
  AppConfig.validateRuntimeConfiguration();

  // Built once, outside the widget tree, so the same instance can be
  // handed both to the Provider (read by screens) and to GoRouter's
  // `refreshListenable` (see lib/core/navigation/app_router.dart).
  final authService = AuthService();
  final router = buildAppRouter(authService);

  runApp(MyApp(authService: authService, router: router));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final GoRouter router;

  const MyApp({super.key, required this.authService, required this.router});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: MaterialApp.router(
        title: 'Catrans mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF0F056B),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F056B),
            secondary: Color(0xFFEFD807),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFF0F056B),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFD807),
              foregroundColor: Colors.black,
            ),
          ),
        ),
        // ⬇️ CES LIGNES SONT ESSENTIELLES ⬇️
        locale: const Locale('fr', 'FR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        routerConfig: router,
      ),
    );
  }
}
