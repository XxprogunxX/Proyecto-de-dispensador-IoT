import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RelojInteligenteApp());
}

class RelojInteligenteApp extends StatelessWidget {
  const RelojInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dispensador Wear OS',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor:
            Colors.black, // Obligatorio negro para relojes OLED
      ),
      // Iniciamos con la Pantalla Inicial (Splash Screen)
      home: const SplashPantalla(),
    );
  }
}

// =========================================================
// PANTALLA INICIAL (SPLASH SCREEN)
// =========================================================
class SplashPantalla extends StatefulWidget {
  const SplashPantalla({super.key});

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla> {
  @override
  void initState() {
    super.initState();
    // Simula un tiempo de carga de 2.5 segundos y luego cambia a la pantalla principal
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavegacionReloj()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 50, color: Colors.blueAccent),
            SizedBox(height: 10),
            Text(
              'Smart\nDispenser',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// NAVEGACIÓN PRINCIPAL (Deslizar para cambiar de funcionalidad)
// =========================================================
class NavegacionReloj extends StatelessWidget {
  const NavegacionReloj({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos PageView para poder deslizar izquierda/derecha entre funcionalidades
      body: PageView(
        children: const [
          FuncionalidadEstado(), // Página 1
          FuncionalidadServir(), // Página 2
        ],
      ),
    );
  }
}

// =========================================================
// FUNCIONALIDAD 1: Monitoreo del Nivel del Tanque
// =========================================================
class FuncionalidadEstado extends StatelessWidget {
  const FuncionalidadEstado({super.key});

  final double alturaContenedor = 20.0;

  @override
  Widget build(BuildContext context) {
    final DatabaseReference distanciaRef = FirebaseDatabase.instance.ref(
      'comida/distancia',
    );

    return Center(
      child: StreamBuilder(
        stream: distanciaRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(color: Colors.blueAccent);
          }

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final distanciaStr = snapshot.data!.snapshot.value.toString();
            double distanciaNum = double.tryParse(distanciaStr) ?? 0;

            if (distanciaNum > alturaContenedor)
              distanciaNum = alturaContenedor;

            int porcentajeLleno =
                ((1 - (distanciaNum / alturaContenedor)) * 100).toInt();
            bool nivelBajo = porcentajeLleno < 25;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  nivelBajo ? Icons.warning_amber_rounded : Icons.opacity,
                  size: 24,
                  color: nivelBajo ? Colors.redAccent : Colors.blueAccent,
                ),
                Text(
                  '$porcentajeLleno%',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: nivelBajo ? Colors.redAccent : Colors.white,
                  ),
                ),
                const Text(
                  'Nivel Tanque',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Desliza ',
                      style: TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ],
            );
          }
          return const Icon(Icons.wifi_off, color: Colors.grey, size: 40);
        },
      ),
    );
  }
}

// =========================================================
// FUNCIONALIDAD 2: Despachar Comida al Plato
// =========================================================
class FuncionalidadServir extends StatefulWidget {
  const FuncionalidadServir({super.key});

  @override
  State<FuncionalidadServir> createState() => _FuncionalidadServirState();
}

class _FuncionalidadServirState extends State<FuncionalidadServir> {
  final DatabaseReference _despacharRef = FirebaseDatabase.instance.ref(
    'comida/despachar',
  );
  bool _estaSirviendo = false;
  bool _exito = false;

  void _servirComida() async {
    setState(() {
      _estaSirviendo = true;
      _exito = false;
    });

    try {
      await _despacharRef.set(true);
      if (mounted) setState(() => _exito = true);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _estaSirviendo = false;
            _exito = false; // Reiniciamos el estado de éxito
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Servir Plato',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),

          ElevatedButton(
            onPressed: _estaSirviendo ? null : _servirComida,
            style: ElevatedButton.styleFrom(
              backgroundColor: _exito ? Colors.green : Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(25),
            ),
            child: _estaSirviendo
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(_exito ? Icons.check : Icons.restaurant, size: 30),
          ),

          const SizedBox(height: 15),
          Text(
            _estaSirviendo
                ? 'Enviando...'
                : (_exito ? '¡Servido!' : 'Tocar para servir'),
            style: TextStyle(
              fontSize: 12,
              color: _exito ? Colors.green : Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
