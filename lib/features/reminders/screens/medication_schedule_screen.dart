// lib/features/reminders/screens/medication_schedule_screen.dart
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
  bool _isProcessingToggle = false;

  // Define la ventana de tiempo para poder marcar una toma
  final Duration _allowMarkingBeforeDuration = const Duration(hours: 1);
  final Duration _allowMarkingAfterDuration = const Duration(hours: 2); // Ej: 2 horas después

  @override
  void initState() {
    super.initState();
    _loadMedicationIntakes();
  }

  void _loadMedicationIntakes() {
    print("MedicationScheduleScreen: Iniciando carga de tomas...");
    if (mounted) {
      setState(() {
        _medicationIntakesFuture = _intakeService.getMyMedicationIntakes();
      });
    }
  }

  bool _canMarkIntake(MedicationIntake intake) {
    try {
      final DateTime now = DateTime.now();
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final DateFormat timeFormat = DateFormat('HH:mm:ss'); // Asumiendo que el tiempo viene en este formato desde Supabase

      final DateTime intakeDate = dateFormat.parseStrict(intake.date);
      final TimeOfDay intakeTimeOfDay = TimeOfDay(
        hour: timeFormat.parseStrict(intake.time).hour,
        minute: timeFormat.parseStrict(intake.time).minute,
      );

      final DateTime intakeDateTime = DateTime(
        intakeDate.year,
        intakeDate.month,
        intakeDate.day,
        intakeTimeOfDay.hour,
        intakeTimeOfDay.minute,
      );

      final DateTime windowStart = intakeDateTime.subtract(_allowMarkingBeforeDuration);
      final DateTime windowEnd = intakeDateTime.add(_allowMarkingAfterDuration);

      // Permitir marcar si 'now' está dentro de la ventana Y la toma aún no ha sido marcada
      // O si ya fue marcada, permitir desmarcarla (si la lógica de negocio lo permite)
      // Por ahora, solo habilitamos si está dentro de la ventana.
      // Si ya está tomada, el switch estará activo pero el onChanged podría no hacer nada si no se permite desmarcar.
      return now.isAfter(windowStart) && now.isBefore(windowEnd);

    } catch (e) {
      print("Error en _canMarkIntake para la toma ${intake.id}: $e");
      return false; // Si hay error en parseo, deshabilitar
    }
  }

  Future<void> _toggleIntakeStatus(MedicationIntake intake) async {
    if (_isProcessingToggle) return;

    // Verificar si se puede marcar la toma (podrías mover esta lógica aquí también)
    // if (!_canMarkIntake(intake) && !intake.taken) { // Si no se puede marcar y no está tomada
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Solo puedes confirmar esta toma cerca de la hora programada.'), backgroundColor: Colors.orange),
    //   );
    //   return;
    // }

    setState(() { _isProcessingToggle = true; });

    try {
      final updatedIntake = await _intakeService.updateIntakeStatus(intake.id, !intake.taken);
      if (mounted) {
        if (updatedIntake != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Toma de "${updatedIntake.medication?.name ?? "medicamento"}" ${updatedIntake.taken ? "confirmada" : "marcada como no tomada"}.'),
              backgroundColor: updatedIntake.taken ? Colors.green : Colors.orangeAccent,
            ),
          );
          _loadMedicationIntakes(); 
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
        setState(() { _isProcessingToggle = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("MedicationScheduleScreen: Construyendo UI...");
    return Scaffold(
      body: FutureBuilder<List<MedicationIntake>>(
        future: _medicationIntakesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                    const SizedBox(height: 16),
                    Text('Error al cargar las tomas: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar de Nuevo'),
                      onPressed: _loadMedicationIntakes,
                    )
                  ],
                ),
              )
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text('No tienes tomas de medicamentos programadas.', style: TextStyle(fontSize: 17, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text('Tu doctor te asignará planes de medicación aquí.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center,),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar Tomas'),
                    onPressed: _loadMedicationIntakes,
                  )
                ],
              ),
            );
          }

          final intakes = snapshot.data!;
          // Aquí podrías agrupar las 'intakes' por 'medication_plan_id' si esa columna
          // estuviera disponible en tu modelo MedicationIntake y la obtuvieras del servicio.
          // Por ahora, se muestran como una lista continua.

          return RefreshIndicator(
            onRefresh: () async {
              _loadMedicationIntakes();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: intakes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final intake = intakes[index];
                final medicationName = intake.medication?.name ?? 'Medicamento Desconocido';
                final activeIngredient = intake.medication?.activeIngredient;
                final bool canMarkThisIntake = _canMarkIntake(intake);

                String displayIntakeDate = 'Fecha no disponible';
                String displayIntakeTime = 'Hora no disponible';
                DateTime? intakeFullDateTime;

                try {
                  final dateP = DateFormat('yyyy-MM-dd').parseStrict(intake.date);
                  final timeP = DateFormat('HH:mm:ss').parseStrict(intake.time); // Asume HH:mm:ss
                  intakeFullDateTime = DateTime(dateP.year, dateP.month, dateP.day, timeP.hour, timeP.minute, timeP.second);
                  
                  displayIntakeDate = DateFormat('EEEE dd MMM, yyyy', 'es_MX').format(intakeFullDateTime);
                  displayIntakeTime = DateFormat('hh:mm a', 'es_MX').format(intakeFullDateTime);
                } catch (e) {
                  print("Error formateando fecha/hora para toma ${intake.id} ('${intake.date}', '${intake.time}'): $e");
                }

                // Lógica para mostrar si el plan está completo (simplificada)
                // Esto requeriría más información sobre el plan al que pertenece la toma.
                // bool isPartOfCompletedPlan = false; // TODO: Implementar lógica si es necesario

                return Opacity(
                  opacity: intake.taken || (intakeFullDateTime != null && intakeFullDateTime.isBefore(DateTime.now().subtract(const Duration(days: 1)))) ? 0.7 : 1.0,
                  child: Card(
                    elevation: intake.taken ? 1 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: canMarkThisIntake && !intake.taken ? Theme.of(context).primaryColor.withOpacity(0.7) : Colors.transparent,
                        width: canMarkThisIntake && !intake.taken ? 1.5 : 0,
                      )
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: intake.taken 
                            ? Colors.green.shade100 
                            : (canMarkThisIntake ? Colors.blue.shade50 : Colors.grey.shade200),
                        child: Icon(
                          intake.taken 
                            ? Icons.check_circle_outline_rounded 
                            : (canMarkThisIntake ? Icons.alarm_on_outlined : Icons.hourglass_empty_rounded),
                          color: intake.taken 
                            ? Colors.green.shade700 
                            : (canMarkThisIntake ? Colors.blue.shade700 : Colors.grey.shade500),
                        ),
                      ),
                      title: Text(medicationName, style: TextStyle(fontWeight: FontWeight.bold, color: intake.taken ? Colors.grey.shade700 : Colors.black87)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeIngredient != null && activeIngredient.isNotEmpty)
                            Text(activeIngredient, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text("$displayIntakeDate a las $displayIntakeTime", style: TextStyle(fontSize: 13, color: intake.taken ? Colors.grey.shade600 : Colors.black54)),
                          if (intake.medication_plan_id != null) // Mostrar si es parte de un plan
                             Padding(
                               padding: const EdgeInsets.only(top: 2.0),
                               child: Text("Plan ID: ${intake.medication_plan_id!.substring(0,8)}...", style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
                             ),
                        ],
                      ),
                      trailing: Switch(
                        value: intake.taken,
                        onChanged: (canMarkThisIntake || intake.taken) // Permitir desmarcar si ya está tomada
                            ? (bool newValue) {
                                if (_isProcessingToggle) return;
                                _toggleIntakeStatus(intake);
                              }
                            : null, // Deshabilitar el switch si no está en la ventana de tiempo
                        activeColor: Colors.green,
                        inactiveThumbColor: canMarkThisIntake ? Colors.blue.shade200 : Colors.grey.shade400,
                        inactiveTrackColor: canMarkThisIntake ? Colors.blue.shade100.withOpacity(0.5) : Colors.grey.shade200,
                      ),
                      onTap: (canMarkThisIntake || intake.taken) ? () {
                        if (_isProcessingToggle) return;
                        _toggleIntakeStatus(intake);
                      } : null,
                    ),
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
