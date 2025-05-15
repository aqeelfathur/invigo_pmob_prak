import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:invigo/services/auth_service.dart';
import 'package:invigo/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class UserSettingsScreen extends StatefulWidget {
  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final AuthService _authService = AuthService();
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  // Text Editing Controllers untuk form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Form keys untuk validasi
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  // State untuk menampilkan atau menyembunyikan password
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  User? _userProfile;
  File? _imageFile;
  String? _profileImageUrl;
  
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
        
        _userProfile = User.fromJson(userData);
        _profileImageUrl = _userProfile!.profilPicture;
        
        // Set data ke controllers
        _nameController.text = _userProfile!.namaLengkap;
        _emailController.text = _userProfile!.email;
        _phoneController.text = _userProfile!.phoneNumber ?? '';
        
        setState(() {
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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      
      // Upload gambar langsung setelah memilih
      _uploadProfileImage();
    }
  }
  
  Future<void> _uploadProfileImage() async {
  if (_imageFile == null || _userProfile == null) return;
  
  setState(() {
    _isUploadingImage = true;
  });
  
  try {
    // Buat nama file yang unik
    final String fileName = '${_userProfile!.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_imageFile!.path)}';
    final filePath = 'profile_pictures/$fileName';
    
    // Tampilkan informasi debug
    print('Uploading to bucket: userimages');
    print('File path: $filePath');
    
    // Tampilkan daftar bucket yang tersedia untuk debug
    final buckets = await supabase.storage.listBuckets();
    print('Available buckets: ${buckets.map((b) => b.name).join(', ')}');
    
    // Upload file ke Supabase Storage (menggunakan nama bucket yang benar)
    await supabase
        .storage
        .from('userimages')  // Pastikan nama ini persis sama dengan di Supabase
        .upload(filePath, _imageFile!);
    
    // Dapatkan URL publik
    final imageUrl = supabase
        .storage
        .from('userimages')
        .getPublicUrl(filePath);
    
    // Update user profile di database
    await supabase
        .from('users')
        .update({'profil_picture': imageUrl})
        .eq('id_user', _userProfile!.id);
    
    // Update state
    setState(() {
      _profileImageUrl = imageUrl;
      _isUploadingImage = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Foto profil berhasil diperbarui'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print('Error uploading image: $e');
    setState(() {
      _isUploadingImage = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  void dispose() {
    // Pembersihan controllers saat widget di-dispose
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Method untuk update profile
  Future<void> _updateProfile() async {
    if (_profileFormKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        if (_userProfile == null) return;
        
        // Update data user di database
        await supabase
            .from('users')
            .update({
              'nama_lengkap': _nameController.text,
              'phone_number': _phoneController.text.isEmpty ? null : _phoneController.text,
            })
            .eq('id_user', _userProfile!.id);
        
        // Update email jika berubah (perlu konfirmasi dengan Supabase Auth)
        if (_emailController.text != _userProfile!.email) {
          try {
            // Update email di auth
            await supabase.auth.updateUser(
              UserAttributes(
                email: _emailController.text,
              ),
            );
            
            // Update juga di tabel users
            await supabase
                .from('users')
                .update({
                  'email': _emailController.text,
                })
                .eq('id_user', _userProfile!.id);
                
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email berhasil diperbarui. Silakan verifikasi email baru Anda.'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            print('Error updating email: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saat memperbarui email: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
            // Kembalikan nilai email ke yang lama
            _emailController.text = _userProfile!.email;
          }
        }
        
        // Reload user profile
        await _loadUserProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Method untuk update password
  Future<void> _updatePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        // Verifikasi password saat ini dengan mencoba login
        try {
          final response = await supabase.auth.signInWithPassword(
            email: _userProfile!.email,
            password: _currentPasswordController.text,
          );
          
          if (response.user == null) {
            throw Exception('Password saat ini tidak valid');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password saat ini tidak valid'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
        
        // Update password di Supabase Auth
        await supabase.auth.updateUser(
          UserAttributes(
            password: _newPasswordController.text,
          ),
        );
        
        // Reset password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error updating password: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Pengguna'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto profil
                  Center(
                    child: Column(
                      children: [
                        _buildProfilePicture(),
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isUploadingImage ? null : _pickImage,
                          icon: Icon(Icons.photo_camera),
                          label: Text(_isUploadingImage ? 'Mengupload...' : 'Ubah Foto Profil'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Informasi Profil
                  _buildSectionTitle('Informasi Profil'),
                  SizedBox(height: 8),
                  _buildProfileForm(),
                  SizedBox(height: 24),
                  
                  // Ubah Password
                  _buildSectionTitle('Ubah Password'),
                  SizedBox(height: 8),
                  _buildPasswordForm(),
                ],
              ),
            ),
    );
  }

  // Widget untuk foto profil
  Widget _buildProfilePicture() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
            image: _imageFile != null
                ? DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  )
                : _profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
          ),
          child: _profileImageUrl == null && _imageFile == null
              ? Icon(
                  Icons.person,
                  size: 70,
                  color: Colors.grey[700],
                )
              : null,
        ),
        if (_isUploadingImage)
          Positioned.fill(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Widget untuk judul section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Form untuk edit profile
  Widget _buildProfileForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _profileFormKey,
          child: Column(
            children: [
              // Nama Lengkap Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Menonaktifkan edit email untuk keamanan
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  helperText: 'Email tidak dapat diubah secara langsung',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Masukkan email yang valid';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // No. Handphone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'No. Handphone',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 24),
              
              // Tombol Simpan
              ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Form untuk ubah password
  Widget _buildPasswordForm() {
    // ... (unchanged)
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              // Current Password Field
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password saat ini tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // New Password Field
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password baru tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Password tidak sama';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Tombol Ubah Password
              ElevatedButton(
                onPressed: _isSaving ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Ubah Password',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}