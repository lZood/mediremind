// lib/features/profile/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:mediremind/core/models/user_profile.dart'; // Asumiendo que tienes este modelo
import 'package:mediremind/core/services/profile_service.dart'; // Para obtener el perfil
import 'package:supabase_flutter/supabase_flutter.dart'; // Para el logout
// import 'package:mediremind/features/auth/screens/login_screen.dart'; // Para redirigir al login

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });
    try {
      final profile = await _profileService.getMyProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
          if (profile == null) {
            _errorMessage = "No se pudo cargar la información del perfil.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _errorMessage = "Error al cargar perfil: ${e.toString()}";
        });
      }
      print("Error cargando perfil en UserProfileScreen: $e");
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // AuthGate se encargará de redirigir a LoginScreen
        // Opcionalmente, puedes forzar la navegación aquí si es necesario:
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => const LoginScreen()), // Asegúrate de importar LoginScreen
        //   (route) => false,
        // );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión cerrada exitosamente.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildProfileDetailRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'No disponible',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 1,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          onPressed: _loadUserProfile,
                        )
                      ],
                    ),
                  )
                )
              : _userProfile == null // Este caso no debería ocurrir si _errorMessage se maneja bien
                  ? const Center(child: Text('No se encontró información del perfil.'))
                  : RefreshIndicator(
                      onRefresh: _loadUserProfile,
                      child: ListView(
                        padding: const EdgeInsets.all(20.0),
                        children: <Widget>[
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).primaryColorLight,
                              child: Text(
                                _userProfile!.name.isNotEmpty ? _userProfile!.name.substring(0, 1).toUpperCase() : 'P',
                                style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColorDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _userProfile!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                           Center(
                            child: Text(
                              _userProfile!.role.replaceFirstMapped(RegExp(r'\b[a-z]'), (match) => match.group(0)!.toUpperCase()), // Capitalizar rol
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          _buildProfileDetailRow('Correo Electrónico', _userProfile!.email, Icons.email_outlined),
                          // Puedes añadir más detalles del perfil aquí si los tienes en tu modelo UserProfile
                          // y los obtienes desde ProfileService
                          // _buildProfileDetailRow('Teléfono', _userProfile!.phone, Icons.phone_outlined),
                          // _buildProfileDetailRow('Fecha de Registro',
                          //   _userProfile!.createdAt != null
                          //       ? DateFormat('dd MMM, yyyy', 'es_MX').format(_userProfile!.createdAt!)
                          //       : 'N/A',
                          //   Icons.calendar_today_outlined),
                          const Divider(),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
