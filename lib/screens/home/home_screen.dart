import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/screens/home/dashboard.dart';
import 'package:iic_connect/widgets/app_bar.dart';
import 'package:iic_connect/widgets/drawer.dart';

import '../../utils/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: AppConstants.appName),
      drawer: const CustomDrawer(),
      body: Dashboard(user: user),
    );
  }
}