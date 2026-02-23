import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/authentication/login_screen.dart';
import 'package:frontend/screens/dashboard/main_dashboard.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:frontend/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const UniversityPortalApp(),
    ),
  );
}

/// Root application widget for the University Appeal & Complaint Management System.
class UniversityPortalApp extends StatelessWidget {
  const UniversityPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Consumer ensures that whenever ThemeProvider changes,
    // the MaterialApp is rebuilt with the new theme data.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'JUST — University Portal',
          theme: AppColors.getTheme(themeProvider.isDarkMode),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final name = settings.name ?? '/';

            // Special handling for dashboard with arguments if any
            if (name.contains('dashboard')) {
              return MaterialPageRoute(
                builder: (_) => const MainDashboard(),
                settings: settings,
              );
            }

            switch (name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              default:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
          },
        );
      },
    );
  }
}
