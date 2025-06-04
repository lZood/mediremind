// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Para el User
import 'package:mediremind/core/models/user_profile.dart'; // Para el tipo UserProfile
import 'package:mediremind/core/services/profile_service.dart'; // Para cargar el perfil

// Importa las pantallas de cada sección
import 'package:mediremind/features/reminders/screens/medication_schedule_screen.dart';
import 'package:mediremind/features/vital_signs/screens/vital_signs_overview_screen.dart';
import 'package:mediremind/features/appointments/screens/appointments_list_screen.dart';
import 'package:mediremind/features/reports/screens/reports_screen.dart';
import 'package:mediremind/features/profile/screens/user_profile_screen.dart';

// NUEVAS IMPORTACIONES
import 'package:mediremind/core/services/fcm_service.dart'; // Para el servicio FCM
import 'package:mediremind/features/notifications/screens/notifications_history_screen.dart'; // Para la pantalla de historial de notificaciones

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();
  final FcmService _fcmService = FcmService(); // Instanciar FcmService
  UserProfile? _currentUserProfile;
  bool _isLoadingProfileAppBar = true; // Para el loader del AppBar

  static final List<Widget> _widgetOptions = <Widget>[
    const MedicationScheduleScreen(),
    const VitalSignsOverviewScreen(),
    const AppointmentsListScreen(),
    const ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfileForAppBar();
    _initializeFCM(); // Llamar a la inicialización de FCM
  }

  Future<void> _loadUserProfileForAppBar() async {
    if (!mounted) return;
    setState(() { _isLoadingProfileAppBar = true; });
    try {
      final profile = await _profileService.getMyProfile();
      if (mounted) {
        setState(() {
          _currentUserProfile = profile;
          _isLoadingProfileAppBar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingProfileAppBar = false; });
      }
      print("Error cargando perfil para AppBar en HomeScreen: $e");
      // Considerar mostrar un SnackBar o mensaje al usuario si falla la carga del perfil
    }
  }

  // NUEVO MÉTODO para inicializar FCM
  Future<void> _initializeFCM() async {
    // Podrías esperar a que _loadUserProfileForAppBar complete si necesitas datos del perfil
    // para registrar el token inmediatamente, o manejarlo dentro de FcmService.
    // Por ahora, lo llamamos directamente. FcmService ya tiene lógica para
    // obtener el perfil y actualizar el token.
    try {
      print("HomeScreen: Inicializando FCM y solicitando permisos...");
      await _fcmService.initializeAndRequestPermission();
      print("HomeScreen: Permisos FCM y token gestionados.");
    } catch (e) {
      print("HomeScreen: Error inicializando FCM: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al configurar notificaciones: ${e.toString()}')),
        );
      }
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
    ).then((_) {
      // Opcional: Recargar perfil si algo pudo haber cambiado en UserProfileScreen
      _loadUserProfileForAppBar(); // Recargar para reflejar cambios del perfil si los hubo
    });
  }

  // MODIFICADO para navegar a la pantalla de historial
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("HomeScreen: Construyendo HomeScreen REAL...");
    final user = Supabase.instance.client.auth.currentUser;
    String displayName = _currentUserProfile?.name ?? user?.email?.split('@').first ?? 'Paciente';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leadingWidth: _isLoadingProfileAppBar ? 56 : null,
        leading: _isLoadingProfileAppBar
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              )
            : IconButton(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Text(
                    displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'P',
                    style: TextStyle(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold),
                  ),
                ),
                onPressed: _navigateToProfile,
                tooltip: 'Ver Perfil',
              ),
        title: InkWell(
          onTap: _navigateToProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _isLoadingProfileAppBar
                ? const Text('Cargando...', style: TextStyle(fontSize: 17))
                : Text(displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: _navigateToNotifications,
            tooltip: 'Notificaciones',
          ),
        ],
        elevation: 1,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_on_outlined),
            label: 'Mis Tomas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            label: 'Signos Vitales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Citas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            label: 'Reportes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}