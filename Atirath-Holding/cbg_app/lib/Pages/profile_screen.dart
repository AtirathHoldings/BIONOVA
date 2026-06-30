import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import 'main_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentIndex = 4;

  // Profile screen editing states
  bool _isEditing = false;
  bool _isLoading = true;
  String? _loadError;
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

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
  String _company = 'Atirath Holding Pvt. Ltd.';
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

  // Temp selected values during edit mode
  late String _tempGender;
  late String _tempBloodGroup;
  late DateTime _tempDOB;

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

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _addressController = TextEditingController();
    _tempGender = '';
    _tempBloodGroup = '';
    _tempDOB = _dob;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await ApiService.getProfile();
      _rawProfile = data;
      _applyProfileData(data);
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
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
    if (rawEmpTyp == 'FTE') friendlyEmpTyp = 'Full-time';
    if (rawEmpTyp == 'CON') friendlyEmpTyp = 'Contractual';
    if (rawEmpTyp == 'RET') friendlyEmpTyp = 'Retired';

    setState(() {
      _employeeCode = data['empCode']?.toString() ?? '';
      _firstName = data['fstNm']?.toString() ?? '';
      _lastName = data['lstNm']?.toString() ?? '';
      _email = data['email']?.toString() ?? '';
      _mobileNumber = data['mobNum']?.toString() ?? '';
      _bloodGroup = data['bldGrp']?.toString() ?? '';
      _address = data['address']?.toString() ?? '';
      _workLocation = data['wLoc']?.toString() ?? '';
      _designation = (data['designation'] ?? data['role'])?.toString() ?? '';
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
      _tempGender = _gender;
      _tempBloodGroup = _bloodGroup;
      _tempDOB = _dob;

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

  Future<void> _selectDOB(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tempDOB,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _tempDOB) {
      setState(() {
        _tempDOB = picked;
      });
    }
  }

  void _startEditing() {
    setState(() {
      _firstNameController.text = _firstName;
      _lastNameController.text = _lastName;
      _emailController.text = _email;
      _mobileController.text = _mobileNumber;
      _addressController.text = _address;
      _tempGender = _gender;
      _tempBloodGroup = _bloodGroup;
      _tempDOB = _dob;
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  void _saveProfileChanges() {
    if (_profileFormKey.currentState!.validate()) {
      setState(() {
        _firstName = _firstNameController.text.trim();
        _lastName = _lastNameController.text.trim();
        _email = _emailController.text.trim();
        _mobileNumber = _mobileController.text.trim();
        _address = _addressController.text.trim();
        _gender = _tempGender;
        _bloodGroup = _tempBloodGroup;
        _dob = _tempDOB;
        _isEditing = false;
      });
      _showSnackBar('Profile updated successfully!');
    }
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _saveProfileImage() async {
    if (_profileImagePath != null) {
      setState(() {
        _savedProfileImagePath = _profileImagePath;
      });
      _showSnackBar('Profile photo saved successfully!');
    } else {
      _showSnackBar('No image to save. Please select an image first.');
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
                  if (_profileImagePath != null)
                    _buildImageOption(
                      icon: Icons.delete_outline,
                      label: 'Remove',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _profileImagePath = null;
                          _savedProfileImagePath = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_profileImagePath != null && _profileImagePath != _savedProfileImagePath)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfileImage,
                    icon: const Icon(Icons.save, size: 18, color: Colors.white),
                    label: const Text(
                      'Save Photo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updatePassword() {
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
      if (_newPasswordController.text.length < 6) {
        _showSnackBar('Password must be at least 6 characters long');
        return;
      }
      _showSnackBar('Password updated successfully!');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFE),
        appBar: CustomHeader(
          title: 'My Profile',
          automaticallyImplyLeading: false,
          onNotificationTap: () {},
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
          onNotificationTap: () {},
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
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
        onNotificationTap: () {},
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
              const SizedBox(height: 16),
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

  // ... (rest of your UI builder methods remain the same)
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
                  child: _profileImagePath != null
                      ? CircleAvatar(
                          radius: 54,
                          backgroundImage: FileImage(File(_profileImagePath!)),
                        )
                      : _savedProfileImagePath != null
                          ? CircleAvatar(
                              radius: 54,
                              backgroundImage: FileImage(File(_savedProfileImagePath!)),
                            )
                          : const CircleAvatar(
                              radius: 54,
                              backgroundColor: Color(0xFFD9E4FF),
                              child: Icon(Icons.person, size: 54, color: Color(0xFF2563EB)),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Text(
                  _profileImagePath != null ? 'Change Photo' : 'Add Photo',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (_profileImagePath != null && _profileImagePath != _savedProfileImagePath) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _saveProfileImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Save Photo',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              if (_savedProfileImagePath != null && _profileImagePath == null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _savedProfileImagePath = null;
                    });
                    _showSnackBar('Profile photo removed');
                  },
                  child: Text(
                    'Remove',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime selectedDate,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(selectedDate),
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            items: items.map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
            )).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              if (!_isEditing)
                TextButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF2563EB)),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),

          if (!_isEditing) ...[
            _buildInfoRow(Icons.person_outline, 'First Name', _firstName),
            _buildInfoRow(Icons.person_outline, 'Second Name', _lastName),
            _buildInfoRow(Icons.wc_outlined, 'Gender', _gender),
            _buildInfoRow(Icons.cake_outlined, 'Date of Birth', _formatDate(_dob)),
            _buildInfoRow(Icons.mail_outline_rounded, 'Email', _email),
            _buildInfoRow(Icons.phone_outlined, 'Mobile Number', _mobileNumber),
            _buildInfoRow(Icons.bloodtype_outlined, 'Blood Group', _bloodGroup),
            _buildInfoRow(Icons.location_on_outlined, 'Address', _address),
          ] else ...[
            Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  _buildEditableField(
                    label: 'First Name',
                    controller: _firstNameController,
                    icon: Icons.person_outline,
                    validator: (val) => val == null || val.trim().isEmpty ? 'First name is required' : null,
                  ),
                  _buildEditableField(
                    label: 'Second Name',
                    controller: _lastNameController,
                    icon: Icons.person_outline,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Second name is required' : null,
                  ),
                  _buildDropdownField(
                    label: 'Gender',
                    value: _tempGender,
                    items: const ['Male', 'Female', 'Other'],
                    icon: Icons.wc_outlined,
                    onChanged: (val) {
                      if (val != null) setState(() => _tempGender = val);
                    },
                  ),
                  _buildDatePickerField(
                    label: 'Date of Birth',
                    selectedDate: _tempDOB,
                    icon: Icons.cake_outlined,
                    onTap: () => _selectDOB(context),
                  ),
                  _buildEditableField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required';
                      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(val.trim())) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  _buildEditableField(
                    label: 'Mobile Number',
                    controller: _mobileController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Mobile number is required' : null,
                  ),
                  _buildDropdownField(
                    label: 'Blood Group',
                    value: _tempBloodGroup,
                    items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                    icon: Icons.bloodtype_outlined,
                    onChanged: (val) {
                      if (val != null) setState(() => _tempBloodGroup = val);
                    },
                  ),
                  _buildEditableField(
                    label: 'Address',
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _cancelEditing,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveProfileChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

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
          _buildInfoRow(Icons.business_outlined, 'Company', _company),
          _buildInfoRow(Icons.factory_outlined, 'Plant', _plant),
          _buildInfoRow(Icons.lan_outlined, 'Department', _department),
          _buildInfoRow(Icons.location_city_outlined, 'Work Location', _workLocation),
          _buildInfoRow(Icons.supervisor_account_outlined, 'Reporting Manager', _reportingManager),
          _buildInfoRow(Icons.calendar_month_outlined, 'Date of Joining', _doj),
          _buildInfoRow(Icons.timelapse_outlined, 'Employee Type', _empType),
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
              'Enter new password (min 6 characters)',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'New password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
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
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _updatePassword,
                icon: const Icon(Icons.lock_open_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Update Password',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
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