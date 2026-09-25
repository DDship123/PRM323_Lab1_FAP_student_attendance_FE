/// Model đại diện cho một buổi điểm danh (Attendance Session) từ Backend
class AttendanceSessionModel {
  final String sessionId;
  final String courseId;
  final int slotNumber;
  final String? sessionCode;
  final String qrCodeSecret;
  final String? qrCodeBase64;
  final String? roomNetworkIp;
  final String? hostPublicIp;
  final String? roomBssid;
  final String? currentQrToken;
  final int? tokenRemainingSeconds;
  final int? tokenIntervalSeconds;
  final int? qrRefreshSeconds;
  final String expiredAt;
  final String status;
  final String? createdAt;

  const AttendanceSessionModel({
    required this.sessionId,
    required this.courseId,
    required this.slotNumber,
    this.sessionCode,
    required this.qrCodeSecret,
    this.qrCodeBase64,
    this.roomNetworkIp,
    this.hostPublicIp,
    this.roomBssid,
    this.currentQrToken,
    this.tokenRemainingSeconds,
    this.tokenIntervalSeconds,
    this.qrRefreshSeconds,
    required this.expiredAt,
    required this.status,
    this.createdAt,
  });

  String get id => sessionId;
  bool get isOpen => status.toUpperCase() == 'OPEN' || status.toUpperCase() == 'ACTIVE';
  bool get isClosed => status.toUpperCase() == 'CLOSED';

  DateTime? get expiredDateTime {
    try {
      return DateTime.parse(expiredAt);
    } catch (_) {
      return null;
    }
  }

  DateTime get expireAt => expiredDateTime ?? DateTime.now().add(const Duration(minutes: 15));
  int get durationMinutes => 15;

  DateTime get sessionDate {
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt!);
      if (dt != null) return dt;
    }
    if (expiredDateTime != null) {
      return expiredDateTime!;
    }
    return DateTime.now();
  }

  bool get hasExpired {
    final exp = expiredDateTime;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    final sId = json['sessionId'] as String? ?? '';
    final code = json['sessionCode']?.toString() ??
        (sId.length >= 6 ? sId.substring(0, 6).toUpperCase() : '849201');
    final interval = (json['tokenIntervalSeconds'] as num?)?.toInt() ??
        (json['qrRefreshSeconds'] as num?)?.toInt() ??
        20;

    return AttendanceSessionModel(
      sessionId: sId,
      courseId: json['courseId'] as String? ?? '',
      slotNumber: json['slotNumber'] as int? ?? 1,
      sessionCode: code,
      qrCodeSecret: json['qrCodeSecret'] as String? ?? '',
      qrCodeBase64: json['qrCodeBase64'] as String?,
      roomNetworkIp: json['roomNetworkIp'] as String?,
      hostPublicIp: json['hostPublicIp'] as String?,
      roomBssid: json['roomBssid'] as String?,
      currentQrToken: json['currentQrToken'] as String?,
      tokenRemainingSeconds: (json['tokenRemainingSeconds'] as num?)?.toInt(),
      tokenIntervalSeconds: interval,
      qrRefreshSeconds: interval,
      expiredAt: json['expiredAt'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'courseId': courseId,
      'slotNumber': slotNumber,
      'sessionCode': sessionCode,
      'qrCodeSecret': qrCodeSecret,
      'qrCodeBase64': qrCodeBase64,
      'roomNetworkIp': roomNetworkIp,
      'hostPublicIp': hostPublicIp,
      'roomBssid': roomBssid,
      'currentQrToken': currentQrToken,
      'tokenRemainingSeconds': tokenRemainingSeconds,
      'tokenIntervalSeconds': tokenIntervalSeconds,
      'qrRefreshSeconds': qrRefreshSeconds,
      'expiredAt': expiredAt,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

/// DTO gửi lên để tạo buổi điểm danh: POST /api/sessions
class SessionCreateRequest {
  final String courseId;
  final int slotNumber; // 1 - 6
  final String expiredAt; // ISO-8601 (yyyy-MM-ddTHH:mm:ss)
  final int? qrRefreshSeconds; // Tự động làm mới mã QR (mặc định 20s)
  final String? roomNetworkIp;
  final String? roomBssid;
  final DateTime? sessionDate;
  final int? durationMinutes;

  SessionCreateRequest({
    required this.courseId,
    required this.slotNumber,
    String? expiredAt,
    this.qrRefreshSeconds,
    this.roomNetworkIp,
    this.roomBssid,
    this.sessionDate,
    this.durationMinutes,
  }) : expiredAt = expiredAt ??
            (sessionDate != null && durationMinutes != null
                ? sessionDate
                    .add(Duration(minutes: durationMinutes))
                    .toIso8601String()
                : DateTime.now()
                    .add(Duration(minutes: durationMinutes ?? 15))
                    .toIso8601String());

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'courseId': courseId,
      'slotNumber': slotNumber,
      'expiredAt': expiredAt,
    };
    if (qrRefreshSeconds != null) {
      map['qrRefreshSeconds'] = qrRefreshSeconds;
    }
    if (sessionDate != null) {
      final d = sessionDate!;
      map['sessionDate'] =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (durationMinutes != null) {
      map['durationMinutes'] = durationMinutes;
    }
    if (roomNetworkIp != null && roomNetworkIp!.trim().isNotEmpty) {
      map['roomNetworkIp'] = roomNetworkIp!.trim();
    }
    if (roomBssid != null && roomBssid!.trim().isNotEmpty) {
      map['roomBssid'] = roomBssid!.trim();
    }
    return map;
  }
}

/// Model trả về từ API /api/sessions/{sessionId}/current-token hoặc SSE /api/sessions/{sessionId}/qr-stream
class DynamicQrTokenModel {
  final String sessionId;
  final String currentQrToken;
  final int tokenRemainingSeconds;
  final int tokenIntervalSeconds;
  final int? qrRefreshSeconds;
  final String? qrCodeBase64;
  final String status;

  const DynamicQrTokenModel({
    required this.sessionId,
    required this.currentQrToken,
    required this.tokenRemainingSeconds,
    this.tokenIntervalSeconds = 20,
    this.qrRefreshSeconds,
    this.qrCodeBase64,
    this.status = 'ACTIVE',
  });

  int get remainingSeconds => tokenRemainingSeconds;
  String get formattedRemaining => '${tokenRemainingSeconds}s';

  factory DynamicQrTokenModel.fromJson(Map<String, dynamic> json) {
    final interval = (json['tokenIntervalSeconds'] as num?)?.toInt() ??
        (json['qrRefreshSeconds'] as num?)?.toInt() ??
        20;

    return DynamicQrTokenModel(
      sessionId: json['sessionId']?.toString() ?? '',
      currentQrToken: json['currentQrToken']?.toString() ?? '',
      tokenRemainingSeconds: (json['tokenRemainingSeconds'] as num?)?.toInt() ??
          (json['remainingSeconds'] as num?)?.toInt() ??
          20,
      tokenIntervalSeconds: interval,
      qrRefreshSeconds: interval,
      qrCodeBase64: json['qrCodeBase64']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'currentQrToken': currentQrToken,
      'tokenRemainingSeconds': tokenRemainingSeconds,
      'remainingSeconds': tokenRemainingSeconds,
      'tokenIntervalSeconds': tokenIntervalSeconds,
      'qrRefreshSeconds': qrRefreshSeconds ?? tokenIntervalSeconds,
      'qrCodeBase64': qrCodeBase64,
      'status': status,
    };
  }
}
