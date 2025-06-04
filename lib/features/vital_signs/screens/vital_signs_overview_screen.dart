// lib/features/vital_signs/screens/vital_signs_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:mediremind/core/models/vital_sign.dart'; // Ajusta el path
import 'package:mediremind/core/services/vital_sign_service.dart'; // Ajusta el path
import 'package:intl/intl.dart';
// import 'record_vital_sign_screen.dart'; // Pantalla/Dialog para registrar nuevo

class VitalSignsOverviewScreen extends StatefulWidget {
  const VitalSignsOverviewScreen({super.key});

  @override
  State<VitalSignsOverviewScreen> createState() => _VitalSignsOverviewScreenState();
}

class _VitalSignsOverviewScreenState extends State<VitalSignsOverviewScreen> {
  final VitalSignService _vitalSignService = VitalSignService();
  late Future<List<VitalSign>> _vitalSignsFuture;

  @override
  void initState() {
    super.initState();
    _loadVitalSigns();
  }

  void _loadVitalSigns() {
    setState(() {
      _vitalSignsFuture = _vitalSignService.getMyVitalSigns();
    });
  }

  // Función para mostrar el diálogo o navegar a la pantalla de registro
  void _showRecordVitalSignDialog() {
    // Implementa un AlertDialog o navega a una nueva pantalla
    // para registrar un nuevo signo vital.
    // Por simplicidad, aquí solo recargamos.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Aquí iría tu formulario de registro de signo vital
        // Por ahora, un placeholder:
        final typeController = TextEditingController();
        final valueController = TextEditingController();
        final unitController = TextEditingController();
        final _formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: const Text('Registrar Signo Vital'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Tipo (ej. Presión Sistólica)'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: 'Valor'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Unidad (ej. mmHg, bpm)'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final data = {
                      'type': typeController.text,
                      'value': double.parse(valueController.text), // Asegúrate de manejar el parse
                      'unit': unitController.text,
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'time': DateFormat('HH:mm').format(DateTime.now()),
                    };
                    await _vitalSignService.recordVitalSign(data);
                    Navigator.of(context).pop();
                    _loadVitalSigns(); // Recargar
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Signo vital registrado!')),
                     );
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error: ${e.toString()}')),
                     );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<VitalSign>>(
        future: _vitalSignsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar signos vitales: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay signos vitales registrados.'));
          }

          final vitalSigns = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadVitalSigns(),
            child: ListView.builder(
              itemCount: vitalSigns.length,
              itemBuilder: (context, index) {
                final vs = vitalSigns[index];
                String displayVSDatetime = 'Fecha/Hora inválida';
                 try {
                  final date = DateFormat('yyyy-MM-dd').parse(vs.date);
                  final time = DateFormat('HH:mm').parse(vs.time); // Asume que vs.time es HH:mm
                  final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  displayVSDatetime = DateFormat('dd MMM yyyy, hh:mm a', 'es_MX').format(dateTime);
                } catch(e) { /* ya manejado arriba */ }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('${vs.type}: ${vs.value} ${vs.unit}'),
                    subtitle: Text(displayVSDatetime),
                    leading: const Icon(Icons.monitor_heart_outlined, color: Colors.redAccent),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordVitalSignDialog,
        label: const Text('Registrar Signo'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}