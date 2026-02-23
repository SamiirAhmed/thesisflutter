class ClassIssueType {
  final int catNo;
  final String catName;

  ClassIssueType({required this.catNo, required this.catName});

  factory ClassIssueType.fromJson(Map<String, dynamic> json) {
    return ClassIssueType(catNo: json['cat_no'], catName: json['cat_name']);
  }
}

class ClassroomIssue {
  final int id;
  final String issueName;
  final String description;
  final String status;
  final String className;
  final String submittedAt;

  ClassroomIssue({
    required this.id,
    required this.issueName,
    required this.description,
    required this.status,
    required this.className,
    required this.submittedAt,
  });

  factory ClassroomIssue.fromJson(Map<String, dynamic> json) {
    return ClassroomIssue(
      id: int.tryParse(json['id'].toString()) ?? 0,
      issueName: json['issue_name']?.toString() ?? 'Unknown Issue',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      className: json['class_name']?.toString() ?? 'Unknown Class',
      submittedAt: json['submitted_at']?.toString() ?? '',
    );
  }
}

class IssueTracking {
  final int id;
  final String newStatus;
  final String? note;
  final String changedDate;

  IssueTracking({
    required this.id,
    required this.newStatus,
    this.note,
    required this.changedDate,
  });

  factory IssueTracking.fromJson(Map<String, dynamic> json) {
    return IssueTracking(
      id: int.tryParse(json['cit_no'].toString()) ?? 0,
      newStatus: json['new_status']?.toString() ?? 'Unknown',
      note: json['note']?.toString(),
      changedDate: json['changed_date']?.toString() ?? '',
    );
  }
}
