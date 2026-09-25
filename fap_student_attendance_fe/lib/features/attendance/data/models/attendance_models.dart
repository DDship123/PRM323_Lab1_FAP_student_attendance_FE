/// Model bản ghi điểm danh của sinh viên (Attendance Record)
class AttendanceRecordModel {
  final String recordId;
  final String sessionId;
  final String studentId;
  final String? studentFapCode;
  final String? studentName;
  final String status;
  final String? deviceId;
  final String? checkedAt;
  final double? distanceMeters;

  const AttendanceRecordModel({
    required this.recordId,
    required this.sessionId,
    required this.studentId,
    this.studentFapCode,
    this.studentName,
    required this.status,
    this.deviceId,
    this.checkedAt,
    this.distanceMeters,
  });

  String get id => recordId;
  String? get studentCode => studentFapCode;
  DateTime get checkInTime =>
      DateTime.tryParse(checkedAt ?? '') ?? DateTime.now();

  bool get isPresent => status.toUpperCase() == 'PRESENT';

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      recordId: json['recordId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentFapCode: json['studentFapCode'] as String?,
      studentName: json['studentName'] as String?,
      status: json['status'] as String? ?? 'PRESENT',
      deviceId: json['deviceId'] as String?,
      checkedAt: json['checkedAt'] as String?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'sessionId': sessionId,
      'studentId': studentId,
      'studentFapCode': studentFapCode,
      'studentName': studentName,
      'status': status,
      'deviceId': deviceId,
      'checkedAt': checkedAt,
      'distanceMeters': distanceMeters,
    };
  }
}

/// DTO gửi lên để sinh viên điểm danh qua Dynamic QR (TOTP), mã PIN (sessionCode): POST /api/attendance/check-in
class CheckInRequest {
  final String? sessionId;
  final String? qrToken;
  final String? qrCodeSecret;
  final String? sessionCode;
  final String? bssid;
  final String? deviceId;
  final String? clientIp;
  final double? latitude;
  final double? longitude;

  const CheckInRequest({
    this.sessionId,
    this.qrToken,
    this.qrCodeSecret,
    this.sessionCode,
    this.bssid,
    this.deviceId,
    this.clientIp,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (sessionId != null && sessionId!.trim().isNotEmpty) {
      map['sessionId'] = sessionId!.trim();
    }
    if (qrToken != null && qrToken!.trim().isNotEmpty) {
      map['qrToken'] = qrToken!.trim();
    }
    if (qrCodeSecret != null && qrCodeSecret!.trim().isNotEmpty) {
      map['qrCodeSecret'] = qrCodeSecret!.trim();
    }
    if (sessionCode != null && sessionCode!.trim().isNotEmpty) {
      map['sessionCode'] = sessionCode!.trim();
    }
    if (bssid != null && bssid!.trim().isNotEmpty) {
      final sanitizedBssid = bssid!.trim();
      // Bỏ qua MAC dummy do Android tắt GPS để Backend tự động fallback kiểm tra IP Subnet
      if (sanitizedBssid != '02:00:00:00:00:00' && sanitizedBssid.toLowerCase() != 'unknown') {
        map['bssid'] = sanitizedBssid;
      }
    }
    if (deviceId != null && deviceId!.trim().isNotEmpty) {
      map['deviceId'] = deviceId!.trim();
    }
    // clientIp đã bị loại bỏ theo Hướng dẫn Tích hợp (Backend tự động lấy IP từ socket/proxy)
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    return map;
  }
}

/// Model đại diện cho sinh viên đã đăng ký vào khóa học (Enrollment)
class EnrollmentModel {
  final String enrollmentId;
  final String courseId;
  final String studentId;
  final String? enrolledAt;
  final String? subjectCode;
  final String? className;
  final String? semester;
  final String? studentName;
  final String? fapCode;

  const EnrollmentModel({
    required this.enrollmentId,
    required this.courseId,
    required this.studentId,
    this.enrolledAt,
    this.subjectCode,
    this.className,
    this.semester,
    this.studentName,
    this.fapCode,
  });

  DateTime get enrolledDate =>
      DateTime.tryParse(enrolledAt ?? '') ?? DateTime.now();

  String get courseTitle => '${subjectCode ?? ''} · ${className ?? ''}'.trim();

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      enrollmentId: json['enrollmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      enrolledAt: json['enrolledAt'] as String?,
      subjectCode: json['subjectCode'] as String?,
      className: json['className'] as String?,
      semester: json['semester'] as String?,
      studentName: json['studentName'] as String?,
      fapCode: json['fapCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enrollmentId': enrollmentId,
      'courseId': courseId,
      'studentId': studentId,
      'enrolledAt': enrolledAt,
      'subjectCode': subjectCode,
      'className': className,
      'semester': semester,
      'studentName': studentName,
      'fapCode': fapCode,
    };
  }
}

/// Model bản ghi lịch sử điểm danh của cá nhân sinh viên: GET /api/attendance/my-history
class AttendanceHistoryItemModel {
  final String recordId;
  final String sessionId;
  final String courseId;
  final String subjectCode;
  final String className;
  final int slotNumber;
  final String status;
  final String checkedAt;

  const AttendanceHistoryItemModel({
    required this.recordId,
    required this.sessionId,
    required this.courseId,
    required this.subjectCode,
    required this.className,
    required this.slotNumber,
    required this.status,
    required this.checkedAt,
  });

  bool get isPresent => status.toUpperCase() == 'PRESENT';

  DateTime? get checkedDateTime => DateTime.tryParse(checkedAt);

  factory AttendanceHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItemModel(
      recordId: json['recordId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      className: json['className'] as String? ?? '',
      slotNumber: json['slotNumber'] as int? ?? 1,
      status: json['status'] as String? ?? 'PRESENT',
      checkedAt: json['checkedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'sessionId': sessionId,
      'courseId': courseId,
      'subjectCode': subjectCode,
      'className': className,
      'slotNumber': slotNumber,
      'status': status,
      'checkedAt': checkedAt,
    };
  }
}
