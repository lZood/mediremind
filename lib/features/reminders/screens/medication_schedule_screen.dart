import 'package:flutter/material.dart';
import 'package:mediremind/core/models/medication_intake.dart';
import 'package:mediremind/core/services/medication_intake_service.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({super.key});

  @override
  State<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  final MedicationIntakeService _intakeService = MedicationIntakeService();
  late Future<List<MedicationIntake>> _medicationIntakesFuture;
  bool _isLoadingToggle = false; // Para el indicador de carga al cambiar estado

  @override
  void initState() {
    super.initState();
    _loadMedicationIntakes();
  }

  void _loadMedicationIntakes() {
    print("MedicationScheduleScreen: Iniciando carga de tomas...");
    setState(() {
      _medicationIntakesFuture = _intakeService.getMyMedicationIntakes();
    });
  }

  Future<void> _toggleIntakeStatus(MedicationIntake intake) async {
    if (_isLoadingToggle) return; // Evitar múltiples llamadas

    setState(() {
      _isLoadingToggle = true;
    });

    try {
      final updatedIntake = await _intakeService.updateIntakeStatus(intake.id, !intake.taken);
      if (mounted) { // Verificar si el widget sigue montado
        if (updatedIntake != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Toma de "${updatedIntake.medication?.name ?? "medicamento"}" ${updatedIntake.taken ? "confirmada" : "marcada como no tomada"}.'),
              backgroundColor: updatedIntake.taken ? Colors.green : Colors.orange,
            ),
          );
          _loadMedicationIntakes(); // Recargar la lista para reflejar el cambio
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar la toma.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingToggle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("MedicationScheduleScreen: Construyendo UI...");
    return Scaffold(
      // El AppBar ya está en HomeScreen, así que puedes decidir si necesitas uno aquí.
      // appBar: AppBar(title: const Text('Mis Tomas de Medicamentos')),
      body: FutureBuilder<List<MedicationIntake>>(
        future: _medicationIntakesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("MedicationScheduleScreen: FutureBuilder esperando datos...");
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("MedicationScheduleScreen: FutureBuilder con error: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error al cargar las tomas: ${snapshot.error}\n\nIntenta recargar.', textAlign: TextAlign.center),
              )
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print("MedicationScheduleScreen: FutureBuilder sin datos o lista vacía.");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medication_liquid_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay tomas de medicamentos programadas.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar'),
                    onPressed: _loadMedicationIntakes,
                  )
                ],
              ),
            );
          }

          final intakes = snapshot.data!;
          print("MedicationScheduleScreen: FutureBuilder con ${intakes.length} tomas.");
          return RefreshIndicator(
            onRefresh: () async {
              _loadMedicationIntakes();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(8.0),
              itemCount: intakes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final intake = intakes[index];
                final medicationName = intake.medication?.name ?? 'Medicamento Desconocido';
                final activeIngredient = intake.medication?.activeIngredient;

                String displayIntakeDateTime = 'Fecha/Hora no disponible'; // Valor inicial
                try {
                  // Asumimos que intake.date es 'YYYY-MM-DD' y intake.time es 'HH:mm' o 'HH:mm:ss'
                  // Es crucial que estos formatos sean los que realmente tienes en la DB y llegan en el JSON.
                  print("Formateando fecha: '${intake.date}', hora: '${intake.time}'"); // DEBUG

                  final datePart = DateFormat('yyyy-MM-dd', 'es_MX').parseStrict(intake.date);
                  final timeParts = intake.time.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = int.parse(timeParts[1]);
                  // Los segundos son opcionales, si existen en intake.time, puedes parsearlos también
                  // final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

                  final dateTime = DateTime(datePart.year, datePart.month, datePart.day, hour, minute /*, second */);
                  displayIntakeDateTime = DateFormat('EEEE dd MMM, hh:mm a', 'es_MX').format(dateTime); // 'es_MX' para español México
                } catch (e) {
                  print("Error formateando fecha/hora para toma ${intake.id} ('${intake.date}', '${intake.time}'): $e");
                  // Mantenemos "Fecha/Hora no disponible" si hay error
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: intake.taken ? Colors.green.shade100 : Colors.orange.shade100,
                      child: Icon(
                        intake.taken ? Icons.check_circle_outline : Icons.alarm_on_outlined,
                        color: intake.taken ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                    title: Text(medicationName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activeIngredient != null && activeIngredient.isNotEmpty)
                          Text(activeIngredient, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text(displayIntakeDateTime, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    trailing: _isLoadingToggle && intake.id == "ID_DE_LA_TOMA_ACTUALIZANDOSE" // Necesitarías una forma de saber cuál se está actualizando
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Switch(
                            value: intake.taken,
                            onChanged: (bool newValue) {
                              _toggleIntakeStatus(intake);
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.grey.shade400,
                            inactiveTrackColor: Colors.grey.shade200,
                          ),
                    onTap: () => _toggleIntakeStatus(intake), // También permite cambiar estado al tocar el item
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}