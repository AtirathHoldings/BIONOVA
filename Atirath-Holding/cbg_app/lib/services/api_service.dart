import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_model.dart';
import '../models/task_item.dart';

class ApiService {
  static List<ProjectModel> _getMockProjects() {
    return [
      ProjectModel(
        prjId: 1,
        prjCd: 'PRJ-001',
        prjNm: '50 TPD CBG Plant Construction',
        prjDesc: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant',
        prjPrty: 'Atmost Critical',
        prjSts: 'In Progress',
        stDt: '01 May 2025',
        endDt: '31 May 2025',
        noOfDays: 30,
        name: '50 TPD CBG Plant Construction',
        details: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant',
        role: 'Site Engineer',
        assigned: 8,
        open: 3,
        progressValue: 0.65,
        progressText: '65%',
        barColor: const Color(0xFF16A34A),
      ),
      ProjectModel(
        prjId: 2,
        prjCd: 'PRJ-002',
        prjNm: 'Bio Fertilizer Unit',
        prjDesc: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant',
        prjPrty: 'Critical',
        prjSts: 'Open',
        stDt: '10 May 2025',
        endDt: '10 Jun 2025',
        noOfDays: 31,
        name: 'Bio Fertilizer Unit',
        details: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant',
        role: 'QA Engineer',
        assigned: 4,
        open: 2,
        progressValue: 0.40,
        progressText: '40%',
        barColor: const Color(0xFF16A34A),
      ),
      ProjectModel(
        prjId: 3,
        prjCd: 'PRJ-003',
        prjNm: 'CBG Expansion Phase-II',
        prjDesc: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant',
        prjPrty: 'High',
        prjSts: 'Open',
        stDt: '15 May 2025',
        endDt: '15 Jun 2025',
        noOfDays: 31,
        name: 'CBG Expansion Phase-II',
        details: 'Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant',
        role: 'Reviewer',
        assigned: 5,
        open: 1,
        progressValue: 0.25,
        progressText: '25%',
        barColor: const Color(0xFF2563EB),
      ),
    ];
  }

  static Future<List<ProjectModel>> getLiveProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/project-live"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data.map((json) => ProjectModel.fromJson(json)).toList();
        if (list.isEmpty) {
          return _getMockProjects();
        }
        return list;
      } else {
        throw Exception("Failed to load projects : ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching live projects: $e. Returning mock projects.");
      return _getMockProjects();
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // Offline mode – return mock profile
      if (token == null || token == 'offline_mock_token') {
        final email = prefs.getString('userEmail') ?? 'ravi@atirath.com';
        return _getMockProfile(email);
      }

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching profile: $e. Returning mock profile.");
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail') ?? 'ravi@atirath.com';
      return _getMockProfile(email);
    }
  }

  static Map<String, dynamic> _getMockProfile(String email) {
    return {
      'empId': 1,
      'empCode': 'EMP001',
      'fstNm': 'Ravi',
      'lstNm': 'Kumar',
      'gender': 'MALE',
      'dob': '1995-05-10',
      'email': email,
      'mobNum': '+91 98765 43210',
      'bldGrp': 'O+',
      'address': 'Flat 402, Sri Sai Residency, Madhapur, Hyderabad, 500081',
      'doj': '2024-01-15',
      'empTyp': 'FTE',
      'wLoc': 'Hyderabad, India',
      'role': 'Site Engineer',
      'photoUrl': null,
      'sts': true,
    };
  }

  static Future<int?> getCurrentEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedId = prefs.getInt('currentEmpId');
    if (cachedId != null) return cachedId;

    final token = prefs.getString('authToken');
    if (token == null || token == 'offline_mock_token') return 1;

    try {
      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

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

  static Future<List<dynamic>> getMilestonesByEmployee(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getMilestonesByEmployee] empId=$empId, token=${token == null ? 'NULL' : 'JWT'}');

      if (token == null || token == 'offline_mock_token') {
        return _getMockMilestones(1);
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

      debugPrint('[getMilestonesByEmployee] HTTP ${response.statusCode} | body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

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

  static Future<List<dynamic>> getTasksByEmployee(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getTasksByEmployee] empId=$empId, token=${token == null ? 'NULL' : 'JWT'}');

      if (token == null || token == 'offline_mock_token') {
        return _getMockTasksForMilestone(1);
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

      debugPrint('[getTasksByEmployee] HTTP ${response.statusCode} | body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

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

  static Future<List<dynamic>> getMilestones(int prjId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getMilestones] prjId=$prjId, token=${token == null ? 'NULL' : token == 'offline_mock_token' ? 'OFFLINE' : 'JWT(${token.length}chars)'}');

      // Skip HTTP when running in offline mode
      if (token == null || token == 'offline_mock_token') {
        debugPrint('[getMilestones] Offline mode → returning mock milestones');
        return _getMockMilestones(prjId);
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

      debugPrint('[getMilestones] HTTP ${response.statusCode} | body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('[getMilestones] Parsed ${data.length} milestones');
        if (data.isEmpty) {
          debugPrint('[getMilestones] Empty list from DB → returning mock');
          return _getMockMilestones(prjId);
        }
        return data;
      } else {
        throw Exception("Failed to load milestones: ${response.statusCode} | ${response.body}");
      }
    } catch (e) {
      debugPrint('[getMilestones] ERROR: $e');
      return _getMockMilestones(prjId);
    }
  }

  static List<Map<String, dynamic>> _getMockMilestones(int prjId) {
    return [
      {
        'mId': (prjId * 100) + 1,
        'mlstnCd': 'MS-001',
        'mlstnTtl': 'Project Initiation',
        'mlstnDesc': 'Initial planning and administrative setup.',
        'stDt': '2025-05-01',
        'endDt': '2025-05-05',
        'mlstnSts': 'COMPLETED',
      },
      {
        'mId': (prjId * 100) + 2,
        'mlstnCd': 'MS-002',
        'mlstnTtl': 'Civil Construction',
        'mlstnDesc': 'Excavation and foundation leveling.',
        'stDt': '2025-05-06',
        'endDt': '2025-05-20',
        'mlstnSts': 'LIVE',
      },
      {
        'mId': (prjId * 100) + 3,
        'mlstnCd': 'MS-003',
        'mlstnTtl': 'Grouting Work',
        'mlstnDesc': 'Concrete structural grouting stability.',
        'stDt': '2025-05-21',
        'endDt': '2025-05-25',
        'mlstnSts': 'LIVE',
      },
      {
        'mId': (prjId * 100) + 4,
        'mlstnCd': 'MS-004',
        'mlstnTtl': 'Reinforcement Fixing',
        'mlstnDesc': 'Steel reinforcement and grid installation.',
        'stDt': '2025-05-26',
        'endDt': '2025-05-31',
        'mlstnSts': 'LIVE',
      },
    ];
  }

  static Future<List<dynamic>> getTasksForMilestone(int mId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      debugPrint('[getTasksForMilestone] mId=$mId, token=${token == null ? 'NULL' : token == 'offline_mock_token' ? 'OFFLINE' : 'JWT'}');

      // Skip HTTP when running in offline mode
      if (token == null || token == 'offline_mock_token') {
        debugPrint('[getTasksForMilestone] Offline → mock tasks');
        return _getMockTasksForMilestone(mId);
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

      debugPrint('[getTasksForMilestone] HTTP ${response.statusCode} | body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        debugPrint('[getTasksForMilestone] Parsed ${decoded.length} tasks');
        if (decoded.isEmpty) return _getMockTasksForMilestone(mId);
        return decoded;
      } else {
        throw Exception("Failed to load tasks: ${response.statusCode} | ${response.body}");
      }
    } catch (e) {
      debugPrint('[getTasksForMilestone] ERROR: $e');
      return _getMockTasksForMilestone(mId);
    }
  }

  static List<Map<String, dynamic>> _getMockTasksForMilestone(int mId) {
    // Use modulo to generate consistent-looking mock data for any mId
    final seedIndex = mId % 4;
    if (seedIndex == 1) {
      return [
        {
          'taskId': mId * 10 + 1,
          'taskCd': 'TSK-${mId}01',
          'taskNm': 'Upload PCC inspection report',
          'taskDesc': 'Verify thickness parameters and compile report.',
          'taskSts': 'COMPLETED',
          'noOfDays': 4,
          'stDt': '2025-05-01',
          'endDt': '2025-05-04',
        },
        {
          'taskId': mId * 10 + 2,
          'taskCd': 'TSK-${mId}02',
          'taskNm': 'Site clearance documentation',
          'taskDesc': 'Prepare clearance documents for initiation sign-off.',
          'taskSts': 'COMPLETED',
          'noOfDays': 2,
          'stDt': '2025-05-03',
          'endDt': '2025-05-05',
        },
      ];
    } else if (seedIndex == 2) {
      return [
        {
          'taskId': mId * 10 + 1,
          'taskCd': 'TSK-${mId}01',
          'taskNm': 'Update excavation progress',
          'taskDesc': 'Monitor site excavation and leveling alignment.',
          'taskSts': 'WIP',
          'noOfDays': 7,
          'stDt': '2025-05-06',
          'endDt': '2025-05-12',
        },
        {
          'taskId': mId * 10 + 2,
          'taskCd': 'TSK-${mId}02',
          'taskNm': 'Foundation reinforcement check',
          'taskDesc': 'Inspect steel bars and column footings.',
          'taskSts': 'OPEN',
          'noOfDays': 5,
          'stDt': '2025-05-13',
          'endDt': '2025-05-17',
        },
        {
          'taskId': mId * 10 + 3,
          'taskCd': 'TSK-${mId}03',
          'taskNm': 'Concrete pouring schedule',
          'taskDesc': 'Coordinate concrete delivery and pouring sequence.',
          'taskSts': 'OPEN',
          'noOfDays': 3,
          'stDt': '2025-05-18',
          'endDt': '2025-05-20',
        },
      ];
    } else if (seedIndex == 3) {
      return [
        {
          'taskId': mId * 10 + 1,
          'taskCd': 'TSK-${mId}01',
          'taskNm': 'Grouting Work Review',
          'taskDesc': 'Examine final core pressure tests.',
          'taskSts': 'OPEN',
          'noOfDays': 5,
          'stDt': '2025-05-21',
          'endDt': '2025-05-25',
        },
      ];
    } else {
      return [
        {
          'taskId': mId * 10 + 1,
          'taskCd': 'TSK-${mId}01',
          'taskNm': 'Submit daily progress report',
          'taskDesc': 'Record active labor and material consumption.',
          'taskSts': 'OPEN',
          'noOfDays': 3,
          'stDt': '2025-05-26',
          'endDt': '2025-05-28',
        },
        {
          'taskId': mId * 10 + 2,
          'taskCd': 'TSK-${mId}02',
          'taskNm': 'Reinforcement fixing inspection',
          'taskDesc': 'Final quality check on steel frame installation.',
          'taskSts': 'OPEN',
          'noOfDays': 3,
          'stDt': '2025-05-29',
          'endDt': '2025-05-31',
        },
      ];
    }
  }

  static Future<List<TaskItem>> getLiveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('userRole') ?? '';
      final currentEmpId = await getCurrentEmployeeId();
      final filterByEmp = currentEmpId != null &&
          role.isNotEmpty &&
          role.toLowerCase() != 'admin' &&
          role.toLowerCase() != 'manager';

      final projects = await getLiveProjects();
      final List<TaskItem> allTasks = [];

      if (filterByEmp) {
        final List<dynamic> rawTasks = await getTasksByEmployee(currentEmpId);
        final List<dynamic> rawMilestones = await getMilestonesByEmployee(currentEmpId);

        for (final taskJson in rawTasks) {
          final mId = taskJson['mId'] ?? taskJson['mid'];
          final milestone = rawMilestones.firstWhere(
            (m) => (m['mId'] ?? m['mid']) == mId,
            orElse: () => null,
          );
          final prjId = milestone != null ? milestone['prjId'] : taskJson['prjId'];
          final project = projects.firstWhere(
            (p) => p.prjId == prjId,
            orElse: () => ProjectModel(
              prjId: prjId ?? 0,
              prjCd: 'PRJ',
              prjNm: 'Project',
              prjDesc: '',
              prjPrty: 'Medium',
              prjSts: 'LIVE',
              stDt: '',
              endDt: '',
              noOfDays: 0,
              name: 'Project',
              details: '',
              role: '',
              assigned: 0,
              open: 0,
              progressValue: 0.0,
              progressText: '0%',
              barColor: Colors.blue,
            ),
          );
          allTasks.add(TaskItem.fromJson(taskJson, project, milestone ?? {}));
        }
      } else {
        // Fetch milestones for all projects in parallel
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
            allTasks.add(TaskItem.fromJson(taskJson, project, milestone));
          }
        }
      }

      if (allTasks.isEmpty) {
        return globalTasks;
      }
      return allTasks;
    } catch (e) {
      debugPrint("Error in getLiveTasks: $e. Returning global mock tasks.");
      return globalTasks;
    }
  }

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
            .where((item) => item['sts'] == true)
            .map((item) => {
                  'chkId': item['chkId'],
                  'title': item['chkNm'] ?? '',
                  'isDone': item['chkSts'] ?? false,
                })
            .toList();
      } else {
        throw Exception("Failed to load checklist: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching checklist items: $e. Returning mock checklist.");
      return [
        {
          'chkId': 1,
          'title': 'Verify ground leveling coordinates',
          'isDone': true,
        },
        {
          'chkId': 2,
          'title': 'Inspect excavation safety barriers',
          'isDone': false,
        },
        {
          'chkId': 3,
          'title': 'Check heavy equipment fuel levels',
          'isDone': false,
        },
      ];
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
      print("Error completing checklist item offline: $e");
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
      print("Error reopening checklist item offline: $e");
    }
  }

  static Future<String> startTask(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId() ?? 1;

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
      print("Error starting task offline: $e");
      return 'WIP';
    }
  }

  static Future<String> submitTask(int taskId, String remarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId() ?? 1;

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
      print("Error submitting task offline: $e");
      return 'SUBMIT_REVIEW';
    }
  }

  static Future<String> resubmitTask(int taskId, String remarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId() ?? 1;

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
      print("Error resubmitting task offline: $e");
      return 'SUBMIT_REVIEW';
    }
  }

  static Future<String> checkerAction(int taskId, String decision, String remarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId() ?? 1;

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId/checker-action"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"empId": empId, "decision": decision, "remarks": remarks}),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['taskSts'] ?? 'UNDER_REVIEW';
      } else {
        throw Exception(data['message'] ?? "Failed to perform checker action: ${response.statusCode}");
      }
    } catch (e) {
      print("Error checker action offline: $e");
      return decision == 'APPROVE' ? 'UNDER_REVIEW' : 'REWORK';
    }
  }

  static Future<String> reviewerAction(int taskId, String decision, String remarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");
      final empId = await getCurrentEmployeeId() ?? 1;

      final response = await http.post(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId/reviewer-action"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"rId": empId, "decision": decision, "remarks": remarks}),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['taskSts'] ?? 'COMPLETED';
      } else {
        throw Exception(data['message'] ?? "Failed to perform reviewer action: ${response.statusCode}");
      }
    } catch (e) {
      print("Error reviewer action offline: $e");
      return decision == 'APPROVE' ? 'COMPLETED' : 'REWORK';
    }
  }

  static Future<List<dynamic>> getProcessHistory(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("Token not found");

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process/task/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load process history: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching process history offline: $e");
      return [
        {
          'prcsSts': 'WIP',
          'remarks': 'Started excavation work on site B.',
          'actorRole': 'Site Engineer',
          'creDt': '2026-06-26T10:00:00Z',
        },
        {
          'prcsSts': 'SUBMIT_REVIEW',
          'remarks': 'PCC and leveling inspection completed.',
          'actorRole': 'Site Engineer',
          'creDt': '2026-06-26T11:00:00Z',
        },
      ];
    }
  }

  static Future<List<dynamic>> getLiveProcessConfig(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/process-config/live-task/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<String?> getEmployeeName(int empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/employees/$empId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final firstName = data['firstName'] ?? data['fstNm'] ?? '';
        final lastName = data['lastName'] ?? data['lstNm'] ?? '';
        return "$firstName $lastName".trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getReviewerName(int rId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/reviewers/$rId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rnm'] ?? data['rNm'] ?? '';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

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
      }
      return [];
    } catch (_) {
      return [];
    }
  }

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
      }
      return [];
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
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
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
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

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
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${dotenv.env['BASE_URL']}/api/user-dashboard"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}