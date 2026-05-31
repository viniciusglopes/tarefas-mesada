import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/parent_login_screen.dart';
import 'screens/auth/child_login_screen.dart';
import 'screens/parent/dashboard_screen.dart';
import 'screens/child/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const TarefasMesadaApp());
}

class TarefasMesadaApp extends StatelessWidget {
  const TarefasMesadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarefas & Mesada',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
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
            final childData = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(builder: (_) => ChildHomeScreen(childData: childData));
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
