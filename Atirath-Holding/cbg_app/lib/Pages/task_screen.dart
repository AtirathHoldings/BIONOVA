import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../widgets/header.dart';
import '../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedTab = 'To-Do List';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<TaskItem> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _fetchTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tasks = await ApiService.getLiveTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          if (args == 'Pending') {
            _selectedTab = 'To-Do List';
          } else {
            _selectedTab = args;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications clicked')),
    );
  }

  List<TaskItem> _getFilteredTasks() {
    return _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesTab = true;
      final currentStatus = task.status;
      if (_selectedTab == 'To-Do List') {
        matchesTab = (currentStatus == 'Pending' || currentStatus == 'Open' || currentStatus == 'In Progress' || currentStatus == 'Rework') &&
            task.hasStarted;
      } else if (_selectedTab == 'Upcoming Tasks') {
        matchesTab = (currentStatus == 'Pending' || currentStatus == 'Open' || currentStatus == 'In Progress' || currentStatus == 'Rework') &&
            !task.hasStarted;
      } else if (_selectedTab == 'Completed') {
        matchesTab = currentStatus == 'Completed';
      } else if (_selectedTab == 'All Tasks') {
        matchesTab = true; 
      }

      return matchesSearch && matchesTab;
    }).toList();
  }

  int _getCount(String type) {
    if (type == 'Total') return _tasks.length;
    if (type == 'Completed') {
      return _tasks.where((task) => task.status == 'Completed').length;
    }
    if (type == 'Upcoming') {
      return _tasks.where((task) {
        final currentStatus = task.status;
        return (currentStatus == 'Pending' || currentStatus == 'Open' || currentStatus == 'In Progress' || currentStatus == 'Rework') &&
            !task.hasStarted;
      }).length;
    }
    if (type == 'ToDo') {
      return _tasks.where((task) {
        final currentStatus = task.status;
        return (currentStatus == 'Pending' || currentStatus == 'Open' || currentStatus == 'In Progress' || currentStatus == 'Rework') &&
            task.hasStarted;
      }).length;
    }
    return 0;
  }

  void _showStatusNote(BuildContext context, TaskItem task) {
    String noteMessage = '';
    final currentStatus = task.status;
    if (task.tag == 'Critical' || task.tag == 'Overdue') {
      noteMessage = 'It will go to almost critical';
    } else if (task.tag == 'High') {
      noteMessage = 'This task has high priority and needs immediate action.';
    } else if (task.tag == 'Completed') {
      noteMessage = 'This task is successfully completed.';
    } else {
      noteMessage = 'Task is currently ${currentStatus.toLowerCase()}.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(task.tag == 'Critical' || task.tag == 'Overdue' ? Icons.warning_amber_rounded : task.tag == 'High' ? Icons.info_outline : Icons.check_circle_outline, color: task.tagColor, size: 22),
            const SizedBox(width: 8),
            Text('${task.tag} Note', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(noteMessage, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))),
        ],
      ),
    );
  }

  void _navigateToTaskDetails(TaskItem task) async {
    await Navigator.pushNamed(
      context,
      '/task-details',
      arguments: task,
    );
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    final criticalTasks = filteredTasks.where((t) => t.tag == 'Critical').toList();
    final highTasks = filteredTasks.where((t) => t.tag == 'High').toList();
    final normalTasks = filteredTasks.where((t) => t.tag != 'Critical' && t.tag != 'High').toList();

    final sortedTasks = [...criticalTasks, ...highTasks, ...normalTasks];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: CustomHeader(
        title: 'Tasks',
        onNotificationTap: _handleNotification,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        color: Colors.deepPurple,
        child: _isLoading && _tasks.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
            : _errorMessage != null && _tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load tasks',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchTasks,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search tasks...',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18), 
                                        onPressed: () => setState(() { 
                                          _searchController.clear(); 
                                          _searchQuery = ''; 
                                        })
                                      ) 
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Summary Cards
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SummaryCard(
                                    title: '${_getCount('ToDo')}', 
                                    subtitle: 'To-Do', 
                                    desc: 'Active Tasks', 
                                    icon: Icons.assignment_outlined, 
                                    iconColor: Colors.orange, 
                                    bgColor: const Color(0xFFFEF3C7), 
                                    isSelected: _selectedTab == 'To-Do List', 
                                    onTap: () => setState(() => _selectedTab = 'To-Do List')
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SummaryCard(
                                    title: '${_getCount('Upcoming')}', 
                                    subtitle: 'Upcoming', 
                                    desc: 'Scheduled', 
                                    icon: Icons.calendar_month_outlined, 
                                    iconColor: Colors.blue, 
                                    bgColor: const Color(0xFFE0F2FE), 
                                    isSelected: _selectedTab == 'Upcoming Tasks', 
                                    onTap: () => setState(() => _selectedTab = 'Upcoming Tasks')
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SummaryCard(
                                    title: '${_getCount('Completed')}', 
                                    subtitle: 'Completed', 
                                    desc: 'Done', 
                                    icon: Icons.check_circle_outline, 
                                    iconColor: Colors.green, 
                                    bgColor: const Color(0xFFDCFCE7), 
                                    isSelected: _selectedTab == 'Completed', 
                                    onTap: () => setState(() => _selectedTab = 'Completed')
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SummaryCard(
                                    title: '${_getCount('Total')}', 
                                    subtitle: 'All Tasks', 
                                    desc: 'Total Work', 
                                    icon: Icons.layers_outlined, 
                                    iconColor: Colors.deepPurple, 
                                    bgColor: const Color(0xFFF3E8FF), 
                                    isSelected: _selectedTab == 'All Tasks', 
                                    onTap: () => setState(() => _selectedTab = 'All Tasks')
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Tab Bar
                          WidgetTabBar(
                            selectedTab: _selectedTab, 
                            onTabChanged: (tabName) => setState(() => _selectedTab = tabName)
                          ),
                          const SizedBox(height: 20),
                          
                          // Task List Card Section
                          if (sortedTasks.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 30.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    Text('No tasks found!', style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500))
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sortedTasks.length,
                                separatorBuilder: (context, index) => const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF1F5F9), 
                                  indent: 12,
                                  endIndent: 12,
                                ),
                                itemBuilder: (context, index) {
                                  final task = sortedTasks[index];
                                  return TaskTileRow(
                                    task: task,
                                    status: task.status,
                                    onInfoTap: () => _showStatusNote(context, task),
                                    onTap: () => _navigateToTaskDetails(task),
                                  );
                                },
                              ),
                            ),
                          
                          const SizedBox(height: 80), 
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class WidgetTabBar extends StatelessWidget {
  final String selectedTab; 
  final Function(String) onTabChanged;
  
  const WidgetTabBar({super.key, required this.selectedTab, required this.onTabChanged});
  
  @override
  Widget build(BuildContext context) {
    final tabs = ['To-Do List', 'Upcoming Tasks', 'Completed', 'All Tasks'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, 
      physics: const BouncingScrollPhysics(), 
      child: Row(
        children: tabs.map((tab) { 
          final isActive = selectedTab == tab; 
          return GestureDetector(
            onTap: () => onTabChanged(tab), 
            child: Container(
              margin: const EdgeInsets.only(right: 6), 
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), 
              decoration: BoxDecoration(
                color: isActive ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent, 
                borderRadius: BorderRadius.circular(16)
              ), 
              child: Text(
                tab, 
                style: TextStyle(
                  color: isActive ? Colors.deepPurple : Colors.grey[600], 
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500, 
                  fontSize: 12
                )
              )
            )
          );
        }).toList()
      )
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title; 
  final String subtitle; 
  final String desc; 
  final IconData icon; 
  final Color iconColor; 
  final Color bgColor; 
  final bool isSelected; 
  final VoidCallback onTap;
  
  const SummaryCard({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.desc, 
    required this.icon, 
    required this.iconColor, 
    required this.bgColor, 
    required this.isSelected, 
    required this.onTap
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), 
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey.shade200, 
            width: isSelected ? 1.5 : 1
          ), 
          boxShadow: isSelected ? [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.1), 
              blurRadius: 8, 
              offset: const Offset(0, 4)
            )
          ] : []
        ), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Container(
              padding: const EdgeInsets.all(4), 
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), 
              child: Icon(icon, color: iconColor, size: 14)
            ), 
            const SizedBox(height: 10), 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), 
                const SizedBox(height: 1), 
                Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis), 
                Text(desc, style: TextStyle(fontSize: 8, color: Colors.grey[500], fontWeight: FontWeight.w500))
              ],
            )
          ],
        ),
      ),
    );
  }
}

class TaskTileRow extends StatelessWidget {
  final TaskItem task; 
  final String status;
  final VoidCallback onInfoTap;
  final VoidCallback onTap;
  
  const TaskTileRow({
    super.key, 
    required this.task, 
    required this.status,
    required this.onInfoTap,
    required this.onTap,
  });

  // 🌟 టాస్క్ యొక్క స్టేటస్‌ను బట్టి కలర్స్ సెట్ చేసే హెల్పర్ మెథడ్
  Color _getStatusColor(String status) {
    if (status == 'Completed') return Colors.green;
    if (status == 'In Progress') return Colors.blue.shade700;
    return Colors.orange.shade700; // Open లేదా Pending ఐతే ఆరెంజ్
  }

  int? _getDaysLeft(String dateStr) {
    if (dateStr.toLowerCase() == 'today') {
      return 0;
    }
    try {
      final normalized = dateStr.replaceAll(',', '').toLowerCase().trim();
      final parts = normalized.split(RegExp(r'\s+'));
      if (parts.length == 3) {
        int? day;
        int? month;
        int? year;
        const months = {
          'jan': 1, 'january': 1,
          'feb': 2, 'february': 2,
          'mar': 3, 'march': 3,
          'apr': 4, 'april': 4,
          'may': 5,
          'jun': 6, 'june': 6,
          'jul': 7, 'july': 7,
          'aug': 8, 'august': 8,
          'sep': 9, 'september': 9,
          'oct': 10, 'october': 10,
          'nov': 11, 'november': 11,
          'dec': 12, 'december': 12,
        };
        final firstIsNum = int.tryParse(parts[0]);
        if (firstIsNum != null) {
          day = firstIsNum;
          month = months[parts[1]];
          year = int.tryParse(parts[2]);
        } else {
          month = months[parts[0]];
          day = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }
        if (day != null && month != null && year != null) {
          final targetDate = DateTime(year, month, day);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return targetDate.difference(today).inDays;
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Widget _buildDaysLeftWidget(TaskItem task, String currentStatus) {
    if (currentStatus == 'Completed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Completed',
            style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    final daysLeft = _getDaysLeft(task.date);
    if (daysLeft == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            'Due: ${task.date}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    Color textColor;
    IconData icon;
    String text;
    FontWeight fontWeight = FontWeight.w500;

    if (daysLeft < 0) {
      textColor = Colors.red.shade700;
      icon = Icons.warning_amber_rounded;
      text = '${daysLeft.abs()} days overdue';
      fontWeight = FontWeight.bold;
    } else if (daysLeft == 0) {
      textColor = Colors.orange.shade800;
      icon = Icons.hourglass_empty_rounded;
      text = '0 days left (Today)';
      fontWeight = FontWeight.bold;
    } else if (daysLeft == 1) {
      textColor = Colors.orange.shade700;
      icon = Icons.hourglass_bottom_rounded;
      text = '1 day left';
      fontWeight = FontWeight.bold;
    } else {
      textColor = (currentStatus == 'Pending' || currentStatus == 'Open') ? task.tagColor : Colors.blueGrey.shade600;
      icon = Icons.schedule;
      text = '$daysLeft days left';
      fontWeight = (currentStatus == 'Pending' || currentStatus == 'Open') ? FontWeight.bold : FontWeight.w500;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: textColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10, color: textColor, fontWeight: fontWeight),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), 
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              // 1. ఎడమవైపు టాస్క్ ఐకాన్ (క్లిక్ చేస్తే నోట్ ఓపెన్ అవుతుంది)
              Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onInfoTap,
                  child: Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(
                      color: task.tagColor.withValues(alpha: 0.15), 
                      borderRadius: BorderRadius.circular(10)
                    ), 
                    child: Icon(
                      task.tag == 'Critical' || task.tag == 'Overdue' 
                          ? Icons.warning_amber_rounded 
                          : task.tag == 'High' 
                              ? Icons.info_outline 
                              : Icons.check_circle_outline, 
                      color: task.tagColor, 
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 2. మధ్యలో ఉండే టాస్క్ వివరాలు (Title, Subtitle, Dates Vertical)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13, 
                        color: Color(0xFF1E293B), 
                        height: 1.3,
                        fontFamily: 'Roboto', 
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.subtitle, 
                      style: TextStyle(
                        color: Colors.grey[500], 
                        fontSize: 11, 
                        fontWeight: FontWeight.w400
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    _buildDaysLeftWidget(task, status),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // 3. 🌟 కుడివైపు ఉండే లేఅవుట్ (Vertical Center)
              Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 🌟 బాణం గుర్తుకి పైన టాస్క్ స్టేటస్ (Open / In Progress / Completed) వస్తుంది
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(height: 4), // స్టేటస్ మరియు బాణం గుర్తు మధ్య గ్యాప్
                  
                  // మధ్యలో బాణం గుర్తు (>)
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                  const SizedBox(height: 6), 
                  
                  // కింద ట్యాగ్ బాక్స్
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                    decoration: BoxDecoration(
                      color: task.tagBg, 
                      borderRadius: BorderRadius.circular(6)
                    ), 
                    child: Text(
                      task.tag, 
                      style: TextStyle(
                        color: task.tagColor, 
                        fontSize: 9, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}