import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../widgets/header.dart'; 
import '../widgets/footer.dart';
import 'main_screen.dart'; 
import '../services/api_service.dart';
import '../models/employee_option.dart';
import '../widgets/employee_dropdown.dart';

class ManageTeamScreen extends StatefulWidget {
  final TaskItem task;
  const ManageTeamScreen({super.key, required this.task});

  @override
  State<ManageTeamScreen> createState() => _ManageTeamScreenState();
}

class _ManageTeamScreenState extends State<ManageTeamScreen> {
  int _currentIndex = 2; // TO-DO tab
  List<EmployeeOption> _currentTaskTeam = [];
  List<EmployeeOption> _allEmployees = [];
  int _unreadNotificationCount = 0;
  bool _isLoading = false;
  EmployeeOption? _selectedEmployee;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
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

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load current team list from DB with local storage fallback
      List<EmployeeOption> dbTeam = [];
      try {
        if (widget.task.isIndividualTask) throw Exception('Skip API for individual task');
        final dbTask = await ApiService.getLiveTask(int.parse(widget.task.id));
        if (dbTask != null) {
          final String? noteTxt = dbTask['noteTxt'] ?? dbTask['note_txt'];
          if (noteTxt != null && noteTxt.trim().isNotEmpty) {
            final List<String> employeeIds = noteTxt.split(',');
            final dbEmployees = await ApiService.getEmployees();
            for (final empId in employeeIds) {
              final match = dbEmployees.firstWhere((emp) => emp['id']?.toString() == empId.trim() || emp['empId']?.toString() == empId.trim(), orElse: () => null);
              if (match != null) {
                dbTeam.add(EmployeeOption.fromJson(match));
              }
            }
          }
        } else {
          final savedTeamJson = prefs.getString('task_team_${widget.task.id}');
          if (savedTeamJson != null) {
            final List<dynamic> decoded = jsonDecode(savedTeamJson);
            dbTeam = decoded.map((item) => EmployeeOption.fromJson(item)).toList();
          }
        }
      } catch (e) {
        debugPrint("Error loading team from db: $e");
        final savedTeamJson = prefs.getString('task_team_${widget.task.id}');
        if (savedTeamJson != null) {
          final List<dynamic> decoded = jsonDecode(savedTeamJson);
          dbTeam = decoded.map((item) => EmployeeOption.fromJson(item)).toList();
        }
      }

      if (mounted) {
        setState(() {
          _currentTaskTeam = dbTeam;
        });
      }

      // Fetch dynamic employee list from database
      final dbEmployees = await ApiService.getEmployees();
      if (mounted) {
        setState(() {
          _allEmployees = dbEmployees.map((e) => EmployeeOption.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading team data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomHeader(
        title: 'Manage Team',
        automaticallyImplyLeading: false,
        notificationCount: _unreadNotificationCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _loadSavedData();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button row
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1E293B)),
                          label: const Text('Back', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 1. Team Members section
                    const Text(
                      'Team Members',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),

                    if (_currentTaskTeam.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'No team members assigned yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _currentTaskTeam.length,
                        itemBuilder: (context, index) {
                          final member = _currentTaskTeam[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFF1F5F9)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                                backgroundImage: member.profileImageUrl != null
                                    ? NetworkImage(member.profileImageUrl!)
                                    : null,
                                child: member.profileImageUrl == null
                                    ? Text(
                                        member.initials,
                                        style: const TextStyle(color: Colors.deepPurple, fontSize: 11, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              title: Text(
                                member.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              subtitle: Text(
                                member.designation,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        title: const Text(
                                          'Remove Team Member',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        ),
                                        content: const Text(
                                          'Do you want to remove this team member?',
                                          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogContext),
                                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(dialogContext);
                                              
                                              final name = member.name;
                                              setState(() {
                                                _currentTaskTeam.removeAt(index);
                                                if (_selectedEmployee == member) {
                                                  _selectedEmployee = null;
                                                }
                                              });

                                              final prefs = await SharedPreferences.getInstance();
                                              await prefs.setString('task_team_${widget.task.id}', jsonEncode(_currentTaskTeam));

                                              final empId = member.id!;
                                              final List<String> localTasks = prefs.getStringList('emp_assigned_tasks_$empId') ?? [];
                                              localTasks.remove(widget.task.id);
                                              await prefs.setStringList('emp_assigned_tasks_$empId', localTasks);

                                              // 4. Update the database!
                                              try {
                                                if (widget.task.isIndividualTask) {
                                                  final dbTask = await ApiService.getIndividualTaskById(int.parse(widget.task.id));
                                                  if (dbTask != null) {
                                                    dbTask['noteTxt'] = _currentTaskTeam.map((m) => m.id).join(',');
                                                    final success = await ApiService.updateIndividualTask(int.parse(widget.task.id), dbTask);
                                                    if (!success) {
                                                      debugPrint("Failed to remove task team on individual task database.");
                                                    }
                                                  }
                                                } else {
                                                  final dbTask = await ApiService.getLiveTask(int.parse(widget.task.id));
                                                  if (dbTask != null) {
                                                    dbTask['noteTxt'] = _currentTaskTeam.map((m) => m.id).join(',');
                                                    final success = await ApiService.updateLiveTask(int.parse(widget.task.id), dbTask);
                                                    if (!success) {
                                                      debugPrint("Failed to remove task team on database.");
                                                    }
                                                  }
                                                }
                                              } catch (e) {
                                                debugPrint("Error saving team to database on remove: $e");
                                              }

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('👤 Removed $name from team.'),
                                                    backgroundColor: Colors.red,
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // 2. Dropdown section
                    const Text(
                      'Select Member',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),

                    EmployeeDropdown(
                      items: _allEmployees,
                      selectedItem: _selectedEmployee,
                      onChanged: (EmployeeOption? value) {
                        setState(() {
                          _selectedEmployee = value;
                        });
                      },
                      label: '',
                      isRequired: false,
                      excluded: _currentTaskTeam, // Pass the already selected members so they don't show up again
                    ),

                    const SizedBox(height: 32),

                    // 4. Add Team Member button before footer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedEmployee == null
                            ? null
                            : () async {
                                final employee = _selectedEmployee!;
                                setState(() {
                                  _currentTaskTeam.add(employee);
                                  _selectedEmployee = null;
                                  _searchController.clear();
                                  _searchQuery = '';
                                });

                                final prefs = await SharedPreferences.getInstance();
                                
                                // 1. Save team list for this task
                                await prefs.setString('task_team_${widget.task.id}', jsonEncode(_currentTaskTeam));
                                
                                // 2. Add task ID to this employee's list
                                final empId = employee.id!;
                                final List<String> localTasks = prefs.getStringList('emp_assigned_tasks_$empId') ?? [];
                                if (!localTasks.contains(widget.task.id)) {
                                  localTasks.add(widget.task.id);
                                  await prefs.setStringList('emp_assigned_tasks_$empId', localTasks);
                                }
                                
                                // 3. Save the serialized task representation
                                await prefs.setString('task_item_data_${widget.task.id}', jsonEncode(widget.task.toJson()));

                                // 4. Update the database!
                                // 4. Update the database!
                                try {
                                  if (widget.task.isIndividualTask) {
                                    final dbTask = await ApiService.getIndividualTaskById(int.parse(widget.task.id));
                                    if (dbTask != null) {
                                      dbTask['noteTxt'] = _currentTaskTeam.map((m) => m.id).join(',');
                                      final success = await ApiService.updateIndividualTask(int.parse(widget.task.id), dbTask);
                                      if (!success) {
                                        debugPrint("Failed to update individual task team on database.");
                                      }
                                    }
                                  } else {
                                    final dbTask = await ApiService.getLiveTask(int.parse(widget.task.id));
                                    if (dbTask != null) {
                                      dbTask['noteTxt'] = _currentTaskTeam.map((m) => m.id).join(',');
                                      final success = await ApiService.updateLiveTask(int.parse(widget.task.id), dbTask);
                                      if (!success) {
                                        debugPrint("Failed to update task team on database.");
                                      }
                                    }
                                  }
                                } catch (e) {
                                  debugPrint("Error saving team to database: $e");
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('👤 ${employee.name} assigned to this task.'),
                                      backgroundColor: Colors.deepPurple,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 16, color: Colors.white),
                        label: const Text('Add Team Member', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
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
}
