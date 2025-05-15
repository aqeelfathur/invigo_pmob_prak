import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:invigo/pages/custom_drawer.dart';
import 'package:invigo/pages/main_screen.dart';
import 'package:invigo/pages/user_settings.dart'; // Import halaman user settings
import 'package:invigo/services/auth_service.dart';
import 'package:invigo/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final supabase = Supabase.instance.client;
  
  User? _userProfile;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cek apakah user sudah login
      final authUser = _authService.getCurrentUser();
      
      if (authUser != null) {
        // Ambil data user dari database
        final userData = await supabase
            .from('users')
            .select()
            .eq('id_user', authUser.id)
            .single();
        
        setState(() {
          _userProfile = User.fromJson(userData);
          _isLoading = false;
        });
      } else {
        // Kembali ke halaman login jika user belum login
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silakan login terlebih dahulu'))
        );
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      drawer: CustomDrawer(
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        },
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _userProfile == null 
              ? Center(child: Text('User tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Widget untuk foto profil (avatar)
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: _userProfile!.profilPicture != null 
                                      ? NetworkImage(_userProfile!.profilPicture!) 
                                      : null,
                                  child: _userProfile!.profilPicture == null
                                      ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[700],
                                        )
                                      : null,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _userProfile!.namaLengkap,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _userProfile!.email,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Widget untuk menampilkan informasi user
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informasi Pengguna',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildInfoRow('Nama Lengkap', _userProfile!.namaLengkap),
                                  Divider(),
                                  _buildInfoRow('Email', _userProfile!.email),
                                  Divider(),
                                  _buildInfoRow('No. Handphone', 
                                      _userProfile!.phoneNumber ?? 'Belum diatur'),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Widget untuk navigasi ke halaman pengaturan
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UserSettingsScreen()),
                              ).then((_) {
                                // Refresh profile setelah kembali dari settings
                                _loadUserProfile();
                              });
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.settings, size: 28, color: Theme.of(context).primaryColor),
                                    SizedBox(width: 16),
                                    Text(
                                      'Pengaturan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Widget untuk tombol logout
                          InkWell(
                            onTap: () => _handleLogout(context),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 28, color: Colors.red),
                                    SizedBox(width: 16),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // Helper method untuk membuat baris informasi
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Fungsi untuk handle logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil logout')),
      );
      
      // Kembali ke halaman utama
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat logout: $e')),
      );
    }
  }
}