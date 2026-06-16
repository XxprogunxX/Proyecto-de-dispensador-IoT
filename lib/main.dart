import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DispensadorApp());
}

class DispensadorApp extends StatelessWidget {
  const DispensadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Dispensador IoT',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, 
        cardColor: const Color(0xFF1A1A1A), 
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final DatabaseReference _distanciaRef = FirebaseDatabase.instance.ref('comida/distancia');
  final DatabaseReference _despacharRef = FirebaseDatabase.instance.ref('comida/despachar');

  // ALTURA TOTAL DE TU CONTENEDOR EN CENTÍMETROS
  // Cambia este número según lo que mida físicamente el tanque donde guardas las croquetas
  final double alturaContenedor = 20.0; 

  bool _estaSirviendo = false;

  void _mostrarNotificacionEmergente() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.blueAccent, size: 28),
              SizedBox(width: 10),
              Text('¡Atención!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: const Text(
            'Se ha enviado la orden.\nLa comida se está sirviendo ahora mismo en el plato. 🐾',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _servirComida() async {
    setState(() => _estaSirviendo = true);
    try {
      await _despacharRef.set(true);
      
      if (mounted) {
        _mostrarNotificacionEmergente();
      }
    } catch (e) {
      debugPrint("Error de conexión: $e");
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _estaSirviendo = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Dispensador Inteligente', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 5,
        shadowColor: Colors.blueAccent.withOpacity(0.5),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nivel del Tanque de Alimento',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.blueAccent.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  child: StreamBuilder(
                    stream: _distanciaRef.onValue,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                      }
                      
                      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                        final distanciaStr = snapshot.data!.snapshot.value.toString();
                        double distanciaNum = double.tryParse(distanciaStr) ?? 0;
                        
                        // Limitamos la distancia a la altura máxima del contenedor para no tener porcentajes negativos
                        if (distanciaNum > alturaContenedor) distanciaNum = alturaContenedor;
                        
                        // FÓRMULA: Si la distancia es igual a la altura, está al 0%. Si la distancia es 0, está al 100%.
                        int porcentajeLleno = ((1 - (distanciaNum / alturaContenedor)) * 100).toInt();
                        
                        // Consideramos "nivel bajo" si el tanque está a menos del 25% de su capacidad
                        bool nivelBajo = porcentajeLleno < 25;
                        
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: nivelBajo ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                nivelBajo ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                size: 80,
                                color: nivelBajo ? Colors.redAccent : Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Ahora mostramos el Porcentaje en grande
                            Text(
                              '$porcentajeLleno%',
                              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            // Y dejamos los centímetros en chiquito como dato técnico
                            Text(
                              'Distancia del sensor: $distanciaStr cm',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: nivelBajo ? Colors.redAccent : Colors.blueAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                nivelBajo ? 'Tanque casi vacío. ¡Rellenar!' : 'Capacidad de alimento óptima',
                                style: const TextStyle(
                                  fontSize: 16, 
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const Center(child: Text('Sin conexión al sensor', style: TextStyle(color: Colors.grey)));
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                height: 75,
                child: ElevatedButton.icon(
                  onPressed: _estaSirviendo ? null : _servirComida,
                  icon: _estaSirviendo 
                      ? const SizedBox(
                          width: 24, height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        )
                      : const Icon(Icons.pets, size: 30),
                  label: Text(
                    _estaSirviendo ? 'Procesando...' : 'Servir al Plato',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: _estaSirviendo ? 0 : 8,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}