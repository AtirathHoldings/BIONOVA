class EmployeeOption {
  final String? id;
  final String name;
  final String designation;
  final String? companyName;
  final String? plantName;
  final String? profileImageUrl;

  final int? coyId;
  final int? pltId;

  EmployeeOption({
    this.id,
    required this.name,
    required this.designation,
    this.companyName,
    this.plantName,
    this.profileImageUrl,
    this.coyId,
    this.pltId,
  });

  factory EmployeeOption.fromJson(dynamic rawJson) {
    final Map<String, dynamic> emp = rawJson is Map ? Map<String, dynamic>.from(rawJson) : {};
    final String fst = emp['fstNm'] ?? emp['firstName'] ?? emp['fst_nm'] ?? emp['first_name'] ?? '';
    final String lst = emp['lstNm'] ?? emp['lastName'] ?? emp['lst_nm'] ?? emp['last_name'] ?? '';
    final String fullName = "$fst $lst".trim();
    final String name = fullName.isNotEmpty 
        ? fullName 
        : (emp['empNm'] ?? emp['employeeName'] ?? emp['name'] ?? 'Unknown');
    
    final String designation = emp['designation']?.toString() ?? 
                              emp['role']?.toString() ?? 
                              emp['desigNm']?.toString() ?? 
                              emp['desig_nm']?.toString() ?? 
                              'No designation';
                              
    final String empId = emp['empId']?.toString() ?? 
                         emp['emp_id']?.toString() ?? 
                         emp['id']?.toString() ?? '';
    
    final String? companyName = emp['coyNm']?.toString() ?? 
                                emp['companyNm']?.toString() ?? 
                                emp['companyName']?.toString() ?? 
                                emp['coy_nm']?.toString();

    final String? plantName = emp['pltNm']?.toString() ?? 
                              emp['plantNm']?.toString() ?? 
                              emp['plantName']?.toString() ?? 
                              emp['plt_nm']?.toString();
    
    final int? coyId = emp['coyId'] is int 
        ? emp['coyId'] 
        : int.tryParse(emp['coyId']?.toString() ?? emp['coy_id']?.toString() ?? '');

    final int? pltId = emp['pltId'] is int 
        ? emp['pltId'] 
        : int.tryParse(emp['pltId']?.toString() ?? emp['plt_id']?.toString() ?? '');
    
    final String? profileImageUrl = emp['profileImageUrl']?.toString() ?? 
                                    emp['profile_image_url']?.toString() ?? 
                                    emp['photoUrl']?.toString() ?? 
                                    emp['photo_url']?.toString() ?? 
                                    emp['photoPath']?.toString() ?? 
                                    emp['photo_path']?.toString() ?? 
                                    emp['profileImage']?.toString() ?? 
                                    emp['profile_image']?.toString() ?? 
                                    emp['empPhoto']?.toString() ?? 
                                    emp['emp_photo']?.toString() ?? 
                                    emp['avatar']?.toString() ?? 
                                    emp['avatarUrl']?.toString() ?? 
                                    emp['avatar_url']?.toString();

    return EmployeeOption(
      id: empId.isNotEmpty ? empId : null,
      name: name,
      designation: designation,
      companyName: companyName,
      plantName: plantName,
      profileImageUrl: profileImageUrl,
      coyId: coyId,
      pltId: pltId,
    );
  }

  String get initials {
    if (name.isEmpty) return 'EE';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'designation': designation,
      'companyName': companyName,
      'plantName': plantName,
      'profileImageUrl': profileImageUrl,
      'role': designation, // For backwards compatibility if any old code uses role
      'initials': name.isNotEmpty ? (name.split(' ').length > 1 ? '${name.split(' ')[0][0]}${name.split(' ')[1][0]}' : name[0]).toUpperCase() : 'EE',
    };
  }

  @override
  String toString() => name;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeeOption && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
