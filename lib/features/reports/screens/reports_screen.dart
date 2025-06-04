// lib/features/reports/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:mediremind/core/models/medication_intake.dart';
import 'package:mediremind/core/models/user_profile.dart';
import 'package:mediremind/core/models/vital_sign.dart';
import 'package:mediremind/core/services/medication_intake_service.dart';
import 'package:mediremind/core/services/profile_service.dart';
import 'package:mediremind/core/services/vital_sign_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Para vista previa e impresión/guardado

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ProfileService _profileService = ProfileService();
  final MedicationIntakeService _medicationIntakeService = MedicationIntakeService();
  final VitalSignService _vitalSignService = VitalSignService();

  DateTimeRange? _selectedDateRange;
  bool _includeMedicationHistory = true;
  bool _includeVitalSignsHistory = true;
  bool _isGeneratingReport = false;

  UserProfile? _currentUserProfile;
  List<MedicationIntake> _medicationIntakes = [];
  List<VitalSign> _vitalSigns = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Cargar perfil del usuario para tenerlo disponible
    try {
      _currentUserProfile = await _profileService.getMyProfile();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error cargando perfil en ReportsScreen: $e");
    }
  }


  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(DateTime.now().year - 5), // 5 años atrás
      lastDate: DateTime.now(), // Hasta hoy
      locale: const Locale('es', 'MX'),
      helpText: 'SELECCIONA RANGO DE FECHAS',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _fetchDataForReport() async {
    if (_currentUserProfile == null) {
      await _loadInitialData(); 
      if (_currentUserProfile == null && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el perfil del usuario.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (_includeMedicationHistory) {
      try {
        _medicationIntakes = await _medicationIntakeService.getMyMedicationIntakes();
        if (_selectedDateRange != null) {
          _medicationIntakes = _medicationIntakes.where((intake) {
            try {
              final intakeDate = DateFormat('yyyy-MM-dd').parseStrict(intake.date);
              return !intakeDate.isBefore(_selectedDateRange!.start) &&
                     !intakeDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)));
            } catch (e) { return false; }
          }).toList();
        }
      } catch (e) {
        print("Error obteniendo historial de tomas: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al obtener historial de tomas: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
        _medicationIntakes = [];
      }
    } else {
      _medicationIntakes = [];
    }

    if (_includeVitalSignsHistory) {
      try {
        _vitalSigns = await _vitalSignService.getMyVitalSigns();
         if (_selectedDateRange != null) {
          _vitalSigns = _vitalSigns.where((vs) {
             try {
              final vsDate = DateFormat('yyyy-MM-dd').parseStrict(vs.date);
              return !vsDate.isBefore(_selectedDateRange!.start) &&
                     !vsDate.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)));
            } catch (e) { return false; }
          }).toList();
        }
      } catch (e) {
        print("Error obteniendo historial de signos vitales: $e");
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al obtener historial de signos vitales: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
        _vitalSigns = [];
      }
    } else {
      _vitalSigns = [];
    }
  }

  Future<void> _generateAndShowPdf() async {
    if (!_includeMedicationHistory && !_includeVitalSignsHistory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un tipo de historial para incluir en el reporte.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() { _isGeneratingReport = true; });
    await _fetchDataForReport();

    if ((_includeMedicationHistory && _medicationIntakes.isEmpty) && (_includeVitalSignsHistory && _vitalSigns.isEmpty) && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos disponibles para el rango de fechas y selecciones especificadas.'), backgroundColor: Colors.orange),
      );
      setState(() { _isGeneratingReport = false; });
      return;
    }


    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');
    final timeFormat = DateFormat('hh:mm a', 'es_MX');

    // --- Página de Título e Información del Paciente ---
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Reporte de Salud del Paciente', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Generado el: ${dateFormat.format(DateTime.now())} a las ${timeFormat.format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            if (_currentUserProfile != null) ...[
              pw.Text('Información del Paciente:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Nombre: ${_currentUserProfile!.name}'),
              pw.Text('Email: ${_currentUserProfile!.email}'),
            ] else ...[
              pw.Text('Información del Paciente no disponible.'),
            ],
            pw.SizedBox(height: 10),
            if (_selectedDateRange != null)
              pw.Text('Periodo del Reporte: ${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}')
            else
              pw.Text('Periodo del Reporte: Todos los datos disponibles'), // <<< COMA AÑADIDA AQUÍ
            pw.SizedBox(height: 30),
            pw.Text('Contenido del Reporte:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (_includeMedicationHistory) pw.Text('- Historial de Tomas de Medicamentos'),
            if (_includeVitalSignsHistory) pw.Text('- Historial de Signos Vitales'),
          ],
        );
      },
    ));

    // --- Historial de Tomas de Medicamentos ---
    if (_includeMedicationHistory && _medicationIntakes.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => pw.Header(level: 1, text: 'Historial de Tomas de Medicamentos'),
        build: (pw.Context context) => [
          pw.Table.fromTextArray(
            headers: ['Fecha', 'Hora', 'Medicamento', 'Principio Activo', 'Tomado'],
            data: _medicationIntakes.map((intake) {
               String displayIntakeDate = 'N/A'; // Renombrado para evitar conflicto
               String displayTime = 'N/A';
                try {
                    final dateP = DateFormat('yyyy-MM-dd').parseStrict(intake.date);
                    displayIntakeDate = dateFormat.format(dateP); // Usar la variable renombrada
                    // Parsear la hora asumiendo que puede o no tener segundos
                    final timeParts = intake.time.split(':');
                    final hour = int.parse(timeParts[0]);
                    final minute = int.parse(timeParts[1]);
                    // final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0; // Opcional
                    final timeP = DateTime(2000,1,1,hour, minute /*, second*/);
                    displayTime = timeFormat.format(timeP);
                } catch(e) { 
                  print("Error formateando fecha/hora de toma para PDF: ${intake.date} ${intake.time} - $e");
                }

              return [
                displayIntakeDate, // Usar la variable renombrada
                displayTime,
                intake.medication?.name ?? 'Desconocido',
                intake.medication?.activeIngredient ?? 'N/A',
                intake.taken ? 'Sí' : 'No',
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {0: pw.Alignment.centerLeft, 4: pw.Alignment.center},
          ),
        ],
      ));
    }

    // --- Historial de Signos Vitales ---
    if (_includeVitalSignsHistory && _vitalSigns.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => pw.Header(level: 1, text: 'Historial de Signos Vitales'),
        build: (pw.Context context) => [
          pw.Table.fromTextArray(
            headers: ['Fecha', 'Hora', 'Tipo', 'Valor', 'Unidad'],
            data: _vitalSigns.map((vs) {
              String displayVSDate = 'N/A'; // Renombrado
              String displayVSTime = 'N/A';
              try {
                  final dateP = DateFormat('yyyy-MM-dd').parseStrict(vs.date);
                  displayVSDate = dateFormat.format(dateP); // Usar la variable renombrada
                  final timeParts = vs.time.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = int.parse(timeParts[1]);
                  // final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0; // Opcional
                  final timeP = DateTime(2000,1,1,hour, minute /*, second*/);
                  displayVSTime = timeFormat.format(timeP);
              } catch(e) {
                 print("Error formateando fecha/hora de signo vital para PDF: ${vs.date} ${vs.time} - $e");
              }
              return [
                displayVSDate, // Usar la variable renombrada
                displayVSTime,
                vs.type,
                vs.value.toString(),
                vs.unit,
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {0: pw.Alignment.centerLeft, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerLeft},
          ),
        ],
      ));
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reporte_MediRemind_${_currentUserProfile?.name?.replaceAll(' ', '_') ?? "Paciente"}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');

    if (mounted) {
      setState(() { _isGeneratingReport = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Generar Reporte PDF',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text(
                _selectedDateRange == null
                    ? 'Seleccionar Rango de Fechas (Opcional)'
                    : 'Periodo: ${DateFormat('dd/MM/yy', 'es_MX').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy', 'es_MX').format(_selectedDateRange!.end)}',
              ),
              trailing: _selectedDateRange != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(()=> _selectedDateRange = null)) : null,
              onTap: () => _selectDateRange(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300)
              ),
            ),
            const SizedBox(height: 20),
            Text('Incluir en el Reporte:', style: Theme.of(context).textTheme.titleMedium),
            CheckboxListTile(
              title: const Text('Historial de Tomas de Medicamentos'),
              value: _includeMedicationHistory,
              onChanged: (bool? value) {
                setState(() {
                  _includeMedicationHistory = value ?? false;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            CheckboxListTile(
              title: const Text('Historial de Signos Vitales'),
              value: _includeVitalSignsHistory,
              onChanged: (bool? value) {
                setState(() {
                  _includeVitalSignsHistory = value ?? false;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 30),
            _isGeneratingReport
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Generar y Ver Reporte PDF'),
                    onPressed: _generateAndShowPdf,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
