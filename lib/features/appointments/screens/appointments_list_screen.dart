// lib/features/appointments/screens/appointments_list_screen.dart
import 'package:flutter/material.dart';
import 'package:mediremind/core/models/appointment.dart';
import 'package:mediremind/core/services/appointment_service.dart';
import 'package:intl/intl.dart'; // Para formateo de fechas
import 'request_appointment_screen.dart'; // Crearás esta pantalla después

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  late Future<List<Appointment>> _appointmentsFuture;
  bool _isProcessing = false; // Para Cancelar o Eliminar

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    if (mounted) {
      setState(() {
        _appointmentsFuture = _appointmentService.getMyAppointments();
      });
    }
  }

  Future<void> _navigateToRequestAppointmentScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RequestAppointmentScreen()),
    );
    if (result == true && mounted) {
      _loadAppointments();
    }
  }

  Future<void> _handleCancelAppointment(String appointmentId) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });

    final confirm = await _showConfirmationDialog(
      title: 'Confirmar Cancelación',
      content: '¿Estás seguro de que quieres cambiar el estado de esta cita a "Cancelada por Paciente"?',
      confirmText: 'Sí, Cancelar',
    );

    if (confirm == true) {
      try {
        await _appointmentService.cancelAppointmentByPatient(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cita marcada como cancelada.'), backgroundColor: Colors.orange),
          );
          _loadAppointments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cancelar la cita: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
    if (mounted) {
      setState(() { _isProcessing = false; });
    }
  }

  Future<void> _handleDeleteAppointment(String appointmentId, String currentStatus) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });

    String dialogTitle = 'Confirmar Eliminación';
    String dialogContent = '¿Estás seguro de que quieres eliminar esta cita? Esta acción no se puede deshacer.';
    String snackbarMessage = 'Cita eliminada exitosamente.';

    if (currentStatus == 'requested_by_patient') {
      dialogContent = '¿Estás seguro de que quieres eliminar esta solicitud de cita? Esta acción no se puede deshacer.';
      snackbarMessage = 'Solicitud de cita eliminada exitosamente.';
    } else if (currentStatus == 'cancelled_by_patient') {
      dialogContent = '¿Estás seguro de que quieres eliminar permanentemente esta cita cancelada de tus registros?';
      snackbarMessage = 'Cita cancelada eliminada de tus registros.';
    }


    final confirm = await _showConfirmationDialog(
      title: dialogTitle,
      content: dialogContent,
      confirmText: 'Sí, Eliminar',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        // Usamos el mismo método de servicio, la RLS en Supabase determinará si se permite
        await _appointmentService.deleteRequestedAppointment(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(snackbarMessage), backgroundColor: Colors.green),
          );
          _loadAppointments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
     if (mounted) {
      setState(() { _isProcessing = false; });
    }
  }

  Future<bool?> _showConfirmationDialog({required String title, required String content, required String confirmText, bool isDestructive = false}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: isDestructive ? Colors.red.shade700 : Theme.of(context).primaryColor,
              ),
              child: Text(confirmText),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;

    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'confirmed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        iconData = Icons.event_available_outlined;
        break;
      case 'requested_by_patient':
      case 'pending_confirmation':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        iconData = Icons.hourglass_empty_outlined;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        iconData = Icons.check_circle_outline;
        break;
      case 'cancelled_by_patient':
      case 'cancelled_by_doctor':
      case 'rejected_by_doctor':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        iconData = Icons.cancel_outlined;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        iconData = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(iconData, color: textColor, size: 16),
      label: Text(
        status.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'\b[a-z]'), (match) => match.group(0)!.toUpperCase()),
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Appointment>>(
        future: _appointmentsFuture,
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
                    Text('Error al cargar las citas: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar de Nuevo'),
                      onPressed: _loadAppointments,
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
                  Icon(Icons.calendar_month_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text('No tienes citas programadas o solicitadas.', style: TextStyle(fontSize: 17, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text('Puedes solicitar una nueva cita usando el botón de abajo.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center,),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recargar Citas'),
                    onPressed: _loadAppointments,
                  )
                ],
              ),
            );
          }

          final appointments = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadAppointments(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: appointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final doctorName = appointment.doctor?.name ?? 'Doctor Desconocido';
                final specialty = appointment.specialty;
                String displayAppointmentDateTime = 'Fecha/Hora no disponible';
                 if (appointment.date.isNotEmpty && appointment.time.isNotEmpty) {
                    try {
                        final datePart = DateFormat('yyyy-MM-dd').parseStrict(appointment.date);
                        final timeParts = appointment.time.split(':');
                        final hour = int.parse(timeParts[0]);
                        final minute = int.parse(timeParts[1]);
                        final dateTime = DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
                        displayAppointmentDateTime = DateFormat('EEEE dd MMM, hh:mm a', 'es_MX').format(dateTime);
                    } catch (e) {
                        print("Error formateando fecha/hora para cita ${appointment.id}: $e");
                    }
                }

                // Determinar qué acciones están disponibles para el paciente
                bool canBeCancelledByPatient = appointment.status == 'scheduled'; // Solo puede cancelar si está agendada
                bool canBeDeletedByPatient = appointment.status == 'requested_by_patient' || appointment.status == 'cancelled_by_patient'; // MODIFICADO

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      print("Cita tocada: ${appointment.id}");
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  specialty,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusChip(appointment.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Con: Dr(a). $doctorName',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  displayAppointmentDateTime,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                          if (appointment.reasonForRequest != null && appointment.reasonForRequest!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Motivo: ${appointment.reasonForRequest}',
                                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Botones de acción
                          if (canBeDeletedByPatient || canBeCancelledByPatient)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (canBeDeletedByPatient)
                                    TextButton.icon(
                                      icon: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700, size: 18),
                                      label: Text(
                                        appointment.status == 'cancelled_by_patient' ? 'Eliminar Cancelada' : 'Eliminar Solicitud',
                                        style: TextStyle(color: Colors.red.shade700, fontSize: 13)
                                      ),
                                      onPressed: _isProcessing ? null : () => _handleDeleteAppointment(appointment.id, appointment.status),
                                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                    ),
                                  if (canBeCancelledByPatient) // Ya no se usa !canBeDeletedByPatient aquí, ya que son acciones diferentes ahora
                                    TextButton.icon(
                                      icon: Icon(Icons.cancel_schedule_send_outlined, color: Colors.orange.shade800, size: 18),
                                      label: Text('Cancelar Cita', style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
                                      onPressed: _isProcessing ? null : () => _handleCancelAppointment(appointment.id),
                                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRequestAppointmentScreen,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Solicitar Cita'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
