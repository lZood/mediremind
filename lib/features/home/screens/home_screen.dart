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
import 'package:mediremind/features/profile/screens/user_profile_screen.dart'; // NUEVA PANTALLA DE PERFIL

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ProfileService _profileService = ProfileService();
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
      // _loadUserProfileForAppBar();
    });
  }

  void _navigateToNotifications() {
    // TODO: Navegar a la futura pantalla de notificaciones
    print("Navegar a Notificaciones (Próximamente)");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pantalla de Notificaciones (Próximamente)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("HomeScreen: Construyendo HomeScreen REAL...");
    final user = Supabase.instance.client.auth.currentUser;
    String displayName = _currentUserProfile?.name ?? user?.email?.split('@').first ?? 'Paciente';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Para quitar el botón de "atrás" si esta es la pantalla principal
        titleSpacing: 0, // Ajustar espaciado si es necesario
        leadingWidth: _isLoadingProfileAppBar ? 56 : null, // Ancho para el loader o el botón
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
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Para que el área de tap sea mayor
            child: _isLoadingProfileAppBar
                ? const Text('Cargando...', style: TextStyle(fontSize: 17))
                : Text(displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined), // Ícono de campana
            onPressed: _navigateToNotifications,
            tooltip: 'Notificaciones',
          ),
        ],
        elevation: 1, // Sutil elevación
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
