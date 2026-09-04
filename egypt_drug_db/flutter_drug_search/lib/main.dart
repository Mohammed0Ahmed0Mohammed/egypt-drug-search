import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/drug_provider.dart';
import 'screens/drug_search_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DrugProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'دليل الأدوية المصرية',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E), // teal 700
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const DrugSearchScreen(),
        builder: (context, child) {
          return Column(
            children: [
              Expanded(child: child!),
              Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Text(
                  'بيانات من karem505 (CC0) + MoaazSalter. للإرشاد فقط — ليس استشارة طبية. الأسعار تقريبية وليست للمقارنة العلاجية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
