import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:invigo/pages/login_page.dart'; 
import 'package:invigo/services/auth_service.dart';
import 'package:invigo/models/user_model.dart';
import 'package:invigo/pages/user_settings.dart';

class CustomDrawer extends StatefulWidget {
  final Function(int) onTap;

  CustomDrawer({required this.onTap});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final AuthService _authService = AuthService();
  final supabase = Supabase.instance.client;
  User? _userProfile;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _imageError = false;
    });

    // Cek apakah user sudah login
    _isAuthenticated = _authService.isAuthenticated();

    if (_isAuthenticated) {
      try {
        // Ambil ID user dari auth
        final authUserId = _authService.getCurrentUser()?.id;
        
        if (authUserId != null) {
          // Fetch user profile dari database
          final data = await supabase
              .from('users')
              .select()
              .eq('id_user', authUserId)
              .maybeSingle();
          
          if (data != null) {
            // Gunakan model User Anda
            _userProfile = User.fromJson(data);
            
            if (_userProfile?.profilPicture != null) {
              print('Profile picture URL: ${_userProfile!.profilPicture}');
            } else {
              print('No profile picture set');
            }
          } else {
            print('No user data found for ID: $authUserId');
          }
        }
      } catch (e) {
        print('Error fetching user profile: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.signOut();
      
      // Reset state
      setState(() {
        _isAuthenticated = false;
        _userProfile = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil logout')),
      );
      
      // Navigate to login page and clear history
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with user info
          _buildDrawerHeader(),
          
          // Common navigation options (always show)
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              widget.onTap(0); // Home adalah index 0
            },
          ),
          
          // Items that only show when logged in
          if (_isAuthenticated) ...[
            ListTile(
              leading: Icon(Icons.warehouse),
              title: Text('Warehouse'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                widget.onTap(1); // Warehouse adalah index 1
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Reports'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                widget.onTap(2); // Reports adalah index 2
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                widget.onTap(3); // Profile adalah index 3
              },
            ),
          ],
          
          // Common settings items
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Untuk halaman yang tidak ada di bottom nav, tetap gunakan push
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserSettingsScreen()),
              ).then((_) {
                // Refresh data jika diperlukan setelah kembali dari settings
                _loadUserData();
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.contact_support),
            title: Text('Contact Person'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to contact page (jika ada)
              // Navigator.push(context, MaterialPageRoute(builder: (context) => ContactScreen()));
            },
          ),
          
          // Login/Logout button based on auth state
          const Divider(),
          !_isAuthenticated
              ? ListTile(
                  leading: Icon(Icons.login),
                  title: Text('Login'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    ).then((_) {
                      // Reload user data when returning from login page
                      _loadUserData();
                    });
                  },
                )
              : ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    _logout(context); // Then logout
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: Colors.blue),
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show profile image - user profile or default
                _buildProfileAvatar(),
                SizedBox(height: 10),
                
                // Show name and email based on login status
                if (_isAuthenticated && _userProfile != null) ...[
                  Text(
                    _userProfile!.namaLengkap,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _userProfile!.email,
                    style: TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    'Guest User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Please login to access more features',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
    );
  }
  
  Widget _buildProfileAvatar() {
    // Jika pengguna terotentikasi dan memiliki foto profil
    if (_isAuthenticated && 
        _userProfile != null && 
        _userProfile!.profilPicture != null && 
        _userProfile!.profilPicture!.isNotEmpty &&
        !_imageError) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(_userProfile!.profilPicture!),
        onBackgroundImageError: (e, stackTrace) {
          print('Error loading profile image: $e');
          setState(() {
            _imageError = true;
          });
        },
      );
    } 
    // Jika pengguna terotentikasi tapi tidak punya foto profil, atau ada error memuat gambar
    else if (_isAuthenticated && _userProfile != null) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[300],
        child: Text(
          _userProfile!.namaLengkap.isNotEmpty 
              ? _userProfile!.namaLengkap[0].toUpperCase() 
              : '?',
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );
    } 
    // Jika user tidak terotentikasi 
    else {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage: AssetImage('lib/images/logo2.png'),
      );
    }
  }
}