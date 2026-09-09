import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/buffet_provider.dart';
import 'routes.dart';
import 'theme.dart';

class SmartBuffetApp extends StatelessWidget {
  const SmartBuffetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BuffetProvider()),
      ],
      child: MaterialApp(
        title: 'SmartBuffet — Equipe V.E.R.',
        debugShowCheckedModeBanner: false,
        theme: VerTheme.lightTheme,
        initialRoute: AppRoutes.landing,
        routes: AppRoutes.routes,
      ),
    );
  }
}
