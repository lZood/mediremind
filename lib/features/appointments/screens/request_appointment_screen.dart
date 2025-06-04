// lib/features/appointments/screens/request_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:mediremind/core/models/user_profile.dart'; // Para el tipo Doctor (UserProfile)
import 'package:mediremind/core/services/appointment_service.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha inicial

class RequestAppointmentScreen extends StatefulWidget {
  const RequestAppointmentScreen({super.key});

  @override
  State<RequestAppointmentScreen> createState() => _RequestAppointmentScreenState();
}

class _RequestAppointmentScreenState extends State<RequestAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _appointmentService = AppointmentService();

  List<UserProfile> _doctors = [];
  UserProfile? _selectedDoctor;
  // String? _selectedDoctorId; // No es necesario si _selectedDoctor contiene el ID
  // String _specialty = ''; // Usaremos _specialtyController.text

  // Usar DateTime para _selectedDate para facilitar la lógica con DatePicker
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  // Usar TimeOfDay para _selectedTime para facilitar la lógica con TimePicker
  TimeOfDay _selectedTime = TimeOfDay(hour: 9, minute: 0); // Default a las 9:00 AM

  String _reasonForRequest = '';
  bool _isLoadingDoctors = true;
  bool _isSubmitting = false;

  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("RequestAppointmentScreen: initState() llamado.");
    _loadDoctors();
    _updateDateText(_selectedDate);
    _updateTimeText(_selectedTime);
  }

  @override
  void dispose() {
    _specialtyController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    print("RequestAppointmentScreen: _loadDoctors() - Iniciando carga de doctores...");
    setState(() { _isLoadingDoctors = true; });
    try {
      final doctorsList = await _appointmentService.getAvailableDoctors();
      print("RequestAppointmentScreen: _loadDoctors() - Doctores obtenidos: ${doctorsList.length}");
      if (mounted) {
        setState(() {
          _doctors = doctorsList;
          _isLoadingDoctors = false;
          if (_doctors.isEmpty) {
            print("RequestAppointmentScreen: _loadDoctors() - Lista de doctores vacía post-carga.");
          }
        });
      }
    } catch (e, s) {
      print("RequestAppointmentScreen: _loadDoctors() - ERROR: $e, Stacktrace: $s");
      if (mounted) {
        setState(() { _isLoadingDoctors = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar doctores: ${e.toString()}')),
        );
      }
    }
  }

  void _updateDateText(DateTime date) {
    _dateController.text = DateFormat('EEEE dd MMMM, yyyy', 'es_MX').format(date);
  }

  void _updateTimeText(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    _timeController.text = DateFormat('hh:mm a', 'es_MX').format(dt);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'MX'), // Asegúrate de tener la localización configurada en main.dart
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateText(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateTimeText(picked);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDoctor == null) { // Validar que se haya seleccionado un doctor
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, seleccione un doctor.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final String formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      print("RequestAppointmentScreen: _submitRequest() - Enviando solicitud con:");
      print("Doctor ID: ${_selectedDoctor!.id}");
      print("Especialidad: ${_specialtyController.text}");
      print("Fecha Solicitada: $formattedDate");
      print("Hora Solicitada: $formattedTime");
      print("Motivo: $_reasonForRequest");

      final newAppointment = await _appointmentService.requestAppointment(
        doctorId: _selectedDoctor!.id, // Usar el ID del doctor seleccionado
        specialty: _specialtyController.text,
        requestedDate: formattedDate,
        requestedTime: formattedTime,
        reasonForRequest: _reasonForRequest,
      );

      if (mounted) {
        if (newAppointment != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitud de cita enviada exitosamente.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Regresar y pasar true para indicar recarga
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo enviar la solicitud de cita.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e,s) {
      print("RequestAppointmentScreen: _submitRequest() - ERROR: $e");
      print("RequestAppointmentScreen: _submitRequest() - Stacktrace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar solicitud: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("RequestAppointmentScreen: build() llamado. isLoadingDoctors: $_isLoadingDoctors, _doctors.length: ${_doctors.length}");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Nueva Cita'),
        elevation: 1,
      ),
      body: _isLoadingDoctors
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Cargando doctores...")
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_doctors.isEmpty && !_isLoadingDoctors)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'No hay doctores disponibles en este momento. Intente más tarde.',
                          style: TextStyle(color: Colors.orange.shade700, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Selector de Doctor
                    DropdownButtonFormField<UserProfile>(
                      decoration: InputDecoration(
                        labelText: 'Doctor',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_search_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      value: _selectedDoctor,
                      hint: const Text('Seleccione un doctor'),
                      isExpanded: true,
                      items: _doctors.map((UserProfile doctor) {
                        return DropdownMenuItem<UserProfile>(
                          value: doctor,
                          child: Text("${doctor.name} (${doctor.specialty ?? 'General'})"),
                        );
                      }).toList(),
                      onChanged: _doctors.isEmpty ? null : (UserProfile? newValue) {
                        setState(() {
                          _selectedDoctor = newValue;
                          // _selectedDoctorId = newValue?.id; // Ya no es necesario, usamos _selectedDoctor.id
                          _specialtyController.text = newValue?.specialty ?? '';
                          print("Doctor seleccionado: ${newValue?.name}, Especialidad: ${newValue?.specialty}, ID: ${newValue?.id}");
                        });
                      },
                      validator: (value) => value == null && _doctors.isNotEmpty ? 'Por favor, seleccione un doctor' : null,
                    ),
                    const SizedBox(height: 20),

                    // Campo de Especialidad
                    TextFormField(
                      controller: _specialtyController,
                      decoration: InputDecoration(
                        labelText: 'Especialidad',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.medical_services_outlined),
                        filled: true,
                        fillColor: _selectedDoctor != null && (_selectedDoctor?.specialty?.isNotEmpty ?? false)
                            ? Colors.grey.shade200 // Color de fondo si es de solo lectura
                            : Colors.grey.shade50,
                      ),
                      readOnly: _selectedDoctor != null && (_selectedDoctor?.specialty?.isNotEmpty ?? false),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La especialidad es requerida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Selector de Fecha
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Fecha Deseada',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => value!.isEmpty ? 'Seleccione una fecha' : null,
                    ),
                    const SizedBox(height: 20),

                    // Selector de Hora
                    TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        labelText: 'Hora Deseada',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.access_time_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context),
                      validator: (value) => value!.isEmpty ? 'Seleccione una hora' : null,
                    ),
                    const SizedBox(height: 20),

                    // Motivo de la Cita
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Motivo de la Cita',
                        hintText: 'Breve descripción del motivo...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.notes_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) => _reasonForRequest = value.trim(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingrese el motivo de la cita';
                        }
                        return null;
                      },
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 30),

                    // Botón de Enviar
                    _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            label: const Text('Enviar Solicitud', style: TextStyle(color: Colors.white)),
                            onPressed: _doctors.isEmpty ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
