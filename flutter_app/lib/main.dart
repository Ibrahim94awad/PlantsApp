import 'package:flutter/material.dart';

import 'database.dart';
import 'screens/home_page.dart';
import 'theme.dart';

export 'format.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();
  runApp(const PlantsApp());
}

class PlantsApp extends StatelessWidget {
  const PlantsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Plantregistratie',
        theme: buildAppTheme(),
        builder: (context, child) =>
            AppBackground(child: child ?? const SizedBox.shrink()),
        home: const HomePage(),
      );
}
