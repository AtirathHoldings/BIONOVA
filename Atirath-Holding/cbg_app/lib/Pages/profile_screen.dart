import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentIndex = 4;
  int _unreadNotificationCount = 0;

  bool _isLoading = false;
  String? _loadError;

  // Profile data state — populated from DB
  String _employeeCode = '';
  String _firstName = '';
  String _lastName = '';
  String _gender = '';
  DateTime _dob = DateTime(1990, 1, 1);
  String _email = '';
  String _mobileNumber = '';
  String _bloodGroup = '';
  String _address = '';
  String _doj = '';
  String _empType = '';
  String _designation = ''; // role from DB
  String _company = '';
  String _plant = '';
  String _department = '';
  String _workLocation = '';
  String _reportingManager = '';
  Map<String, dynamic> _rawProfile = {};

  // Text controllers for editing profile
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;



  // Password visibility states
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Profile image state
  String? _profileImagePath;
  String? _savedProfileImagePath;
  final ImagePicker _picker = ImagePicker();

  // Text controllers for password change
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Form key for password validation
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  // State to track updating password API request status
  bool _isUpdatingPassword = false;

  
  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _addressController = TextEditingController();

    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    debugPrint("🔄 Fetching profile data...");
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getUnreadNotifications(),
      ]);
      _rawProfile = results[0] as Map<String, dynamic>;
      final unreadNotifications = results[1] as List<dynamic>;
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
      debugPrint("✅ Profile fetched successfully");
      _applyProfileData(_rawProfile);
    } catch (e) {
      debugPrint("❌ Error fetching profile: $e");
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final unreadNotifications = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  void _applyProfileData(Map<String, dynamic> data) {
    final String rawDob = data['dob']?.toString() ?? '';
    final String rawDoj = data['doj']?.toString() ?? '';
    final String rawGender = data['gender']?.toString() ?? '';
    final String rawEmpTyp = data['empTyp']?.toString() ?? '';

    DateTime parsedDob = DateTime(1990, 1, 1);
    try { parsedDob = DateTime.parse(rawDob); } catch (_) {}

    String friendlyGender = rawGender;
    if (rawGender == 'MALE') friendlyGender = 'Male';
    if (rawGender == 'FEMALE') friendlyGender = 'Female';
    if (rawGender == 'OTHER') friendlyGender = 'Other';

    String friendlyEmpTyp = rawEmpTyp;
    if (rawEmpTyp == 'FTE') friendlyEmpTyp = 'Full-time Employee';
    if (rawEmpTyp == 'CON') friendlyEmpTyp = 'Contract Employee';
    if (rawEmpTyp == 'RET') friendlyEmpTyp = 'Retainer';

    setState(() {
      _employeeCode = data['empCode']?.toString() ?? '';
      _firstName = data['fstNm']?.toString() ?? '';
      _lastName = data['lstNm']?.toString() ?? '';
      _email = data['email']?.toString() ?? '';
      _mobileNumber = data['mobNum']?.toString() ?? '';
      _bloodGroup = data['bldGrp']?.toString() ?? '';
      _address = data['address']?.toString() ?? '';
      _workLocation = data['wLoc']?.toString() ?? data['wloc']?.toString() ?? '';
      _designation = data['designation']?.toString() ?? data['role']?.toString() ?? data['desigId']?.toString() ?? '';
      _company = data['coyNm']?.toString() ?? data['coyId']?.toString() ?? '';
      _plant = data['pltNm']?.toString() ?? data['pltId']?.toString() ?? '';
      _department = data['deptNm']?.toString() ?? data['deptId']?.toString() ?? '';
      _reportingManager = data['repManNm']?.toString() ?? data['repManId']?.toString() ?? '';
      _gender = friendlyGender;
      _dob = parsedDob;
      _empType = friendlyEmpTyp;
      _doj = _formatDate(_parseDate(rawDoj));

      // Seed text controllers
      _firstNameController.text = _firstName;
      _lastNameController.text = _lastName;
      _emailController.text = _email;
      _mobileController.text = _mobileNumber;
      _addressController.text = _address;


      _savedProfileImagePath = data['photoUrl']?.toString();
      _isLoading = false;
    });
  }

  DateTime _parseDate(String raw) {
    try { return DateTime.parse(raw); } catch (_) { return DateTime(1990, 1, 1); }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }
// ============ UPLOAD PHOTO WITH REACT FLOW ============
Future<void> _uploadAndSavePhoto(String filePath) async {
  debugPrint("🚀 ===== PROFILE PHOTO UPLOAD STARTED (React Flow) =====");
  debugPrint("📁 Selected file path: $filePath");
  
  // Check if file exists
  final file = File(filePath);
  final bool fileExists = await file.exists();
  debugPrint("📂 File exists: $fileExists");
  
  if (fileExists) {
    final int fileSize = await file.length();
    debugPrint("📊 File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)");
  } else {
    debugPrint("❌ ERROR: File does not exist at path: $filePath");
    setState(() {
      _isLoading = false;
    });
    _showSnackBar('Error: File not found');
    return;
  }

  setState(() {
    _isLoading = true;
  });
  
  try {
    final int? empId = _rawProfile['empId'] as int?;
    debugPrint("👤 Employee ID: $empId");
    
    if (empId == null) {
      debugPrint("❌ ERROR: Employee ID not found in profile");
      throw Exception("Employee ID not found.");
    }
    
    // STEP 1: Upload photo to storage (React flow)
    debugPrint("📤 STEP 1: Uploading photo to storage...");
    debugPrint("📤 POST /api/storage/upload/employee-photo");
    _showSnackBar('Uploading photo to server...');
    
    final String uploadedUrl = await ApiService.uploadEmployeePhoto(file);
    
    debugPrint("✅ STEP 1 complete! Uploaded URL: $uploadedUrl");
    
    // STEP 2: Update employee profile with the URL (React flow)
    debugPrint("📤 STEP 2: Updating employee profile with photo URL...");
    debugPrint("📤 PUT /api/employees/$empId with photoUrl: $uploadedUrl");
    
    final Map<String, dynamic> updatedData = Map<String, dynamic>.from(_rawProfile);
    updatedData['photoUrl'] = uploadedUrl;
    
    final bool updateSuccess = await ApiService.updateProfile(empId, updatedData);
    debugPrint("📥 Update profile response: $updateSuccess");
    
    if (!updateSuccess) {
      throw Exception("Failed to update employee profile with photo URL");
    }
    
    debugPrint("✅ STEP 2 complete! Profile updated successfully!");
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profilePhotoUrl', uploadedUrl);
    debugPrint("💾 Saved profile photo URL to SharedPreferences");
    
    // Update UI state
    setState(() {
      _savedProfileImagePath = uploadedUrl;
      _profileImagePath = null;
      _rawProfile['photoUrl'] = uploadedUrl;
      _isLoading = false;
    });
    
    debugPrint("🎉 Profile photo update complete!");
    _showSnackBar('Profile photo updated successfully!');
    
  } catch (e) {
    debugPrint("❌ EXCEPTION in _uploadAndSavePhoto: $e");
    debugPrint("🔴 Stack trace: ${StackTrace.current}");
    setState(() {
      _isLoading = false;
    });
    _showSnackBar('Update failed: $e');
  }
}

  Future<void> _pickImageFromGallery() async {
    debugPrint("📸 Opening gallery to pick image...");
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        debugPrint("✅ Image picked from gallery: ${image.path}");
        await _uploadAndSavePhoto(image.path);
      } else {
        debugPrint("ℹ️ User cancelled gallery pick");
      }
    } catch (e) {
      debugPrint("❌ Error picking image from gallery: $e");
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    debugPrint("📸 Opening camera...");
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        debugPrint("✅ Image captured from camera: ${image.path}");
        await _uploadAndSavePhoto(image.path);
      } else {
        debugPrint("ℹ️ User cancelled camera");
      }
    } catch (e) {
      debugPrint("❌ Error taking photo: $e");
      _showSnackBar('Error taking photo: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  if (_savedProfileImagePath != null)
                    _buildImageOption(
                      icon: Icons.delete_outline,
                      label: 'Remove',
                      color: Colors.red,
                      onTap: () async {
                        debugPrint("🗑️ User requested to remove profile photo");
                        Navigator.pop(context);
                        setState(() {
                          _isLoading = true;
                        });
                        
                        final int? empId = _rawProfile['empId'] as int?;
                        if (empId != null) {
                          debugPrint("👤 Removing photo for employee: $empId");
                          final updatedData = Map<String, dynamic>.from(_rawProfile);
                          updatedData['photoUrl'] = null;
                          final success = await ApiService.updateProfile(empId, updatedData);
                          debugPrint("📤 Remove photo API response: $success");
                          
                          if (success) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('profilePhotoUrl');
                            debugPrint("🗑️ Removed profile photo URL from SharedPreferences");
                            setState(() {
                              _savedProfileImagePath = null;
                              _profileImagePath = null;
                              _rawProfile['photoUrl'] = null;
                            });
                            _showSnackBar('Profile photo removed successfully!');
                          } else {
                            debugPrint("❌ Failed to remove profile photo");
                            _showSnackBar('Failed to remove profile photo.');
                          }
                        }
                        
                        setState(() {
                          _isLoading = false;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    debugPrint("📢 SnackBar: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Must be at least 8 characters';
    }
    if (value.contains(' ')) {
      return 'Spaces are not allowed';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain at least one capital letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) {
      return 'Must contain at least one special character';
    }
    return null;
  }

  void _updatePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      if (_currentPasswordController.text.isEmpty) {
        _showSnackBar('Please enter current password');
        return;
      }
      if (_newPasswordController.text.isEmpty) {
        _showSnackBar('Please enter new password');
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnackBar('New password and confirm password do not match');
        return;
      }
      if (_newPasswordController.text.length < 8) {
        _showSnackBar('Password must be at least 8 characters long');
        return;
      }
      if (_currentPasswordController.text == _newPasswordController.text) {
        _showSnackBar('New password cannot be the same as the current password');
        return;
      }

      setState(() {
        _isUpdatingPassword = true;
      });

      try {
        await ApiService.changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
        _showSnackBar('Password updated successfully! Please login again with your new password.');
        
        // Force logout
        await ApiService.clearCache(clearAuth: true);
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/signin', 
            (route) => false
          );
        }
      } catch (e) {
        final errorMessage = e.toString().replaceAll("Exception:", "").trim();
        _showSnackBar(errorMessage.isNotEmpty ? errorMessage : 'Failed to update password');
      } finally {
        if (mounted) {
          setState(() {
            _isUpdatingPassword = false;
          });
        }
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFE),
        appBar: CustomHeader(
          title: 'My Profile',
          automaticallyImplyLeading: false,
          notificationCount: _unreadNotificationCount,
          onNotificationTap: () async {
            await Navigator.pushNamed(context, '/notifications');
            _fetchNotificationCount();
          },
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
        bottomNavigationBar: CustomFooter(
          currentIndex: _currentIndex,
          onTabSelected: (index) {
            if (MainScreen.navigatorKey.currentState != null) {
              MainScreen.navigatorKey.currentState!.changeTab(index);
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFE),
        appBar: CustomHeader(
          title: 'My Profile',
          automaticallyImplyLeading: false,
          notificationCount: _unreadNotificationCount,
          onNotificationTap: () async {
            await Navigator.pushNamed(context, '/notifications');
            _fetchNotificationCount();
          },
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load profile', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomFooter(
          currentIndex: _currentIndex,
          onTabSelected: (index) {
            if (MainScreen.navigatorKey.currentState != null) {
              MainScreen.navigatorKey.currentState!.changeTab(index);
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: CustomHeader(
        title: 'My Profile',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _fetchNotificationCount();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileAvatarCard(),
              const SizedBox(height: 16),
              _buildProfileInfoCard(),
              const SizedBox(height: 16),
              _buildAccountSecurityCard(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          if (MainScreen.navigatorKey.currentState != null) {
            MainScreen.navigatorKey.currentState!.changeTab(index);
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else if (path.startsWith('data:image')) {
      try {
        final base64Content = path.split(',').last;
        return MemoryImage(base64Decode(base64Content));
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
      }
    }
    return FileImage(File(path));
  }

  Widget _buildProfileAvatarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _profileImagePath != null && _profileImagePath != _savedProfileImagePath
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF2563EB),
                      width: _profileImagePath != null && _profileImagePath != _savedProfileImagePath ? 3 : 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundImage: _profileImagePath != null
                        ? _getImageProvider(_profileImagePath!)
                        : _savedProfileImagePath != null && _savedProfileImagePath!.isNotEmpty
                            ? _getImageProvider(_savedProfileImagePath!)
                            : null,
                    backgroundColor: const Color(0xFFD9E4FF),
                    child: (_profileImagePath == null && (_savedProfileImagePath == null || _savedProfileImagePath!.isEmpty))
                        ? const Icon(Icons.person, size: 54, color: Color(0xFF2563EB))
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                  ),
                ),
              ),
              if (_profileImagePath != null && _profileImagePath != _savedProfileImagePath)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Unsaved',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_firstName $_lastName',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            _designation,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _employeeCode,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Personal Information',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),

          _buildInfoRow(Icons.person_outline, 'First Name', _firstName),
          _buildInfoRow(Icons.person_outline, 'Second Name', _lastName),
          _buildInfoRow(Icons.wc_outlined, 'Gender', _gender),
          _buildInfoRow(Icons.cake_outlined, 'Date of Birth', _formatDate(_dob)),
          _buildInfoRow(Icons.mail_outline_rounded, 'Email', _email),
          _buildInfoRow(Icons.phone_outlined, 'Mobile Number', _mobileNumber),
          _buildInfoRow(Icons.bloodtype_outlined, 'Blood Group', _bloodGroup),
          _buildInfoRow(Icons.location_on_outlined, 'Address', _address),

          // Work Information Section
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.business_center_outlined, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'Work Information',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),

          _buildInfoRow(Icons.badge_outlined, 'Employee Code', _employeeCode),
          _buildInfoRow(Icons.assignment_ind_outlined, 'Designation', _designation),
          if (_company.isNotEmpty && _company != 'null' && _company != '0')
            _buildInfoRow(Icons.business_outlined, 'Company', _company),
          if (_plant.isNotEmpty && _plant != 'null' && _plant != '0' && _plant != 'DBG_NO_PLT_MATCH')
            _buildInfoRow(Icons.factory_outlined, 'Plant', _plant),
          _buildInfoRow(Icons.lan_outlined, 'Department', _department),
          _buildInfoRow(Icons.location_city_outlined, 'Work Location', _workLocation),
          _buildInfoRow(Icons.supervisor_account_outlined, 'Reporting Manager', _reportingManager),
          _buildInfoRow(Icons.calendar_month_outlined, 'Date of Joining', _doj),
          _buildInfoRow(Icons.timelapse_outlined, 'Employment Type', _empType),
          _buildInfoStatusRow(Icons.timelapse_outlined, 'Status', 'Active'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const Text(':', style: TextStyle(color: Color(0xFF94A3B8))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStatusRow(IconData icon, String label, String statusText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const Text(':', style: TextStyle(color: Color(0xFF94A3B8))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 20, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(
                  'Account & Security',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFF1F5F9), height: 1),
            ),
            _buildInputFieldLabel('Current Password'),
            _buildPasswordField(
              _currentPasswordController,
              _obscureCurrent,
              () => setState(() => _obscureCurrent = !_obscureCurrent),
              'Enter current password',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Current password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildInputFieldLabel('New Password'),
            _buildPasswordField(
              _newPasswordController,
              _obscureNew,
              () => setState(() => _obscureNew = !_obscureNew),
              'Enter new password (min 8 characters)',
              validator: _validatePassword,
              onChanged: (val) => _passwordFormKey.currentState?.validate(),
            ),
            const SizedBox(height: 12),
            _buildInputFieldLabel('Confirm New Password'),
            _buildPasswordField(
              _confirmPasswordController,
              _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm),
              'Confirm new password',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onChanged: (val) => _passwordFormKey.currentState?.validate(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingPassword ? null : _updatePassword,
                icon: _isUpdatingPassword
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.lock_open_rounded, size: 16, color: Colors.white),
                label: Text(
                  _isUpdatingPassword ? 'Updating...' : 'Update Password',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
    String hint, {
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 12.5),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(fontSize: 10),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 16,
            color: const Color(0xFF64748B),
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
