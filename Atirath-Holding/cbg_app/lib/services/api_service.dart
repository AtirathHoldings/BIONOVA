import 'dart:convert';
import 'package:flutter/material.dart';
import 'custom_http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../models/project_model.dart';
import '../models/task_item.dart';

class ApiService {
  // ==================== IN-MEMORY GLOBAL CACHE ====================
  static List<ProjectModel>? _cachedProjects;
  static List<TaskItem>? _cachedLiveTasks;
  static List<dynamic>? _cachedIndividualTasks;
  static Map<String, dynamic>? _cachedDashboardData;
  static Map<String, dynamic>? _cachedProfile;
  static List<dynamic>? _cachedEmployees;
  static bool _isPreloading = false;

  static Future<void> clearCache({bool clearAuth = false}) async {
    _cachedProjects = null;
    _cachedLiveTasks = null;
    _cachedIndividualTasks = null;
    _cachedDashboardData = null;
    _cachedProfile = null;
    _cachedEmployees = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_userName');
      await prefs.remove('cache_myTasksCount');
      await prefs.remove('cache_openTasksCount');
      await prefs.remove('cache_inProgressTasksCount');
      await prefs.remove('cache_overdueTasksCount');
      await prefs.remove('cache_completedTasksCount');
      await prefs.remove('cache_projectsCount');
      await prefs.remove('cached_employee_list');
      if (clearAuth) {
        await prefs.remove('profilePhotoUrl');
        await prefs.remove('userRole');
        await prefs.remove('userEmail');
        await prefs.remove('currentEmpId');
        await prefs.remove('authToken');
      }
    } catch (e) {
      debugPrint("Error clearing ApiService cache: $e");
    }
  }

  static Future<void> preloadAllData({bool forceRefresh = false}) async {
    if (_isPreloading && !forceRefresh) return;
    _isPreloading = true;
    try {
      await Future.wait([
        getLiveProjects(forceRefresh: forceRefresh),
        getLiveTasks(forceRefresh: forceRefresh),
        getIndividualTasks(forceRefresh: forceRefresh),
        getUserDashboardData(forceRefresh: forceRefresh),
        getProfile(forceRefresh: forceRefresh),
        getEmployees(forceRefresh: forceRefresh),
      ]);
    } catch (e) {
      debugPrint("Preloading data error: $e");
    } finally {
      _isPreloading = false;
    }
  }

  // ==================== PROJECTS ====================
  
  static Future<List<ProjectModel>> getLiveProjects({bool forceRefresh = false}) async {
    if (_cachedProjects != null && !forceRefresh) {
      return _cachedProjects!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("Token not found");
      }

      final role = prefs.getString('userRole') ?? '';
      final currentEmpId = await getCurrentEmployeeId();

      final bool isEmployee = currentEmpId != null &&
          role.isNotEmpty &&
          role.toLowerCase() != 'admin' &&
          role.toLowerCase() != 'manager';

      final url = isEmployee
          ? "${dotenv.env['BASE_URL']}/api/project-live/by-employee/$currentEmpId"
          : "${dotenv.env['BASE_URL']}/api/project-live";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((json) => ProjectModel.fromJson(json)).toList();
        _cachedProjects = list;
        return list;
      } else {
        throw Exception("Failed to load projects : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching live projects: $e");
      return [];
    }
  }

  // ==================== PROFILE ====================
  
  static Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    if (_cachedProfile != null && !forceRefresh) {
      return _cachedProfile!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final profileData = Map<String, dynamic>.from(jsonDecode(response.body));
        _cachedProfile = profileData;
        
        // Save profile photo URL to SharedPreferences
        if (profileData['photoUrl'] != null) {
          await prefs.setString('profilePhotoUrl', profileData['photoUrl'].toString());
        } else {
          await prefs.remove('profilePhotoUrl');
        }
        
        try {
          final headers = {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          };
          final baseUrl = dotenv.env['BASE_URL'];
          
          final futures = await Future.wait([
            http.get(Uri.parse("$baseUrl/api/companies"), headers: headers),
            http.get(Uri.parse("$baseUrl/api/plants"), headers: headers),
            http.get(Uri.parse("$baseUrl/api/departments"), headers: headers),
            http.get(Uri.parse("$baseUrl/api/employees"), headers: headers)
          ]);
          
          if (profileData['coyId'] != null && futures[0].statusCode == 200) {
            final parsed = jsonDecode(futures[0].body);
            final List list = parsed is List ? parsed : (parsed['data'] ?? parsed['content'] ?? parsed['items'] ?? []);
            final matched = list.firstWhere((e) {
              final id = e['coyId'] ?? e['coy_id'] ?? e['id'];
              return id?.toString() == profileData['coyId']?.toString();
            }, orElse: () => null);
            if (matched != null) profileData['coyNm'] = matched['coyNm'] ?? matched['coy_nm'] ?? matched['companyNm'] ?? matched['companyName'] ?? matched['name'];
          }
          if (profileData['pltId'] != null && futures[1].statusCode == 200) {
            final parsed = jsonDecode(futures[1].body);
            final List list = parsed is List ? parsed : (parsed['data'] ?? parsed['content'] ?? parsed['items'] ?? []);
            final matched = list.firstWhere((e) {
              final id = e['pltId'] ?? e['plt_id'] ?? e['id'];
              return id?.toString() == profileData['pltId']?.toString();
            }, orElse: () => null);
            if (matched != null) profileData['pltNm'] = matched['pltNm'] ?? matched['plt_nm'] ?? matched['plantNm'] ?? matched['plantName'] ?? matched['name'];
          }
          if (profileData['deptId'] != null && futures[2].statusCode == 200) {
            final parsed = jsonDecode(futures[2].body);
            final List list = parsed is List ? parsed : (parsed['data'] ?? parsed['content'] ?? parsed['items'] ?? []);
            final matched = list.firstWhere((e) {
              final id = e['deptId'] ?? e['dept_id'] ?? e['id'];
              return id?.toString() == profileData['deptId']?.toString();
            }, orElse: () => null);
            if (matched != null) profileData['deptNm'] = matched['deptNm'] ?? matched['dept_nm'] ?? matched['departmentNm'] ?? matched['departmentName'] ?? matched['name'];
          }
          if (profileData['repManId'] != null && futures[3].statusCode == 200) {
            final parsed = jsonDecode(futures[3].body);
            final List list = parsed is List ? parsed : (parsed['data'] ?? parsed['content'] ?? parsed['items'] ?? []);
            final matched = list.firstWhere((e) {
              final id = e['empId'] ?? e['emp_id'] ?? e['id'];
              return id?.toString() == profileData['repManId']?.toString();
            }, orElse: () => null);
            if (matched != null) {
              final String fst = matched['fstNm'] ?? matched['firstName'] ?? matched['fst_nm'] ?? '';
              final String lst = matched['lstNm'] ?? matched['lastName'] ?? matched['lst_nm'] ?? '';
              final fullName = "$fst $lst".trim();
              if (fullName.isNotEmpty) {
                 profileData['repManNm'] = fullName;
              } else {
                 profileData['repManNm'] = matched['empNm'] ?? matched['employeeName'] ?? matched['name'] ?? profileData['repManId'].toString();
              }
            }
          }
        } catch(e) {
          debugPrint("Error resolving profile references: $e");
        }
        
        return profileData;
      } else {
        throw Exception("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return {};
    }
  }

  static Future<bool> updateProfile(int empId, Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      debugPrint("========== UPDATE PROFILE ==========");
      debugPrint("PUT request to ${dotenv.env['BASE_URL']}/api/employees/$empId");
      debugPrint("Payload: ${jsonEncode(profileData)}");

      final response = await http.put(
        Uri.parse("${dotenv.env['BASE_URL']}/api/employees/$empId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(profileData),
      ).timeout(const Duration(seconds: 6));

      debugPrint("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      throw Exception("Failed to update profile: $e");
    }
  }

  // ==================== UPLOAD EMPLOYEE PHOTO (React flow) ====================
  
  /// Upload employee photo to storage - follows React's upload flow
  /// POST /api/storage/upload/employee-photo
  /// Returns the uploaded URL
  static Future<String> uploadEmployeePhoto(File file) async {
    debugPrint("========== UPLOAD EMPLOYEE PHOTO (React Flow) ==========");
    debugPrint("📤 Uploading file: ${file.path}");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      debugPrint("🔑 Token: ${token != null ? 'YES (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'NO'}");
      
      if (token == null) {
        throw Exception("Authentication token missing.");
      }

      final String url = "${dotenv.env['BASE_URL']}/api/storage/upload/employee-photo";
      debugPrint("🌐 URL: $url");
      debugPrint("🔧 Method: POST");
      
      // Get file extension and MIME type
      final String filePath = file.path;
      final String fileExtension = filePath.split('.').last.toLowerCase();
      String mimeType = 'jpeg';
      if (fileExtension == 'png') {
        mimeType = 'png';
      } else if (fileExtension == 'gif') {
        mimeType = 'gif';
      } else if (fileExtension == 'webp') {
        mimeType = 'webp';
      } else if (fileExtension == 'bmp') {
        mimeType = 'bmp';
      }
      
      debugPrint("📄 File extension: $fileExtension, MIME: image/$mimeType");
      
      // Create multipart request (matches React's FormData)
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = "Bearer $token";
      
      // Add file with field name 'file' (matches React)
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('image', mimeType),
        ),
      );
      
      final uploadedFile = request.files.first;
      debugPrint("📄 File details:");
      debugPrint("  Field: ${uploadedFile.field}");
      debugPrint("  Filename: ${uploadedFile.filename}");
      debugPrint("  Content-Type: ${uploadedFile.contentType}");
      debugPrint("  Size: ${uploadedFile.length} bytes (${(uploadedFile.length / 1024).toStringAsFixed(2)} KB)");
      
      debugPrint("🚀 Sending request...");
      
      // Send request
      var response = await request.send();
      
      debugPrint("📥 Response received!");
      debugPrint("📊 Status Code: ${response.statusCode}");
      
      // Read response body
      final respStr = await response.stream.bytesToString();
      debugPrint("📝 Response Body: $respStr");
      
      debugPrint("========== UPLOAD EMPLOYEE PHOTO END ==========");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(respStr);
          // React typically returns: { url: "https://..." } or { data: { url: "..." } }
          String? uploadedUrl = data['url'] ?? data['data']?['url'] ?? data['photoUrl'] ?? data['fileUrl'];
          
          if (uploadedUrl == null || uploadedUrl.isEmpty) {
            debugPrint("⚠️ Could not extract URL from response: $respStr");
            // If response is just a string URL
            if (respStr.startsWith('http')) {
              uploadedUrl = respStr;
            } else {
              throw Exception("Could not extract URL from server response");
            }
          }
          
          debugPrint("✅ Upload successful! URL: $uploadedUrl");
          return uploadedUrl;
        } catch (e) {
          debugPrint("❌ Failed to parse response JSON: $e");
          // If response is a plain URL string
          if (respStr.startsWith('http')) {
            return respStr;
          }
          throw Exception("Invalid response format: $respStr");
        }
      } else {
        debugPrint("❌ Server returned error: ${response.statusCode}");
        throw Exception("Server Error ${response.statusCode}: $respStr");
      }
    } catch (e) {
      debugPrint("❌ EXCEPTION in uploadEmployeePhoto:");
      debugPrint("  Error: $e");
      debugPrint("  Stack trace: ${StackTrace.current}");
      debugPrint("========== UPLOAD EMPLOYEE PHOTO FAILED ==========");
      rethrow;
    }
  }

  // ==================== UPLOAD PROFILE PHOTO (Legacy - kept for reference) ====================
  
  static Future<String?> uploadProfilePhoto(int empId, String filePath) async {
    debugPrint("========== UPLOAD PROFILE PHOTO (Legacy) ==========");
    debugPrint("⚠️ This is the legacy method. Use uploadEmployeePhoto instead.");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        throw Exception("Authentication token missing.");
      }

      final String url = "${dotenv.env['BASE_URL']}/api/employees/$empId/profile-image";
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = "Bearer $token";
      
      final String fileExtension = filePath.split('.').last.toLowerCase();
      String mimeType = 'jpeg';
      if (fileExtension == 'png') {
        mimeType = 'png';
      } else if (fileExtension == 'gif') {
        mimeType = 'gif';
      } else if (fileExtension == 'webp') {
        mimeType = 'webp';
      } else if (fileExtension == 'bmp') {
        mimeType = 'bmp';
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('image', mimeType),
        ),
      );
      
      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: $respStr");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(respStr);
          return data['profileImage'] ?? data['photoUrl'];
        } catch (e) {
          return respStr;
        }
      } else {
        throw Exception("Server Error ${response.statusCode}: $respStr");
      }
    } catch (e) {
      debugPrint("Error uploading profile photo: $e");
      throw Exception("Upload failed: $e");
    }
  }

  // ==================== CURRENT EMPLOYEE ID ====================
  
  static Future<int?> getCurrentEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedId = prefs.getInt('currentEmpId');
    if (cachedId != null) return cachedId;

    final token = prefs.getString('authToken');
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final empId = data['empId'] as int?;
        if (empId != null) {
          await prefs.setInt('currentEmpId', empId);
          if (data['role'] != null) {
            await prefs.setString('userRole', data['role'].toString());
          }
          return empId;
        }
      }
    } catch (e) {
      debugPrint("Error fetching current employee ID from profile: $e");
    }
    return null;
  }

  static Future<String> getCurrentEmployeeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('cache_userName') ?? 
                         prefs.getString('fullName') ?? 
                         prefs.getString('userName') ?? 
                         prefs.getString('employeeName');
      if (cachedName != null && cachedName.isNotEmpty && cachedName != 'Welcome!' && cachedName != 'Reviewer') {
        return cachedName;
      }

      final token = prefs.getString('authToken');
      if (token != null) {
        final response = await http.get(
          Uri.parse("${dotenv.env['BASE_URL']}/api/profile"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final name = data['fullName']?.toString() ?? data['empNm']?.toString() ?? data['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            await prefs.setString('cache_userName', name);
            await prefs.setString('fullName', name);
            return name;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching employee name: $e");
    }
    return 'Reviewer';
  }

  // ==================== EMPLOYEE MILESTONES ====================
  
  static Future<List<dynamic>> getMilestonesByEmployee(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getMilestonesByEmployee] empId=$empId');

      if (token == null) {
        throw Exception("Token not found");
      }

      final url = "${dotenv.env['BASE_URL']}/api/milestone-live/by-employee/$empId";
      debugPrint('[getMilestonesByEmployee] GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 6));

      debugPrint('[getMilestonesByEmployee] HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception("Failed to load employee milestones: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('[getMilestonesByEmployee] ERROR: $e');
      return [];
    }
  }

  // ==================== EMPLOYEE TASKS ====================
  
  static Future<List<dynamic>> getTasksByEmployee(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getTasksByEmployee] empId=$empId');

      if (token == null) {
        throw Exception("Token not found");
      }

      final url = "${dotenv.env['BASE_URL']}/api/task-live/by-employee/$empId";
      debugPrint('[getTasksByEmployee] GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 6));

      debugPrint('[getTasksByEmployee] HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception("Failed to load employee tasks: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('[getTasksByEmployee] ERROR: $e');
      return [];
    }
  }

  // ==================== PROJECT MILESTONES ====================
  
  static Future<List<dynamic>> getMilestones(int prjId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getMilestones] prjId=$prjId');

      if (token == null) {
        throw Exception("Token not found");
      }

      final url = "${dotenv.env['BASE_URL']}/api/project-live/$prjId/milestones";
      debugPrint('[getMilestones] GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 6));

      debugPrint('[getMilestones] HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('[getMilestones] Parsed ${data.length} milestones');
        return data;
      } else {
        throw Exception("Failed to load milestones: ${response.statusCode} | ${response.body}");
      }
    } catch (e) {
      debugPrint('[getMilestones] ERROR: $e');
      return [];
    }
  }

  /// Fetches ALL milestones (no project filter) for use in deny/rework dialogs.
  static Future<List<dynamic>> getAllMilestones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");

      final url = "${dotenv.env['BASE_URL']}/api/milestone-live";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception("Failed to load milestones: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('[getAllMilestones] ERROR: $e');
      return [];
    }
  }

  // ==================== TASKS FOR MILESTONE ====================
  
  static Future<List<dynamic>> getTasksForMilestone(int mId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getTasksForMilestone] mId=$mId');

      if (token == null) {
        throw Exception("Token not found");
      }

      final url = "${dotenv.env['BASE_URL']}/api/project-live/milestones/$mId/tasks";
      debugPrint('[getTasksForMilestone] GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 6));

      debugPrint('[getTasksForMilestone] HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        debugPrint('[getTasksForMilestone] Parsed ${decoded.length} tasks');
        return decoded;
      } else {
        throw Exception("Failed to load tasks: ${response.statusCode} | ${response.body}");
      }
    } catch (e) {
      debugPrint('[getTasksForMilestone] ERROR: $e');
      return [];
    }
  }

  // ==================== LIVE TASKS ====================
  
  static Future<List<TaskItem>> getLiveTasks({bool forceRefresh = false}) async {
    if (_cachedLiveTasks != null && !forceRefresh) {
      return _cachedLiveTasks!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        throw Exception("Token not found");
      }
      
      final role = prefs.getString('userRole') ?? '';
      final currentEmpId = await getCurrentEmployeeId();
      final bool isEmployee = currentEmpId != null &&
          role.isNotEmpty &&
          role.toLowerCase() != 'admin' &&
          role.toLowerCase() != 'manager';
      bool filterByEmp = isEmployee;

      final projects = await getLiveProjects();
      final List<TaskItem> allTasks = [];

      if (filterByEmp) {
        // Employee-specific tasks
        final List<dynamic> rawTasks = await getTasksByEmployee(currentEmpId);
        final List<dynamic> rawMilestones = await getMilestonesByEmployee(currentEmpId);

        for (final taskJson in rawTasks) {
          final mId = taskJson['mId'] ?? taskJson['mid'];
          final milestone = rawMilestones.firstWhere(
            (m) => (m['mId'] ?? m['mid']) == mId,
            orElse: () => null,
          );
          final prjId = milestone != null ? milestone['prjId'] : taskJson['prjId'];
          
          // Find project, create placeholder if not found
          ProjectModel? project;
          try {
            project = projects.firstWhere((p) => p.prjId == prjId);
          } catch (_) {
            // Project not found - create minimal placeholder
            project = ProjectModel(
              prjId: prjId ?? 0,
              prjCd: '',
              prjNm: 'Unknown Project',
              prjDesc: '',
              prjPrty: 'Medium',
              prjSts: 'LIVE',
              stDt: '',
              endDt: '',
              noOfDays: 0,
              name: 'Unknown Project',
              details: '',
              role: '',
              assigned: 0,
              open: 0,
              progressValue: 0.0,
              progressText: '0%',
              barColor: Colors.blue,
            );
          }
          
          allTasks.add(TaskItem.fromJson(taskJson, project, milestone ?? {}, currentEmpId.toString()));
        }
      } else {
        // Admin/Manager - fetch all tasks
        final milestoneResults = await Future.wait(
          projects.map((project) => getMilestones(project.prjId)),
        );

        final List<Future<List<dynamic>>> taskFutures = [];
        final List<Map<String, dynamic>> contextList = [];

        for (int i = 0; i < projects.length; i++) {
          final project = projects[i];
          final milestones = milestoneResults[i];
          for (final milestone in milestones) {
            final mId = milestone['mId'] ?? milestone['mid'];
            if (mId != null) {
              taskFutures.add(getTasksForMilestone(mId));
              contextList.add({
                'project': project,
                'milestone': milestone,
              });
            }
          }
        }

        final taskResults = await Future.wait(taskFutures);
        for (int i = 0; i < taskResults.length; i++) {
          final context = contextList[i];
          final ProjectModel project = context['project'];
          final milestone = context['milestone'];
          final tasksJson = taskResults[i];

          for (final taskJson in tasksJson) {
            allTasks.add(TaskItem.fromJson(taskJson, project, milestone, currentEmpId?.toString()));
          }
        }
      }

      // Include locally assigned tasks
      if (currentEmpId != null) {
        final localTaskIds = prefs.getStringList('emp_assigned_tasks_$currentEmpId') ?? [];
        for (final taskId in localTaskIds) {
          if (!allTasks.any((t) => t.id == taskId)) {
            final taskDataStr = prefs.getString('task_item_data_$taskId');
            if (taskDataStr != null) {
              try {
                final taskJson = jsonDecode(taskDataStr);
                final localTask = TaskItem.fromLocalJson(taskJson);
                
                // Fetch the latest data from the backend for individual tasks
                // to ensure mutual visibility of actions (checklists, status changes)
                if (localTask.isIndividualTask) {
                  try {
                    final latestRaw = await getIndividualTaskById(int.parse(localTask.id));
                    if (latestRaw != null) {
                      allTasks.add(TaskItem.fromIndividualTask(latestRaw, currentEmpId.toString()));
                      continue;
                    }
                  } catch (_) {}
                }
                
                allTasks.add(localTask);
              } catch (_) {}
            }
          }
        }
      }

      // Local filtering for non-admin roles (mirroring website My Tasks.jsx)
      if (currentEmpId != null && role.isNotEmpty && role.toLowerCase() != 'admin') {
        final currentEmpIdStr = currentEmpId.toString();
        allTasks.retainWhere((task) {
          final raw = task.rawData ?? {};
          final doer = (raw['empId'] ?? raw['empid'] ?? raw['assignedTo'] ?? raw['executorId'])?.toString();
          final reviewer = (raw['reviewerId'] ?? raw['reviewer'] ?? task.reviewer)?.toString();
          final approver = (raw['approverId'] ?? raw['approver'] ?? task.approver)?.toString();
          return doer == currentEmpIdStr || reviewer == currentEmpIdStr || approver == currentEmpIdStr || task.isCurrentUserReviewer || task.isCurrentUserApprover;
        });
      }

      allTasks.removeWhere((task) => task.isDraft);

      _cachedLiveTasks = allTasks;
      return allTasks;
    } catch (e) {
      debugPrint("Error in getLiveTasks: $e");
      return [];
    }
  }

  // ==================== CHECKLIST ====================
  
  static Future<List<Map<String, dynamic>>> getLiveChecklistItems(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/live-task/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .where((item) => item['sts'] != false && item['sts'] != 'false' && item['sts'] != 0)
            .map((item) => {
                  'chkId': item['chkId'] ?? item['chk_id'],
                  'title': item['chkNm'] ?? item['chk_nm'] ?? item['title'] ?? item['chkDesc'] ?? '',
                  'isDone': item['chkSts'] == true || item['chkSts'] == 1 || item['chkSts'] == 'true' || item['chkSts'] == 'Y',
                  'seq': item['seqNo'] ?? item['seq_no'] ?? item['seq'] ?? 0,
                })
            .toList();
      } else {
        throw Exception("Failed to load checklist: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching checklist items: $e");
      return [];
    }
  }

  static Future<void> completeChecklistItem(int chkId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");

      final response = await http.patch(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/$chkId/complete"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception("Failed to complete checklist item: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error completing checklist item: $e");
      rethrow;
    }
  }

  static Future<void> reopenChecklistItem(int chkId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");

      final response = await http.patch(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/$chkId/reopen"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        throw Exception("Failed to reopen checklist item: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error reopening checklist item: $e");
      rethrow;
    }
  }

  static Future<bool> replaceLiveChecklistItems({
    required int taskId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      var response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/live-task/$taskId/bulk"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(items),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        response = await http.put(
          Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/live-task/$taskId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(items),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      debugPrint('replaceLiveChecklistItems failed: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error replacing live checklist items: $e');
      return false;
    }
  }

  static Future<bool> createLiveChecklistItems({
    required int taskId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      var response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/live-task/$taskId/bulk"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(items),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        response = await http.post(
          Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/live-task/$taskId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(items),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      debugPrint('createLiveChecklistItems failed: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error creating live checklist items: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getIndividualChecklistItems(int empTaskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/assignments/$empTaskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map<Map<String, dynamic>>((item) {
          return {
            'chkId': item['chkId'] ?? item['chk_id'],
            'title': item['chkNm'] ?? item['chk_nm'] ?? item['title'] ?? item['chkDesc'] ?? item['chk_desc'] ?? item['name'] ?? item['text'] ?? '',
            'isDone': item['chkSts'] == true || item['chkSts'] == 1 || item['chkSts'] == 'true' || item['chkSts'] == 'Y' || item['isDone'] == true,
            'seq': item['seqNo'] ?? item['seq_no'] ?? item['seq'] ?? 0,
          };
        }).toList();
      }

      debugPrint('getIndividualChecklistItems failed: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error fetching individual checklist items: $e');
      return [];
    }
  }

  static Future<bool> createIndividualChecklistItems({
    required int empTaskId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/assignments/$empTaskId/bulk"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(items),
      );

      debugPrint('createIndividualChecklistItems status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('createIndividualChecklistItems body: ${response.body}');
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating individual checklist items: $e');
      return false;
    }
  }

  static Future<bool> deleteChecklistItem(int chkId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse("${dotenv.env['BASE_URL']}/api/checklists/$chkId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting checklist item $chkId: $e');
      return false;
    }
  }

  // ==================== TASK ACTIONS ====================
  
  static Future<String> startTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId();
      if (empId == null) throw Exception("Employee ID not found");

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId/start"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"empId": empId}),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['taskSts'] ?? 'WIP';
      } else {
        throw Exception(data['message'] ?? "Failed to start task: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error starting task: $e");
      rethrow;
    }
  }

  static Future<String> submitTask(int taskId, String remarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId();
      if (empId == null) throw Exception("Employee ID not found");

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId/submit"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"empId": empId, "remarks": remarks}),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['taskSts'] ?? 'SUBMIT_REVIEW';
      } else {
        throw Exception(data['message'] ?? "Failed to submit task: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error submitting task: $e");
      rethrow;
    }
  }

  static Future<String> resubmitTask(int taskId, String remarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId();
      if (empId == null) throw Exception("Employee ID not found");

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId/resubmit"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"empId": empId, "remarks": remarks}),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['taskSts'] ?? 'SUBMIT_REVIEW';
      } else {
        throw Exception(data['message'] ?? "Failed to resubmit task: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error resubmitting task: $e");
      rethrow;
    }
  }

  static Future<String> checkerAction(
    int taskId,
    String decision,
    String remarks, {
    String rejectionType = 'REASSIGN',
    int? targetMId,
    int? targetEmpId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId();
      if (empId == null) throw Exception("Employee ID not found");

      final Map<String, dynamic> payload = {
        "empId": empId,
        "decision": decision,
        "remarks": remarks,
      };
      if (decision == 'NO') {
        payload['rejectionType'] = rejectionType;
        if (targetMId != null) payload['targetMId'] = targetMId;
        if (targetEmpId != null) payload['targetEmpId'] = targetEmpId;
      }

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId/checker-action"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['taskSts'] ?? 'UNDER_REVIEW';
      } else {
        throw Exception(data['message'] ?? "Failed to perform checker action: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error checker action: $e");
      rethrow;
    }
  }

  static Future<String> reviewerAction(
    int taskId,
    String decision,
    String remarks, {
    String rejectionType = 'REASSIGN',
    int? targetMId,
    int? targetEmpId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId();
      if (empId == null) throw Exception("Employee ID not found");

      final Map<String, dynamic> payload = {
        "rId": empId,
        "empId": empId,
        "decision": decision,
        "remarks": remarks,
      };
      if (decision == 'NO') {
        payload['rejectionType'] = rejectionType;
        if (targetMId != null) payload['targetMId'] = targetMId;
        if (targetEmpId != null) payload['targetEmpId'] = targetEmpId;
      }

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId/reviewer-action"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['taskSts'] ?? 'CLOSED';
      } else {
        throw Exception(data['message'] ?? "Failed to perform reviewer action: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error reviewer action: $e");
      rethrow;
    }
  }

  // ==================== PROCESS HISTORY (Removed) ====================

  // ==================== PROCESS CONFIG ====================
  
  static Future<List<dynamic>> getLiveProcessConfig(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[getLiveProcessConfig] Auth token is missing.");
        return [];
      }

      final url = "${dotenv.env['BASE_URL']}/api/process-config/live-task/$taskId";
      debugPrint("[getLiveProcessConfig] Request URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      debugPrint("[getLiveProcessConfig] Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("[getLiveProcessConfig] Response body: ${response.body}");
        return jsonDecode(response.body);
      } else {
        debugPrint("[getLiveProcessConfig] Request failed with status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("[getLiveProcessConfig] Error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getDraftProcessConfig(int drftTaskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[getDraftProcessConfig] Auth token is missing.");
        return [];
      }

      final url = "${dotenv.env['BASE_URL']}/api/process-config/draft-task/$drftTaskId";
      debugPrint("[getDraftProcessConfig] Request URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      debugPrint("[getDraftProcessConfig] Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("[getDraftProcessConfig] Response body: ${response.body}");
        return jsonDecode(response.body);
      }
      debugPrint("[getDraftProcessConfig] Request failed with status: ${response.statusCode}");
      return [];
    } catch (e) {
      debugPrint("[getDraftProcessConfig] Error: $e");
      return [];
    }
  }

  // ==================== EMPLOYEE NAME ====================
  
  static Future<String?> getEmployeeName(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[getEmployeeName] Auth token is missing.");
        return null;
      }

      final url = "${dotenv.env['BASE_URL']}/api/employees/$empId";
      debugPrint("[getEmployeeName] Request URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      debugPrint("[getEmployeeName] Response status for empId $empId: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("[getEmployeeName] Response body: ${response.body}");
        final data = jsonDecode(response.body);
        final firstName = data['firstName'] ?? data['first_name'] ?? data['fstNm'] ?? data['fst_nm'] ?? '';
        final lastName = data['lastName'] ?? data['last_name'] ?? data['lstNm'] ?? data['lst_nm'] ?? '';
        String resolvedName = "$firstName $lastName".trim();
        
        if (resolvedName.isEmpty) {
          resolvedName = (data['empNm'] ?? data['employeeName'] ?? data['name'] ?? '').toString().trim();
        }
        
        debugPrint("[getEmployeeName] Resolved name: $resolvedName");
        return resolvedName.isNotEmpty ? resolvedName : null;
      }
      debugPrint("[getEmployeeName] Request failed with status: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("[getEmployeeName] Error: $e");
      return null;
    }
  }

  static Future<String?> getReviewerName(int rId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[getReviewerName] Auth token is missing.");
        return null;
      }

      final url = "${dotenv.env['BASE_URL']}/api/reviewers/$rId";
      debugPrint("[getReviewerName] Request URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      debugPrint("[getReviewerName] Response status for reviewerId $rId: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("[getReviewerName] Response body: ${response.body}");
        final data = jsonDecode(response.body);
        final rnm = data['rnm'] ?? data['rNm'] ?? data['roleName'] ?? data['role_name'] ?? '';
        debugPrint("[getReviewerName] Resolved role name: $rnm");
        return rnm;
      }
      debugPrint("[getReviewerName] Request failed with status: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("[getReviewerName] Error: $e");
      return null;
    }
  }

  // ==================== COMPANIES ====================
  
  static Future<List<dynamic>> getCompanies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/companies"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // ==================== PLANTS ====================
  
  static Future<List<dynamic>> getPlants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/plants"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // ==================== HOLIDAYS ====================

  static Future<List<DateTime>> getHolidays({int? coyId, int? pltId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final url = "${dotenv.env['BASE_URL']}/api/calendar";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<DateTime> holidays = [];
        
        for (var item in data) {
          final type = item['calType'] ?? '';
          final cId = item['coyId'];
          final pId = item['pltId'];
          
          bool include = false;
          if (type == 'MANDATORY') {
            include = true;
          } else if (type == 'COMPANY' && cId != null && coyId != null && cId == coyId) {
            include = true;
          } else if (type == 'PLANT' && pId != null && pltId != null && pId == pltId) {
            include = true;
          }
          
          if (include && item['calDt'] != null) {
            final dt = DateTime.tryParse(item['calDt'].toString());
            if (dt != null) {
              holidays.add(dt);
            }
          }
        }
        return holidays;
      }
    } catch (e) {
      debugPrint("Error fetching holidays: $e");
    }
    return [];
  }

  static Future<int> getEffectiveWorkingDaysPerWeek({int? coyId, int? pltId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return 6;

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      if (pltId != null) {
        final res = await http.get(Uri.parse("${dotenv.env['BASE_URL']}/api/plants"), headers: headers);
        if (res.statusCode == 200) {
          final List<dynamic> plants = jsonDecode(res.body);
          final plant = plants.firstWhere((p) => p['pltId'] == pltId || p['id'] == pltId, orElse: () => null);
          if (plant != null && plant['wrkDaysPerWk'] != null) {
            return int.tryParse(plant['wrkDaysPerWk'].toString()) ?? 6;
          }
        }
      }

      if (coyId != null) {
        // Fallback to companies API if plant doesn't have it or pltId is null
        final res = await http.get(Uri.parse("${dotenv.env['BASE_URL']}/api/company"), headers: headers);
        if (res.statusCode == 200) {
          final List<dynamic> companies = jsonDecode(res.body);
          final company = companies.firstWhere((c) => c['coyId'] == coyId || c['id'] == coyId, orElse: () => null);
          if (company != null && company['wrkDaysPerWk'] != null) {
            return int.tryParse(company['wrkDaysPerWk'].toString()) ?? 6;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching working days config: $e");
    }
    return 6;
  }


  // ==================== DEPARTMENTS ====================
  
  static Future<List<dynamic>> getDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/departments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // ==================== NOTIFICATIONS ====================
  
  static Future<List<dynamic>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/notifications"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getUnreadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/notifications/unread"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  static Future<bool> markNotificationAsRead(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse("${dotenv.env['BASE_URL']}/api/notifications/$id/read"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== GANTT DATA ====================
  
  static Future<String> getProjectLeadLagStatus(int projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return '';

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/project-live/$projectId/lead-lag-status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          String? status;
          if (data is Map) {
            final raw = data['status'] ?? data['leadLag'] ?? data['leadLagStatus'] ?? data['lead_lag_status'];
            if (raw != null && raw.toString().trim().toLowerCase() != 'null') {
              status = raw.toString();
            }
          } else if (data != null && data.toString().trim().toLowerCase() != 'null') {
            status = data.toString();
          }
          if (status != null && status.isNotEmpty && status.trim().toLowerCase() != 'null') {
            return status;
          }
        } catch (_) {
          final bodyStr = response.body.trim().replaceAll('"', '');
          if (bodyStr.toLowerCase() != 'null') {
            return bodyStr;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching lead lag status: $e");
    }
    return '';
  }

  static Future<List<dynamic>> getGanttData(int projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/gantt/$projectId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // ==================== CALENDAR FEED ====================
  
  static Future<List<dynamic>> getCalendarFeed({required String viewType, String? date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      String url = "${dotenv.env['BASE_URL']}/api/calendar/user-feed?viewType=$viewType";
      if (date != null && date.isNotEmpty) {
        url += "&date=$date";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // ==================== USER DASHBOARD ====================
  
  static Future<Map<String, dynamic>?> getUserDashboardData({bool forceRefresh = false}) async {
    if (_cachedDashboardData != null && !forceRefresh) {
      return _cachedDashboardData!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        throw Exception("Auth token not found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/user-dashboard"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedDashboardData = data;
        return data;
      } else {
        throw Exception("Server returned status ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error in getUserDashboardData: $e");
      rethrow;
    }
  }

  // ==================== SETTINGS ====================
  
  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/settings"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateSettings(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final body = {
        "language": preferences["language"] ?? preferences["Language"] ?? "English",
        "dateFormat": preferences["dateFormat"] ?? preferences["Date Format"] ?? preferences["date_format"] ?? "DD-MMM-YYYY",
        "timeZone": preferences["timeZone"] ?? preferences["Time Zone"] ?? preferences["time_zone"] ?? "Asia/Kolkata",
        "theme": preferences["theme"] ?? preferences["Theme"] ?? "Light",
      };

      final response = await http.put(
        Uri.parse("${dotenv.env['BASE_URL']}/api/settings"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== CHANGE PASSWORD ====================
  
  static Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/employees/change-password"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        throw Exception(data['message'] ?? "Failed to change password: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error in changePassword: $e");
      rethrow;
    }
  }

  // ==================== FORGOT PASSWORD ====================
  
  static Future<String> sendPasswordResetLink(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/auth/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return data['message'] ?? "Reset link sent successfully.";
        } catch (_) {
          return "Reset link sent successfully.";
        }
      } else {
        debugPrint("sendPasswordResetLink error: ${response.statusCode} - ${response.body}");
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          throw Exception(data['error'] ?? data['message'] ?? "Failed to send reset link (Status: ${response.statusCode}).");
        } catch (_) {
          throw Exception("Failed to send reset link (Status: ${response.statusCode}). Server returned invalid data.");
        }
      }
    } catch (e) {
      debugPrint("Error in sendPasswordResetLink: $e");
      rethrow;
    }
  }

  static Future<String> resetPasswordWithToken(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "newPassword": newPassword,
        }),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return data['message'] ?? "Password updated successfully.";
        } catch (_) {
          return "Password updated successfully.";
        }
      } else {
        debugPrint("resetPasswordWithToken error: ${response.statusCode} - ${response.body}");
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          throw Exception(data['error'] ?? data['message'] ?? "Failed to reset password (Status: ${response.statusCode}).");
        } catch (_) {
          throw Exception("Failed to reset password (Status: ${response.statusCode}). Server returned invalid data.");
        }
      }
    } catch (e) {
      debugPrint("Error in resetPasswordWithToken: $e");
      rethrow;
    }
  }

  // ==================== FETCH EMPLOYEES ====================
  
  static Future<List<Map<String, String>>> fetchEmployees() async {
    final List<Map<String, String>> defaultEmployees = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token == 'offline_mock_token') {
        return defaultEmployees;
      }

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/employees"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Map<String, String>>((item) {
          final String fstNm = item['fstNm'] ?? '';
          final String lstNm = item['lstNm'] ?? '';
          final String name = "$fstNm $lstNm".trim();
          final String role = item['role'] ?? item['designation'] ?? 'Employee';
          final String idStr = (item['empId'] ?? item['id'] ?? '0').toString();
          
          String initials = 'EE';
          if (name.isNotEmpty) {
            final parts = name.split(' ');
            if (parts.length >= 2) {
              initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
            } else if (parts[0].isNotEmpty) {
              initials = parts[0][0].toUpperCase();
            }
          }

          return {
            'name': name,
            'role': role,
            'initials': initials,
            'id': idStr,
          };
        }).toList();
      }
      return defaultEmployees;
    } catch (e) {
      debugPrint("Error fetching employees: $e");
      return defaultEmployees;
    }
  }

  // ==================== INDIVIDUAL TASKS ====================

  static Future<int?> createIndividualTask(Map<String, dynamic> taskData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;

      debugPrint('==== CREATE INDIVIDUAL TASK DEBUG ====');
      debugPrint('Payload: ${jsonEncode(taskData)}');

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(taskData),
      ).timeout(const Duration(seconds: 5));

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('======================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          if (data['id'] != null) {
            return int.tryParse(data['id'].toString());
          }
          if (data['taskId'] != null) {
            return int.tryParse(data['taskId'].toString());
          }
          if (data['empTaskId'] != null) {
            return int.tryParse(data['empTaskId'].toString());
          }
        } catch (_) {}
        // Fallback if no ID is returned but it succeeded
        return -1;
      }
      return null;
    } catch (e) {
      debugPrint('==== CREATE INDIVIDUAL TASK EXCEPTION ====');
      debugPrint('Error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getLiveProcessConfigs(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process-config/individual-task/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> saveLiveProcessConfigs(int taskId, int? reviewerId, int? approverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      // 1. Fetch existing configs
      final existingConfigs = await getLiveProcessConfigs(taskId);
      
      Map<String, dynamic>? checkerConfig;
      Map<String, dynamic>? reviewerConfig;

      for (var config in existingConfigs) {
        if (config['stepType'] == 'CHECKER' || config['stepType'] == 'APPROVER') checkerConfig = config;
        if (config['stepType'] == 'REVIEWER') reviewerConfig = config;
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      // 2. Handle Approver (CHECKER)
      if (approverId != null) {
        final payload = {
          "ordrId": 2,
          "stepType": "CHECKER",
          "empId": approverId,
          "stepLabel": "Approver"
        };
        
        if (checkerConfig != null) {
          // Update
          await http.put(
            Uri.parse("${dotenv.env['BASE_URL']}/api/process-config/${checkerConfig['pcId']}"),
            headers: headers,
            body: jsonEncode(payload),
          );
        } else {
          // Create
          await http.post(
            Uri.parse("${dotenv.env['BASE_URL']}/api/process-config/individual-task/$taskId"),
            headers: headers,
            body: jsonEncode(payload),
          );
        }
      }

      // 3. Handle Reviewer (REVIEWER)
      if (reviewerId != null) {
        final payload = {
          "ordrId": 1,
          "stepType": "REVIEWER",
          "empId": reviewerId,
          "stepLabel": "Reviewer"
        };
        
        if (reviewerConfig != null) {
          // Update
          await http.put(
            Uri.parse("${dotenv.env['BASE_URL']}/api/process-config/${reviewerConfig['pcId']}"),
            headers: headers,
            body: jsonEncode(payload),
          );
        } else {
          // Create
          await http.post(
            Uri.parse("${dotenv.env['BASE_URL']}/api/process-config/individual-task/$taskId"),
            headers: headers,
            body: jsonEncode(payload),
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error saving process configs: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getIndividualTasks({bool forceRefresh = false}) async {
    if (_cachedIndividualTasks != null && !forceRefresh) {
      return _cachedIndividualTasks!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> result = [];
        if (decoded is List) {
          result = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          result = decoded['data'] as List<dynamic>? ?? [];
        }
        _cachedIndividualTasks = result;
        return result;
      } else {
        debugPrint("getIndividualTasks Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("getIndividualTasks Exception: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getIndividualTaskById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> updateIndividualTask(int id, Map<String, dynamic> taskData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      debugPrint('==== UPDATE INDIVIDUAL TASK DEBUG ====');
      debugPrint('Endpoint: ${dotenv.env['BASE_URL']}/api/assignments/$id');
      debugPrint('Payload: ${jsonEncode(taskData)}');

      final response = await http.put(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(taskData),
      ).timeout(const Duration(seconds: 5));

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('======================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        clearCache();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('==== UPDATE INDIVIDUAL TASK EXCEPTION ====');
      debugPrint('Error: $e');
      return false;
    }
  }

  static Future<bool> deleteIndividualTask(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getIndividualTasksAssignedTo(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments/employee/$empId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getIndividualTasksAssignedBy(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments/assigned-by/$empId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> getIndividualTaskProcessConfigsForEmployee(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process-config/employee/$empId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching process configs for employee: $e');
      return [];
    }
  }

  // ==================== ATTACHMENTS ====================

  static Future<List<Map<String, dynamic>>> fetchAttachmentsForTask({required int taskId, int? drftTaskId}) async {
    final List<Map<String, dynamic>> results = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[fetchAttachments] Auth token is missing.");
        return [];
      }

      // 1. Fetch live task attachments
      final liveUrl = "${dotenv.env['BASE_URL']}/api/attachments/live-task/$taskId";
      debugPrint("[fetchAttachments] GET $liveUrl");
      final liveResponse = await http.get(
        Uri.parse(liveUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      debugPrint("[fetchAttachments] Live response status: ${liveResponse.statusCode}");
      if (liveResponse.statusCode == 200) {
        debugPrint("[fetchAttachments] Live response body: ${liveResponse.body}");
        final List<dynamic> list = jsonDecode(liveResponse.body);
        results.addAll(list.map((item) => Map<String, dynamic>.from(item)));
      }

      // 2. Fetch draft task attachments if drftTaskId is available
      if (drftTaskId != null) {
        final draftUrl = "${dotenv.env['BASE_URL']}/api/attachments/draft-task/$drftTaskId";
        debugPrint("[fetchAttachments] GET $draftUrl");
        final draftResponse = await http.get(
          Uri.parse(draftUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 4));

        debugPrint("[fetchAttachments] Draft response status: ${draftResponse.statusCode}");
        if (draftResponse.statusCode == 200) {
          final List<dynamic> list = jsonDecode(draftResponse.body);
          for (final item in list) {
            final mapped = Map<String, dynamic>.from(item);
            if (!results.any((r) => r['fileId'] == mapped['fileId'])) {
              results.add(mapped);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[fetchAttachments] Error: $e");
    }
    debugPrint("[fetchAttachments] Total results: ${results.length}");
    return results;
  }

  /// Upload a file to Supabase storage via the backend's storage endpoint.
  /// Returns the public Supabase URL of the uploaded file.
  static Future<String?> uploadFileToStorage(String filePath) async {
    debugPrint("[uploadFileToStorage] Uploading file: $filePath");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[uploadFileToStorage] Auth token is missing.");
        return null;
      }

      final String url = "${dotenv.env['BASE_URL']}/api/storage/upload/employee-photo";
      debugPrint("[uploadFileToStorage] POST $url");

      // Determine MIME type from extension
      final String ext = filePath.split('.').last.toLowerCase();
      String mimeCategory = 'application';
      String mimeSubtype = 'octet-stream';

      if (['jpg', 'jpeg'].contains(ext)) {
        mimeCategory = 'image';
        mimeSubtype = 'jpeg';
      } else if (ext == 'png') {
        mimeCategory = 'image';
        mimeSubtype = 'png';
      } else if (ext == 'gif') {
        mimeCategory = 'image';
        mimeSubtype = 'gif';
      } else if (ext == 'webp') {
        mimeCategory = 'image';
        mimeSubtype = 'webp';
      } else if (ext == 'pdf') {
        mimeCategory = 'application';
        mimeSubtype = 'pdf';
      } else if (['doc', 'docx'].contains(ext)) {
        mimeCategory = 'application';
        mimeSubtype = 'msword';
      } else if (['xls', 'xlsx'].contains(ext)) {
        mimeCategory = 'application';
        mimeSubtype = 'vnd.ms-excel';
      } else if (ext == 'csv') {
        mimeCategory = 'text';
        mimeSubtype = 'csv';
      } else if (ext == 'txt') {
        mimeCategory = 'text';
        mimeSubtype = 'plain';
      }

      debugPrint("[uploadFileToStorage] MIME: $mimeCategory/$mimeSubtype");

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = "Bearer $token";

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType(mimeCategory, mimeSubtype),
        ),
      );

      final response = await request.send().timeout(const Duration(seconds: 15));
      final respStr = await response.stream.bytesToString();

      debugPrint("[uploadFileToStorage] Response status: ${response.statusCode}");
      debugPrint("[uploadFileToStorage] Response body: $respStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(respStr);
          String? uploadedUrl = data['url'] ?? data['data']?['url'] ?? data['fileUrl'];

          if (uploadedUrl == null || uploadedUrl.isEmpty) {
            if (respStr.startsWith('http')) {
              uploadedUrl = respStr;
            } else {
              debugPrint("[uploadFileToStorage] Could not extract URL from response.");
              return null;
            }
          }

          debugPrint("[uploadFileToStorage] ✅ Upload successful! URL: $uploadedUrl");
          return uploadedUrl;
        } catch (e) {
          if (respStr.startsWith('http')) {
            return respStr;
          }
          debugPrint("[uploadFileToStorage] Failed to parse response: $e");
          return null;
        }
      } else {
        debugPrint("[uploadFileToStorage] ❌ Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("[uploadFileToStorage] Error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadAttachment({
    required int taskId,
    required String fileNm,
    required String atPath,
    required String atType, // 'UPLOAD' or 'ATTACHMENT'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[uploadAttachment] Auth token is missing.");
        return null;
      }

      // Step 1: Upload file bytes to Supabase storage
      String storagePath = atPath;
      if (!atPath.startsWith('http')) {
        debugPrint("[uploadAttachment] Local file detected. Uploading to storage first...");
        final storageUrl = await uploadFileToStorage(atPath);
        if (storageUrl != null && storageUrl.isNotEmpty) {
          storagePath = storageUrl;
          debugPrint("[uploadAttachment] Storage URL obtained: $storagePath");
        } else {
          debugPrint("[uploadAttachment] ⚠️ Storage upload failed. Saving local path as fallback.");
        }
      }

      // Step 2: Create attachment record in DB with the storage URL
      final url = "${dotenv.env['BASE_URL']}/api/attachments/live-task/$taskId";
      debugPrint("[uploadAttachment] POST $url");
      debugPrint("[uploadAttachment] Body: fileNm=$fileNm, atPath=$storagePath, atType=$atType");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fileNm": fileNm,
          "atPath": storagePath,
          "atType": atType,
        }),
      ).timeout(const Duration(seconds: 6));

      debugPrint("[uploadAttachment] Response status: ${response.statusCode}");
      debugPrint("[uploadAttachment] Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("[uploadAttachment] Error: $e");
    }
    return null;
  }

  static Future<bool> deleteAttachment(int fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[deleteAttachment] Auth token is missing.");
        return false;
      }

      final url = "${dotenv.env['BASE_URL']}/api/attachments/$fileId";
      debugPrint("[deleteAttachment] DELETE $url");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      debugPrint("[deleteAttachment] Response status: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("[deleteAttachment] Error: $e");
      return false;
    }
  }

  // ==================== LEGACY / ALIAS METHODS ====================
  
  // Alias for getEmployees - to maintain compatibility
  static Future<List<dynamic>> getEmployees({bool forceRefresh = false}) async {
    if (_cachedEmployees != null && _cachedEmployees!.isNotEmpty && !forceRefresh) {
      return _cachedEmployees!;
    }
    List<dynamic> cachedEmployees = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_employee_list');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final cDecoded = jsonDecode(cachedStr);
        if (cDecoded is List) {
          cachedEmployees = cDecoded;
        } else if (cDecoded is Map) {
          cachedEmployees = cDecoded['data'] ?? cDecoded['content'] ?? cDecoded['items'] ?? cDecoded['employees'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("[getEmployees] Cache read error: $e");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        debugPrint("[getEmployees] Auth token is missing. Returning cached if available.");
        return cachedEmployees;
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
      
      final baseUrl = dotenv.env['BASE_URL'];

      http.Response empResp;
      try {
        empResp = await http.get(
          Uri.parse("$baseUrl/api/employees"),
          headers: headers,
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint("[getEmployees] Network timeout/error on /api/employees: $e");
        return cachedEmployees;
      }

      if (empResp.statusCode == 200) {
        final decoded = jsonDecode(empResp.body);
        List<dynamic> employees = [];
        if (decoded is List) {
          employees = decoded;
        } else if (decoded is Map) {
          employees = decoded['data'] ?? decoded['content'] ?? decoded['items'] ?? decoded['employees'] ?? [];
        }

        if (employees.isNotEmpty) {
          await prefs.setString('cached_employee_list', empResp.body);
        }

        List<dynamic> companies = [];
        List<dynamic> plants = [];

        try {
          final extraResults = await Future.wait([
            http.get(Uri.parse("$baseUrl/api/companies"), headers: headers).timeout(const Duration(seconds: 5)),
            http.get(Uri.parse("$baseUrl/api/plants"), headers: headers).timeout(const Duration(seconds: 5)),
          ]);
          if (extraResults[0].statusCode == 200) {
            final cDec = jsonDecode(extraResults[0].body);
            companies = cDec is List ? cDec : (cDec['data'] ?? cDec['content'] ?? cDec['items'] ?? []);
          }
          if (extraResults[1].statusCode == 200) {
            final pDec = jsonDecode(extraResults[1].body);
            plants = pDec is List ? pDec : (pDec['data'] ?? pDec['content'] ?? pDec['items'] ?? []);
          }
        } catch (e) {
          debugPrint("[getEmployees] Warning: Failed to fetch companies/plants: $e");
        }

        for (var emp in employees) {
          if (emp is Map) {
            if (emp['coyId'] != null && companies.isNotEmpty) {
              final matched = companies.firstWhere(
                (c) => c is Map && (c['coyId'] ?? c['id'])?.toString() == emp['coyId']?.toString(), 
                orElse: () => null
              );
              if (matched != null && matched is Map) {
                emp['coyNm'] = matched['coyNm'] ?? matched['companyNm'] ?? matched['name'];
              }
            }
            if (emp['pltId'] != null && plants.isNotEmpty) {
              final matched = plants.firstWhere(
                (p) => p is Map && (p['pltId'] ?? p['id'])?.toString() == emp['pltId']?.toString(), 
                orElse: () => null
              );
              if (matched != null && matched is Map) {
                emp['pltNm'] = matched['pltNm'] ?? matched['plantNm'] ?? matched['name'];
              }
            }
          }
        }
        
        debugPrint("[getEmployees] Successfully loaded ${employees.length} employees.");
        final finalEmpList = employees.isNotEmpty ? employees : cachedEmployees;
        _cachedEmployees = finalEmpList;
        return finalEmpList;
      } else {
        debugPrint("[getEmployees] Error status code: ${empResp.statusCode} - Body: ${empResp.body}");
        return cachedEmployees;
      }
    } catch (e) {
      debugPrint("[getEmployees] Exception: $e");
      return cachedEmployees;
    }
  }

  // ==================== LIVE TASK RETRIEVAL & UPDATE ====================

  /// Fetches a single project task by its taskId from the project-live endpoint.
  /// The /api/process/task/$taskId endpoint returns a LIST (process steps), not the task itself.
  static Future<Map<String, dynamic>?> getLiveTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/project-live/task/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) return body;
        if (body is List && body.isNotEmpty && body.first is Map) {
          return body.first as Map<String, dynamic>;
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching live task: $e");
      return null;
    }
  }

  static Future<bool> updateLiveTask(int taskId, Map<String, dynamic> taskData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse("${dotenv.env['BASE_URL']}/api/project-live/task/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(taskData),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating live task: $e");
      return false;
    }
  }

  static Future<bool> updateIndividualTaskStatus(int id, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse("${dotenv.env['BASE_URL']}/api/assignments/$id/status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"taskSts": status}),
      );
      
      debugPrint('PATCH /assignments/$id/status Response: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error updating individual task status: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTaskHistory(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching task history: $e');
      return [];
    }
  }

  /// For project tasks: directly update taskSts to WIP (bypasses the process/start API
  /// which only accepts tasks in numeric OPEN status from DB).
  static Future<bool> updateProjectTaskStatus(int taskId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse("${dotenv.env['BASE_URL']}/api/task-live/$taskId/status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"taskSts": newStatus}),
      ).timeout(const Duration(seconds: 15));
      
      debugPrint("[updateProjectTaskStatus] PATCH response: ${response.statusCode} - ${response.body}");
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? body['error'] ?? 'Failed to update status');
      }
      return true;
    } catch (e) {
      debugPrint("Error updating project task status: $e");
      rethrow;
    }
  }

  /// Full update for live project tasks to persist prcsYesActn (REWORK / REASSIGN) and executor in DB
  static Future<bool> updateTaskLiveFull(int taskId, Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse("${dotenv.env['BASE_URL']}/api/task-live/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      debugPrint("[updateTaskLiveFull] PUT response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error updating task-live full: $e");
      return false;
    }
  }

  /// Get team members from DB table `team_members`
  static Future<List<dynamic>> getContributors(int taskId, bool isIndividualTask) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final endpoint = isIndividualTask
          ? "/api/assignments/$taskId/contributors"
          : "/api/task-live/$taskId/contributors";

      final baseUrl = dotenv.env['BASE_URL'];
      final response = await http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching contributors from DB: $e");
      return [];
    }
  }

  /// Save team members to DB table `team_members`
  static Future<bool> saveContributors(int taskId, bool isIndividualTask, List<Map<String, dynamic>> teamMembers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return false;

      final endpoint = isIndividualTask
          ? "/api/assignments/$taskId/contributors"
          : "/api/task-live/$taskId/contributors";

      final payload = teamMembers.map((tm) => {
        "empId": tm["empId"] ?? tm["id"],
        "asgnRmk": tm["asgnRmk"] ?? "Collaborator",
        if (isIndividualTask) "empTaskId": taskId else "taskId": taskId
      }).toList();

      final baseUrl = dotenv.env['BASE_URL'];
      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      debugPrint("[saveContributors] POST response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error saving contributors to DB: $e");
      return false;
    }
  }
}