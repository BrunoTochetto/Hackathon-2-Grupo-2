import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/buffet_provider.dart';
import '../../widgets/common/responsive_scaffold.dart';
import 'restaurant_dashboard_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buffet = context.watch<BuffetProvider>();

    return ResponsiveScaffold(
      currentIndex: 0,
      title: buffet.establishment.name.isNotEmpty
          ? buffet.establishment.name
          : 'Painel de Gerenciamento — SmartBuffet',
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Atualizar Dados do Backend',
          onPressed: () => buffet.refreshFromBackend(),
        ),
        IconButton(
          icon: const Icon(Icons.soup_kitchen, color: Colors.amberAccent),
          tooltip: 'Abrir Display da Cozinha',
          onPressed: () => Navigator.pushNamed(context, '/kitchen'),
        ),
      ],
      body: const RestaurantDashboardView(),
    );
  }
}
