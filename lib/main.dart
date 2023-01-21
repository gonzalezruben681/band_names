import 'package:band_names/pages/add_band_category.dart';
import 'package:band_names/pages/home_prueba.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:band_names/pages/home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SocketService(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Votaciones ',
        initialRoute: 'prueba',
        routes: {
          'home': (context) => HomePage(),
          'prueba': (context) => HomePagePrueba(),
          'addband': (context) => AddBandPage(),
        },
      ),
    );
  }
}
