import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:catrans_app/core/config/app_config.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/screens/staff/auth/personnel_entry_screen.dart';

void main() {
  // Serves clean paths (e.g. /personnel) instead of hash fragments on web.
  // No-op on non-web platforms. Requires the staging/production web server
  // to fall back unknown paths to index.html (see LOT 6.8B1 report §2).
  usePathUrlStrategy();
  AppConfig.validateRuntimeConfiguration();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
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
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/personnel') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const PersonnelEntryScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}
