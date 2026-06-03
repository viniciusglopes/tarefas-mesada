import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/supabase_service.dart';
import 'services/session_service.dart';
import 'services/admin_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/parent_login_screen.dart';
import 'screens/auth/child_login_screen.dart';
import 'screens/parent/dashboard_screen.dart';
import 'screens/child/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await SessionService.init();

  final initialRoute = await _resolveInitialRoute();
  final childData = await SessionService.getChildSession();

  runApp(TarefasMesadaApp(initialRoute: initialRoute, childData: childData));
}

Future<String> _resolveInitialRoute() async {
  if (SupabaseService.isAuthenticated) {
    return AdminService.isAdmin() ? '/admin' : '/parent-dashboard';
  }
  final childData = await SessionService.getChildSession();
  if (childData != null) {
    return '/child-home';
  }
  return '/';
}

class TarefasMesadaApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, dynamic>? childData;

  const TarefasMesadaApp({super.key, required this.initialRoute, this.childData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarefas & Mesada',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/parent-login':
            return MaterialPageRoute(builder: (_) => const ParentLoginScreen());
          case '/child-login':
            return MaterialPageRoute(builder: (_) => const ChildLoginScreen());
          case '/parent-dashboard':
            return MaterialPageRoute(builder: (_) => const ParentDashboardScreen());
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
          case '/child-home':
            final data = settings.arguments as Map<String, dynamic>? ?? childData;
            if (data == null) {
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
            return MaterialPageRoute(builder: (_) => ChildHomeScreen(childData: data));
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
