class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    this.userId = '',
    this.userName = '',
    this.email = '',
    this.companyId = '',
    this.companyName = '',
    this.departmentName = '',
    this.roles = const [],
    this.permissions = const [],
    this.mustChangePassword = false,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final user = _object(json['user']) ?? _object(data?['user']);
    final source = user ?? data ?? json;
    return LoginResponseDto(
      accessToken:
          _string(json, const ['access_token', 'accessToken', 'token']) ??
          _string(data ?? const {}, const [
            'access_token',
            'accessToken',
            'token',
          ])!,
      userId: _string(source, const ['user_id', 'userId', 'id']) ?? '',
      userName:
          _string(source, const [
            'user_name',
            'userName',
            'name',
            'full_name',
          ]) ??
          '',
      email: _string(source, const ['email']) ?? '',
      companyId:
          _string(source, const ['company_id', 'companyId', 'company']) ?? '',
      companyName: _string(source, const ['company_name', 'companyName']) ?? '',
      departmentName:
          _string(source, const ['department_name', 'departmentName']) ?? '',
      roles: _stringList(source['roles']) ?? _stringList(json['roles']) ?? [],
      permissions:
          _stringList(source['permissions']) ??
          _stringList(json['permissions']) ??
          [],
      mustChangePassword:
          _bool(source, const ['must_change_password', 'mustChangePassword']) ??
          _bool(json, const ['must_change_password', 'mustChangePassword']) ??
          false,
    );
  }

  final String accessToken;
  final String userId;
  final String userName;
  final String email;
  final String companyId;
  final String companyName;
  final String departmentName;
  final List<String> roles;
  final List<String> permissions;
  final bool mustChangePassword;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'user_id': userId,
    'user_name': userName,
    'email': email,
    'company_id': companyId,
    'company_name': companyName,
    'department_name': departmentName,
    'roles': roles,
    'permissions': permissions,
    'must_change_password': mustChangePassword,
  };
}

class AuthUserDto {
  const AuthUserDto({
    this.userId = '',
    this.userName = '',
    this.email = '',
    this.companyId = '',
    this.companyName = '',
    this.departmentName = '',
    this.roles = const [],
    this.permissions = const [],
    this.mustChangePassword = false,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final user = _object(json['user']) ?? _object(data?['user']);
    final source = user ?? data ?? json;
    return AuthUserDto(
      userId: _string(source, const ['user_id', 'userId', 'id']) ?? '',
      userName:
          _string(source, const [
            'user_name',
            'userName',
            'name',
            'full_name',
          ]) ??
          '',
      email: _string(source, const ['email']) ?? '',
      companyId:
          _string(source, const ['company_id', 'companyId', 'company']) ?? '',
      companyName: _string(source, const ['company_name', 'companyName']) ?? '',
      departmentName:
          _string(source, const ['department_name', 'departmentName']) ?? '',
      roles: _stringList(source['roles']) ?? _stringList(json['roles']) ?? [],
      permissions:
          _stringList(source['permissions']) ??
          _stringList(json['permissions']) ??
          [],
      mustChangePassword:
          _bool(source, const ['must_change_password', 'mustChangePassword']) ??
          _bool(json, const ['must_change_password', 'mustChangePassword']) ??
          false,
    );
  }

  final String userId;
  final String userName;
  final String email;
  final String companyId;
  final String companyName;
  final String departmentName;
  final List<String> roles;
  final List<String> permissions;
  final bool mustChangePassword;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'email': email,
    'company_id': companyId,
    'company_name': companyName,
    'department_name': departmentName,
    'roles': roles,
    'permissions': permissions,
    'must_change_password': mustChangePassword,
  };
}

class DashboardSummaryDto {
  const DashboardSummaryDto({required this.cards, required this.activities});

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final cards = _dashboardCards(data);
    final activitiesJson =
        _objectList(data['recent_activity']) ??
        _objectList(data['recentActivity']) ??
        _objectList(data['activities']) ??
        const [];

    return DashboardSummaryDto(
      cards: cards,
      activities: activitiesJson.map(DashboardActivityDto.fromJson).toList(),
    );
  }

  final List<DashboardSummaryCardDto> cards;
  final List<DashboardActivityDto> activities;

  Map<String, dynamic> toJson() => {
    'cards': cards.map((card) => card.toJson()).toList(),
    'recent_activity': activities.map((activity) => activity.toJson()).toList(),
  };
}

class DashboardSummaryCardDto {
  const DashboardSummaryCardDto({
    required this.key,
    required this.label,
    required this.value,
    this.permission,
  });

  factory DashboardSummaryCardDto.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryCardDto(
      key: _string(json, const ['key', 'name', 'code']) ?? '',
      label: _string(json, const ['label', 'title', 'name']) ?? '',
      value: _displayValue(json['value'] ?? json['count'] ?? json['amount']),
      permission: _string(json, const ['permission', 'required_permission']),
    );
  }

  final String key;
  final String label;
  final String value;
  final String? permission;

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'value': value,
    'permission': permission,
  };
}

class DashboardActivityDto {
  const DashboardActivityDto({
    required this.title,
    required this.message,
    required this.createdAt,
    this.route,
  });

  factory DashboardActivityDto.fromJson(Map<String, dynamic> json) {
    final createdAtRaw =
        _string(json, const ['created_at', 'createdAt', 'time']) ?? '';
    return DashboardActivityDto(
      title: _string(json, const ['title', 'name']) ?? '',
      message:
          _string(json, const ['message', 'body', 'description', 'subtitle']) ??
          '',
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      route: _string(json, const ['route', 'url', 'path']),
    );
  }

  final String title;
  final String message;
  final DateTime createdAt;
  final String? route;

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'route': route,
  };
}

class NotificationUnreadCountDto {
  const NotificationUnreadCountDto({required this.count});

  factory NotificationUnreadCountDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final count = data['count'] ?? data['unread_count'] ?? data['unreadCount'];
    return NotificationUnreadCountDto(count: _intValue(count));
  }

  final int count;

  Map<String, dynamic> toJson() => {'count': count};
}

class NotificationPageDto {
  const NotificationPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory NotificationPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final itemsJson =
        _objectList(data['notifications']) ??
        _objectList(data['items']) ??
        _objectList(data['data']) ??
        _objectList(json['notifications']) ??
        _objectList(json['data']) ??
        const [];
    final meta = _object(data['meta']) ?? _object(json['meta']) ?? data;

    return NotificationPageDto(
      items: itemsJson.map(NotificationDto.fromJson).toList(),
      page: _intValue(meta['page'], fallback: 1),
      limit: _intValue(meta['limit'], fallback: itemsJson.length),
      total: _intValue(meta['total'], fallback: itemsJson.length),
    );
  }

  final List<NotificationDto> items;
  final int page;
  final int limit;
  final int total;

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'page': page,
    'limit': limit,
    'total': total,
  };
}

class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.route,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final createdAtRaw =
        _string(json, const ['created_at', 'createdAt', 'time']) ?? '';
    final readAt = _string(json, const ['read_at', 'readAt']);
    return NotificationDto(
      id:
          _string(json, const ['id', 'notification_id', 'notificationId']) ??
          '',
      title: _string(json, const ['title', 'name']) ?? '',
      message: _string(json, const ['message', 'body', 'description']) ?? '',
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      isRead:
          _bool(json, const ['is_read', 'isRead', 'read']) ?? readAt != null,
      route: _string(json, const ['route', 'url', 'path']),
    );
  }

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? route;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'route': route,
  };
}

class PermissionsResponseDto {
  const PermissionsResponseDto({required this.permissions});

  factory PermissionsResponseDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    return PermissionsResponseDto(
      permissions:
          _stringList(json['permissions']) ??
          _stringList(data?['permissions']) ??
          _stringList(json['data']) ??
          [],
    );
  }

  final List<String> permissions;

  Map<String, dynamic> toJson() => {'permissions': permissions};
}

class ChangePasswordRequestDto {
  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
    'new_password_confirmation': newPasswordConfirmation,
  };
}

class PurchaseRequestPayloadDto {
  const PurchaseRequestPayloadDto({
    required this.title,
    required this.description,
    required this.priority,
    required this.neededDate,
    required this.items,
  });

  final String title;
  final String? description;
  final String priority;
  final DateTime? neededDate;
  final List<PurchaseRequestItemPayloadDto> items;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'priority': priority,
    'needed_date': neededDate?.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class PurchaseRequestItemPayloadDto {
  const PurchaseRequestItemPayloadDto({
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.estimatedUnitPrice,
  });

  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double estimatedUnitPrice;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'estimated_unit_price': estimatedUnitPrice,
  };
}

class PurchaseRequestPageDto {
  const PurchaseRequestPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PurchaseRequestPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final itemsJson =
        _objectList(data['items']) ??
        _objectList(data['requests']) ??
        _objectList(data['purchase_requests']) ??
        _objectList(data['data']) ??
        _objectList(json['data']) ??
        const [];
    final meta = _object(data['meta']) ?? _object(json['meta']) ?? data;

    return PurchaseRequestPageDto(
      items: itemsJson.map(PurchaseRequestDto.fromJson).toList(),
      page: _intValue(meta['page'], fallback: 1),
      limit: _intValue(meta['limit'], fallback: itemsJson.length),
      total: _intValue(meta['total'], fallback: itemsJson.length),
    );
  }

  final List<PurchaseRequestDto> items;
  final int page;
  final int limit;
  final int total;
}

class PurchaseRequestDto {
  const PurchaseRequestDto({
    required this.id,
    required this.requestNumber,
    required this.title,
    required this.description,
    required this.requesterId,
    required this.requesterName,
    required this.departmentName,
    required this.priority,
    required this.neededDate,
    required this.status,
    required this.estimatedTotal,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.budgetCheck,
    this.approvalStatus,
  });

  factory PurchaseRequestDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['purchase_request_items']) ??
        const [];
    final neededDateRaw = _string(source, const ['needed_date', 'neededDate']);
    final createdAtRaw =
        _string(source, const ['created_at', 'createdAt']) ?? '';
    final updatedAtRaw =
        _string(source, const ['updated_at', 'updatedAt']) ?? createdAtRaw;

    return PurchaseRequestDto(
      id:
          _string(source, const ['id', 'server_id', 'serverId', 'local_id']) ??
          '',
      requestNumber:
          _string(source, const [
            'request_number',
            'requestNumber',
            'number',
          ]) ??
          '',
      title: _string(source, const ['title']) ?? '',
      description: _string(source, const ['description']),
      requesterId: _string(source, const ['requester_id', 'requesterId']) ?? '',
      requesterName:
          _string(source, const ['requester_name', 'requesterName']) ?? '',
      departmentName:
          _string(source, const ['department_name', 'departmentName']) ?? '',
      priority: _normalizePriority(
        _string(source, const ['priority']) ?? 'NORMAL',
      ),
      neededDate: neededDateRaw == null
          ? null
          : DateTime.tryParse(neededDateRaw),
      status: _normalizeStatus(_string(source, const ['status']) ?? 'DRAFT'),
      estimatedTotal: _doubleValue(
        source['estimated_total'] ??
            source['estimatedTotal'] ??
            source['total_amount'] ??
            source['totalAmount'],
      ),
      items: itemsJson.map(PurchaseRequestItemDto.fromJson).toList(),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
      rejectionReason: _string(source, const [
        'rejection_reason',
        'rejectionReason',
      ]),
      budgetCheck: _object(source['budget_check']) == null
          ? null
          : BudgetCheckDto.fromJson(_object(source['budget_check'])!),
      approvalStatus: _string(source, const [
        'approval_status',
        'approvalStatus',
      ]),
    );
  }

  final String id;
  final String requestNumber;
  final String title;
  final String? description;
  final String requesterId;
  final String requesterName;
  final String departmentName;
  final String priority;
  final DateTime? neededDate;
  final String status;
  final double estimatedTotal;
  final List<PurchaseRequestItemDto> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionReason;
  final BudgetCheckDto? budgetCheck;
  final String? approvalStatus;
}

class PurchaseRequestItemDto {
  const PurchaseRequestItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.estimatedUnitPrice,
    required this.totalPrice,
  });

  factory PurchaseRequestItemDto.fromJson(Map<String, dynamic> json) {
    final quantity = _doubleValue(json['quantity']);
    final unitPrice = _doubleValue(
      json['estimated_unit_price'] ??
          json['estimatedUnitPrice'] ??
          json['unit_price'] ??
          json['unitPrice'],
    );
    return PurchaseRequestItemDto(
      id:
          _string(json, const ['id', 'server_id', 'serverId', 'local_id']) ??
          '',
      name: _string(json, const ['name', 'item_name', 'itemName']) ?? '',
      description: _string(json, const ['description']),
      quantity: quantity,
      unit: _string(json, const ['unit']) ?? 'pcs',
      estimatedUnitPrice: unitPrice,
      totalPrice: _doubleValue(
        json['total_price'] ??
            json['totalPrice'] ??
            json['line_total'] ??
            json['lineTotal'],
        fallback: quantity * unitPrice,
      ),
    );
  }

  final String id;
  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double estimatedUnitPrice;
  final double totalPrice;
}

class BudgetCheckDto {
  const BudgetCheckDto({
    required this.status,
    required this.message,
    required this.availableAmount,
  });

  factory BudgetCheckDto.fromJson(Map<String, dynamic> json) {
    return BudgetCheckDto(
      status: _string(json, const ['status']) ?? '',
      message: _string(json, const ['message']) ?? '',
      availableAmount: _doubleValue(
        json['available_amount'] ?? json['availableAmount'],
      ),
    );
  }

  final String status;
  final String message;
  final double availableAmount;
}

class ApprovalHistoryEntryDto {
  const ApprovalHistoryEntryDto({
    required this.id,
    required this.approverName,
    required this.action,
    required this.status,
    required this.comment,
    required this.createdAt,
  });

  factory ApprovalHistoryEntryDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final createdAtRaw =
        _string(source, const ['created_at', 'createdAt']) ?? '';
    return ApprovalHistoryEntryDto(
      id: _string(source, const ['id']) ?? '',
      approverName:
          _string(source, const ['approver_name', 'approverName', 'actor']) ??
          '',
      action: _string(source, const ['action']) ?? '',
      status: _normalizeStatus(_string(source, const ['status']) ?? ''),
      comment: _string(source, const ['comment', 'message']),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
    );
  }

  static List<ApprovalHistoryEntryDto> listFromJson(Object? json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(ApprovalHistoryEntryDto.fromJson)
          .toList();
    }
    if (json is! Map<String, dynamic>) {
      return const [];
    }
    final data = _object(json['data']);
    final items =
        _objectList(data?['items']) ??
        _objectList(data?['history']) ??
        _objectList(json['items']) ??
        _objectList(json['history']) ??
        _objectList(json['data']) ??
        const [];
    return items.map(ApprovalHistoryEntryDto.fromJson).toList();
  }

  final String id;
  final String approverName;
  final String action;
  final String status;
  final String? comment;
  final DateTime createdAt;
}

class ApprovalHistoryResponseDto {
  const ApprovalHistoryResponseDto({required this.items});

  factory ApprovalHistoryResponseDto.fromJson(Object? json) {
    return ApprovalHistoryResponseDto(
      items: ApprovalHistoryEntryDto.listFromJson(json),
    );
  }

  final List<ApprovalHistoryEntryDto> items;
}

class ApprovalInboxPageDto {
  const ApprovalInboxPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory ApprovalInboxPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final itemsJson =
        _objectList(data['items']) ??
        _objectList(data['approvals']) ??
        _objectList(data['requests']) ??
        _objectList(data['data']) ??
        _objectList(json['items']) ??
        _objectList(json['approvals']) ??
        _objectList(json['requests']) ??
        _objectList(json['data']) ??
        const [];
    final meta = _object(data['meta']) ?? _object(json['meta']) ?? data;

    return ApprovalInboxPageDto(
      items: itemsJson.map(ApprovalInboxItemDto.fromJson).toList(),
      page: _intValue(meta['page'], fallback: 1),
      limit: _intValue(meta['limit'], fallback: itemsJson.length),
      total: _intValue(meta['total'], fallback: itemsJson.length),
    );
  }

  final List<ApprovalInboxItemDto> items;
  final int page;
  final int limit;
  final int total;
}

class ApprovalInboxItemDto {
  const ApprovalInboxItemDto({
    required this.requestId,
    required this.requestNumber,
    required this.title,
    required this.requesterName,
    required this.departmentId,
    required this.departmentName,
    required this.priority,
    required this.neededDate,
    required this.estimatedTotal,
    required this.currentApprovalStep,
    required this.createdAt,
  });

  factory ApprovalInboxItemDto.fromJson(Map<String, dynamic> json) {
    final request =
        _object(json['request']) ??
        _object(json['purchase_request']) ??
        _object(json['purchaseRequest']);
    final source = request ?? json;
    final neededDateRaw = _string(source, const ['needed_date', 'neededDate']);
    final createdAtRaw =
        _string(source, const ['created_at', 'createdAt']) ??
        _string(json, const ['created_at', 'createdAt']) ??
        '';

    return ApprovalInboxItemDto(
      requestId:
          _string(source, const [
            'id',
            'request_id',
            'requestId',
            'purchase_request_id',
            'purchaseRequestId',
          ]) ??
          _string(json, const [
            'request_id',
            'requestId',
            'purchase_request_id',
            'purchaseRequestId',
          ]) ??
          '',
      requestNumber:
          _string(source, const [
            'request_number',
            'requestNumber',
            'number',
          ]) ??
          '',
      title: _string(source, const ['title']) ?? '',
      requesterName:
          _string(source, const [
            'requester_name',
            'requesterName',
            'requester',
          ]) ??
          _string(json, const [
            'requester_name',
            'requesterName',
            'requester',
          ]) ??
          '',
      departmentId:
          _string(source, const ['department_id', 'departmentId']) ??
          _string(json, const ['department_id', 'departmentId']),
      departmentName:
          _string(source, const ['department_name', 'departmentName']) ??
          _string(json, const ['department_name', 'departmentName']) ??
          '',
      priority: _normalizePriority(
        _string(source, const ['priority']) ??
            _string(json, const ['priority']) ??
            'NORMAL',
      ),
      neededDate: neededDateRaw == null
          ? null
          : DateTime.tryParse(neededDateRaw),
      estimatedTotal: _doubleValue(
        source['estimated_total'] ??
            source['estimatedTotal'] ??
            source['total_amount'] ??
            source['totalAmount'] ??
            json['estimated_total'] ??
            json['estimatedTotal'] ??
            json['total_amount'] ??
            json['totalAmount'],
      ),
      currentApprovalStep:
          _string(json, const [
            'current_approval_step',
            'currentApprovalStep',
            'current_step',
            'currentStep',
            'step',
          ]) ??
          _string(source, const [
            'current_approval_step',
            'currentApprovalStep',
            'current_step',
            'currentStep',
            'step',
          ]) ??
          '',
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
    );
  }

  final String requestId;
  final String requestNumber;
  final String title;
  final String requesterName;
  final String? departmentId;
  final String departmentName;
  final String priority;
  final DateTime? neededDate;
  final double estimatedTotal;
  final String currentApprovalStep;
  final DateTime createdAt;
}

class ApprovalDecisionRequestDto {
  const ApprovalDecisionRequestDto({this.comment});

  final String? comment;

  Map<String, dynamic> toJson() {
    final trimmed = comment?.trim();
    if (trimmed == null || trimmed.isEmpty) return const {};
    return {'comment': trimmed};
  }
}

class PurchaseRequestSyncRequestDto {
  const PurchaseRequestSyncRequestDto({
    required this.localId,
    required this.companyId,
    required this.title,
    required this.description,
    required this.priority,
    required this.neededDate,
    required this.totalAmount,
    required this.items,
  });

  final String localId;
  final String companyId;
  final String title;
  final String? description;
  final String priority;
  final DateTime? neededDate;
  final double totalAmount;
  final List<PurchaseRequestItemSyncDto> items;

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'company_id': companyId,
    'title': title,
    'description': description,
    'priority': priority,
    'needed_date': neededDate?.toIso8601String(),
    'total_amount': totalAmount,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class PurchaseRequestItemSyncDto {
  const PurchaseRequestItemSyncDto({
    required this.localId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String localId;
  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory PurchaseRequestItemSyncDto.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestItemSyncDto(
      localId: json['local_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'name': name,
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
    'line_total': lineTotal,
  };
}

class PurchaseRequestSyncResponseDto {
  const PurchaseRequestSyncResponseDto({
    required this.serverId,
    required this.requestNumber,
    required this.syncedAt,
  });

  factory PurchaseRequestSyncResponseDto.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestSyncResponseDto(
      serverId: json['server_id'] as String,
      requestNumber: json['request_number'] as String,
      syncedAt: DateTime.parse(json['synced_at'] as String),
    );
  }

  final String serverId;
  final String requestNumber;
  final DateTime syncedAt;

  Map<String, dynamic> toJson() => {
    'server_id': serverId,
    'request_number': requestNumber,
    'synced_at': syncedAt.toIso8601String(),
  };
}

class ApprovalActionRequestDto {
  const ApprovalActionRequestDto({required this.action, required this.comment});

  final String action;
  final String comment;

  Map<String, dynamic> toJson() => {'action': action, 'comment': comment};
}

class VendorPayloadDto {
  const VendorPayloadDto({
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.status,
  });

  final String name;
  final String? contactPerson;
  final String phone;
  final String? email;
  final String? address;
  final String status;

  Map<String, dynamic> toJson() => {
    'name': name,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'status': _normalizeVendorStatus(status),
  };
}

class VendorPageDto {
  const VendorPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory VendorPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final itemsJson =
        _objectList(data['items']) ??
        _objectList(data['vendors']) ??
        _objectList(data['data']) ??
        _objectList(json['items']) ??
        _objectList(json['vendors']) ??
        _objectList(json['data']) ??
        const [];
    final meta = _object(data['meta']) ?? _object(json['meta']) ?? data;

    return VendorPageDto(
      items: itemsJson.map(VendorDto.fromJson).toList(),
      page: _intValue(meta['page'], fallback: 1),
      limit: _intValue(meta['limit'], fallback: itemsJson.length),
      total: _intValue(meta['total'], fallback: itemsJson.length),
    );
  }

  final List<VendorDto> items;
  final int page;
  final int limit;
  final int total;
}

class VendorDto {
  const VendorDto({
    required this.id,
    required this.companyId,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final createdAtRaw =
        _string(source, const ['createdAt', 'created_at']) ?? '';
    final updatedAtRaw =
        _string(source, const ['updatedAt', 'updated_at']) ?? createdAtRaw;

    return VendorDto(
      id: _string(source, const ['id', 'serverId', 'server_id']) ?? '',
      companyId: _string(source, const ['companyId', 'company_id']) ?? '',
      name: _string(source, const ['name']) ?? '',
      contactPerson: _string(source, const ['contactPerson', 'contact_person']),
      phone: _string(source, const ['phone']) ?? '',
      email: _string(source, const ['email']),
      address: _string(source, const ['address']),
      status: _normalizeVendorStatus(
        _string(source, const ['status']) ??
            (_bool(source, const ['isActive', 'is_active']) == false
                ? 'INACTIVE'
                : 'ACTIVE'),
      ),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  final String id;
  final String companyId;
  final String name;
  final String? contactPerson;
  final String phone;
  final String? email;
  final String? address;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'name': name,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class CreateRfqPayloadDto {
  const CreateRfqPayloadDto({
    required this.purchaseRequestId,
    required this.dueDate,
    required this.notes,
  });

  final String purchaseRequestId;
  final DateTime dueDate;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'purchaseRequestId': purchaseRequestId,
    'dueDate': _dateOnly(dueDate),
    'notes': notes,
  };
}

class AssignRfqVendorsPayloadDto {
  const AssignRfqVendorsPayloadDto({required this.vendorIds});

  final List<String> vendorIds;

  Map<String, dynamic> toJson() => {'vendorIds': vendorIds};
}

class CreateQuotationPayloadDto {
  const CreateQuotationPayloadDto({
    required this.vendorId,
    required this.quotationNumber,
    required this.quotationDate,
    required this.validUntil,
    required this.notes,
    required this.items,
  });

  final String vendorId;
  final String quotationNumber;
  final DateTime quotationDate;
  final DateTime? validUntil;
  final String? notes;
  final List<CreateQuotationItemPayloadDto> items;

  Map<String, dynamic> toJson() => {
    'vendorId': vendorId,
    'quotationNumber': quotationNumber,
    'quotationDate': _dateOnly(quotationDate),
    'validUntil': validUntil == null ? null : _dateOnly(validUntil!),
    'notes': notes,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class CreateQuotationItemPayloadDto {
  const CreateQuotationItemPayloadDto({
    required this.rfqItemId,
    required this.unitPrice,
  });

  final String rfqItemId;
  final double unitPrice;

  Map<String, dynamic> toJson() => {
    'rfqItemId': rfqItemId,
    'unitPrice': unitPrice,
  };
}

class SelectedQuotationPayloadDto {
  const SelectedQuotationPayloadDto({required this.quotationId});

  final String quotationId;

  Map<String, dynamic> toJson() => {'quotationId': quotationId};
}

class RfqPageDto {
  const RfqPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory RfqPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final itemsJson =
        _objectList(data['items']) ??
        _objectList(data['rfqs']) ??
        _objectList(data['data']) ??
        _objectList(json['items']) ??
        _objectList(json['rfqs']) ??
        _objectList(json['data']) ??
        const [];
    final meta = _object(data['meta']) ?? _object(json['meta']) ?? data;

    return RfqPageDto(
      items: itemsJson.map(RfqDto.fromJson).toList(),
      page: _intValue(meta['page'], fallback: 1),
      limit: _intValue(meta['limit'], fallback: itemsJson.length),
      total: _intValue(meta['total'], fallback: itemsJson.length),
    );
  }

  final List<RfqDto> items;
  final int page;
  final int limit;
  final int total;
}

class EligiblePurchaseRequestPageDto {
  const EligiblePurchaseRequestPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory EligiblePurchaseRequestPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final itemsJson =
        _objectList(data['items']) ??
        _objectList(data['requests']) ??
        _objectList(data['purchaseRequests']) ??
        _objectList(data['data']) ??
        _objectList(json['items']) ??
        _objectList(json['requests']) ??
        _objectList(json['purchaseRequests']) ??
        _objectList(json['data']) ??
        const [];
    final meta = _object(data['meta']) ?? _object(json['meta']) ?? data;

    return EligiblePurchaseRequestPageDto(
      items: itemsJson.map(EligiblePurchaseRequestDto.fromJson).toList(),
      page: _intValue(meta['page'], fallback: 1),
      limit: _intValue(meta['limit'], fallback: itemsJson.length),
      total: _intValue(meta['total'], fallback: itemsJson.length),
    );
  }

  final List<EligiblePurchaseRequestDto> items;
  final int page;
  final int limit;
  final int total;
}

class EligiblePurchaseRequestDto {
  const EligiblePurchaseRequestDto({
    required this.id,
    required this.requestNumber,
    required this.title,
    required this.departmentName,
    required this.estimatedTotal,
    required this.status,
  });

  factory EligiblePurchaseRequestDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    return EligiblePurchaseRequestDto(
      id: _string(source, const ['id', 'serverId', 'server_id']) ?? '',
      requestNumber:
          _string(source, const ['requestNumber', 'request_number']) ?? '',
      title: _string(source, const ['title']) ?? '',
      departmentName:
          _string(source, const ['departmentName', 'department_name']) ?? '',
      estimatedTotal: _doubleValue(
        source['estimatedTotal'] ??
            source['estimated_total'] ??
            source['totalAmount'] ??
            source['total_amount'],
      ),
      status: _normalizeStatus(_string(source, const ['status']) ?? 'APPROVED'),
    );
  }

  final String id;
  final String requestNumber;
  final String title;
  final String departmentName;
  final double estimatedTotal;
  final String status;
}

class RfqDto {
  const RfqDto({
    required this.id,
    required this.companyId,
    required this.rfqNumber,
    required this.purchaseRequestId,
    required this.purchaseRequestNumber,
    required this.purchaseRequestTitle,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this.vendorCount,
    required this.quotationCount,
    required this.selectedQuotationId,
    required this.items,
    required this.vendors,
    required this.quotations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RfqDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final pr =
        _object(source['purchaseRequest']) ??
        _object(source['purchase_request']);
    final dueDateRaw = _string(source, const ['dueDate', 'due_date']);
    final createdAtRaw =
        _string(source, const ['createdAt', 'created_at']) ?? '';
    final updatedAtRaw =
        _string(source, const ['updatedAt', 'updated_at']) ?? createdAtRaw;
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['rfqItems']) ??
        _objectList(source['rfq_items']) ??
        const [];
    final vendorsJson =
        _objectList(source['vendors']) ??
        _objectList(source['assignedVendors']) ??
        _objectList(source['assigned_vendors']) ??
        const [];
    final quotationsJson =
        _objectList(source['quotations']) ??
        _objectList(source['quotes']) ??
        const [];

    return RfqDto(
      id: _string(source, const ['id', 'serverId', 'server_id']) ?? '',
      companyId: _string(source, const ['companyId', 'company_id']) ?? '',
      rfqNumber:
          _string(source, const ['rfqNumber', 'rfq_number', 'number']) ?? '',
      purchaseRequestId:
          _string(source, const ['purchaseRequestId', 'purchase_request_id']) ??
          _string(pr ?? const {}, const ['id']) ??
          '',
      purchaseRequestNumber:
          _string(source, const [
            'purchaseRequestNumber',
            'purchase_request_number',
          ]) ??
          _string(pr ?? const {}, const ['requestNumber', 'request_number']) ??
          '',
      purchaseRequestTitle:
          _string(source, const [
            'purchaseRequestTitle',
            'purchase_request_title',
          ]) ??
          _string(pr ?? const {}, const ['title']) ??
          '',
      dueDate: dueDateRaw == null ? null : DateTime.tryParse(dueDateRaw),
      status: _normalizeRfqStatus(_string(source, const ['status']) ?? 'DRAFT'),
      notes: _string(source, const ['notes']),
      vendorCount: _intValue(
        source['vendorCount'] ?? source['vendor_count'],
        fallback: vendorsJson.length,
      ),
      quotationCount: _intValue(
        source['quotationCount'] ?? source['quotation_count'],
        fallback: quotationsJson.length,
      ),
      selectedQuotationId: _string(source, const [
        'selectedQuotationId',
        'selected_quotation_id',
      ]),
      items: itemsJson.map(RfqItemDto.fromJson).toList(),
      vendors: vendorsJson.map(RfqVendorDto.fromJson).toList(),
      quotations: quotationsJson.map(QuotationDto.fromJson).toList(),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  final String id;
  final String companyId;
  final String rfqNumber;
  final String purchaseRequestId;
  final String purchaseRequestNumber;
  final String purchaseRequestTitle;
  final DateTime? dueDate;
  final String status;
  final String? notes;
  final int vendorCount;
  final int quotationCount;
  final String? selectedQuotationId;
  final List<RfqItemDto> items;
  final List<RfqVendorDto> vendors;
  final List<QuotationDto> quotations;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RfqItemDto {
  const RfqItemDto({
    required this.id,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.estimatedUnitPrice,
  });

  factory RfqItemDto.fromJson(Map<String, dynamic> json) {
    return RfqItemDto(
      id: _string(json, const ['id', 'serverId', 'server_id']) ?? '',
      itemName: _string(json, const ['itemName', 'item_name', 'name']) ?? '',
      description: _string(json, const ['description']),
      quantity: _doubleValue(json['quantity']),
      unit: _string(json, const ['unit']) ?? 'pcs',
      estimatedUnitPrice: _doubleValue(
        json['estimatedUnitPrice'] ??
            json['estimated_unit_price'] ??
            json['unitPrice'] ??
            json['unit_price'],
      ),
    );
  }

  final String id;
  final String itemName;
  final String? description;
  final double quantity;
  final String unit;
  final double estimatedUnitPrice;
}

class RfqVendorDto {
  const RfqVendorDto({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.contactPerson,
    required this.email,
    required this.phone,
  });

  factory RfqVendorDto.fromJson(Map<String, dynamic> json) {
    final vendor = _object(json['vendor']);
    final source = vendor ?? json;
    return RfqVendorDto(
      id: _string(json, const ['id']) ?? _string(source, const ['id']) ?? '',
      vendorId:
          _string(json, const ['vendorId', 'vendor_id']) ??
          _string(source, const ['id', 'vendorId', 'vendor_id']) ??
          '',
      vendorName:
          _string(json, const ['vendorName', 'vendor_name']) ??
          _string(source, const ['name', 'vendorName', 'vendor_name']) ??
          '',
      contactPerson:
          _string(json, const ['contactPerson', 'contact_person']) ??
          _string(source, const ['contactPerson', 'contact_person']),
      email: _string(json, const ['email']) ?? _string(source, const ['email']),
      phone: _string(json, const ['phone']) ?? _string(source, const ['phone']),
    );
  }

  final String id;
  final String vendorId;
  final String vendorName;
  final String? contactPerson;
  final String? email;
  final String? phone;
}

class QuotationDto {
  const QuotationDto({
    required this.id,
    required this.rfqId,
    required this.vendorId,
    required this.vendorName,
    required this.quotationNumber,
    required this.quotationDate,
    required this.validUntil,
    required this.status,
    required this.totalAmount,
    required this.notes,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuotationDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final quotationDateRaw = _string(source, const [
      'quotationDate',
      'quotation_date',
    ]);
    final validUntilRaw = _string(source, const ['validUntil', 'valid_until']);
    final createdAtRaw =
        _string(source, const ['createdAt', 'created_at']) ?? '';
    final updatedAtRaw =
        _string(source, const ['updatedAt', 'updated_at']) ?? createdAtRaw;
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['quotationItems']) ??
        _objectList(source['quotation_items']) ??
        const [];

    return QuotationDto(
      id: _string(source, const ['id', 'serverId', 'server_id']) ?? '',
      rfqId: _string(source, const ['rfqId', 'rfq_id']) ?? '',
      vendorId: _string(source, const ['vendorId', 'vendor_id']) ?? '',
      vendorName: _string(source, const ['vendorName', 'vendor_name']) ?? '',
      quotationNumber:
          _string(source, const ['quotationNumber', 'quotation_number']) ?? '',
      quotationDate: quotationDateRaw == null
          ? null
          : DateTime.tryParse(quotationDateRaw),
      validUntil: validUntilRaw == null
          ? null
          : DateTime.tryParse(validUntilRaw),
      status: _string(source, const ['status']) ?? 'SUBMITTED',
      totalAmount: _doubleValue(
        source['totalAmount'] ?? source['total_amount'],
      ),
      notes: _string(source, const ['notes']),
      items: itemsJson.map(QuotationItemDto.fromJson).toList(),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  final String id;
  final String rfqId;
  final String vendorId;
  final String vendorName;
  final String quotationNumber;
  final DateTime? quotationDate;
  final DateTime? validUntil;
  final String status;
  final double totalAmount;
  final String? notes;
  final List<QuotationItemDto> items;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class QuotationItemDto {
  const QuotationItemDto({
    required this.id,
    required this.rfqItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory QuotationItemDto.fromJson(Map<String, dynamic> json) {
    final quantity = _doubleValue(json['quantity'], fallback: 1);
    final unitPrice = _doubleValue(json['unitPrice'] ?? json['unit_price']);
    return QuotationItemDto(
      id: _string(json, const ['id', 'serverId', 'server_id']) ?? '',
      rfqItemId: _string(json, const ['rfqItemId', 'rfq_item_id']) ?? '',
      itemName: _string(json, const ['itemName', 'item_name', 'name']) ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: _doubleValue(
        json['totalPrice'] ?? json['total_price'],
        fallback: quantity * unitPrice,
      ),
    );
  }

  final String id;
  final String rfqItemId;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
}

class RfqComparisonDto {
  const RfqComparisonDto({
    required this.rfqId,
    required this.rfqNumber,
    required this.status,
    required this.purchaseRequestId,
    required this.purchaseRequestNumber,
    required this.purchaseRequestTitle,
    required this.quotations,
    required this.lowestQuotationId,
    required this.selectedQuotationId,
    this.purchaseOrderId,
  });

  factory RfqComparisonDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final pr =
        _object(source['purchaseRequest']) ??
        _object(source['purchase_request']);
    final quotationsJson =
        _objectList(source['quotations']) ??
        _objectList(source['items']) ??
        _objectList(source['data']) ??
        const [];

    return RfqComparisonDto(
      rfqId: _string(source, const ['rfqId', 'rfq_id', 'id', 'serverId']) ?? '',
      rfqNumber:
          _string(source, const ['rfqNumber', 'rfq_number', 'number']) ?? '',
      status: _normalizeRfqStatus(_string(source, const ['status']) ?? 'DRAFT'),
      purchaseRequestId:
          _string(source, const ['purchaseRequestId', 'purchase_request_id']) ??
          _string(pr ?? const {}, const ['id']) ??
          '',
      purchaseRequestNumber:
          _string(source, const [
            'purchaseRequestNumber',
            'purchase_request_number',
          ]) ??
          _string(pr ?? const {}, const ['requestNumber', 'request_number']) ??
          '',
      purchaseRequestTitle:
          _string(source, const [
            'purchaseRequestTitle',
            'purchase_request_title',
          ]) ??
          _string(pr ?? const {}, const ['title']) ??
          '',
      quotations: quotationsJson
          .map(RfqComparisonQuotationDto.fromJson)
          .toList(),
      lowestQuotationId: _string(source, const [
        'lowestQuotationId',
        'lowest_quotation_id',
      ]),
      selectedQuotationId: _string(source, const [
        'selectedQuotationId',
        'selected_quotation_id',
      ]),
      purchaseOrderId: _string(source, const [
        'purchaseOrderId',
        'purchase_order_id',
      ]),
    );
  }

  final String rfqId;
  final String rfqNumber;
  final String status;
  final String purchaseRequestId;
  final String purchaseRequestNumber;
  final String purchaseRequestTitle;
  final List<RfqComparisonQuotationDto> quotations;
  final String? lowestQuotationId;
  final String? selectedQuotationId;
  final String? purchaseOrderId;
}

class RfqComparisonQuotationDto {
  const RfqComparisonQuotationDto({
    required this.quotationId,
    required this.vendorId,
    required this.vendorName,
    required this.quotationNumber,
    required this.quotationDate,
    required this.validUntil,
    required this.totalAmount,
    required this.rank,
    required this.items,
  });

  factory RfqComparisonQuotationDto.fromJson(Map<String, dynamic> json) {
    final vendor = _object(json['vendor']);
    final source = _object(json['quotation']) ?? json;
    final quotationDateRaw = _string(source, const [
      'quotationDate',
      'quotation_date',
    ]);
    final validUntilRaw = _string(source, const ['validUntil', 'valid_until']);
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['quotationItems']) ??
        _objectList(source['quotation_items']) ??
        const [];

    return RfqComparisonQuotationDto(
      quotationId:
          _string(source, const ['quotationId', 'quotation_id', 'id']) ?? '',
      vendorId:
          _string(source, const ['vendorId', 'vendor_id']) ??
          _string(vendor ?? const {}, const ['id']) ??
          '',
      vendorName:
          _string(source, const ['vendorName', 'vendor_name']) ??
          _string(vendor ?? const {}, const ['name']) ??
          '',
      quotationNumber:
          _string(source, const ['quotationNumber', 'quotation_number']) ?? '',
      quotationDate: quotationDateRaw == null
          ? null
          : DateTime.tryParse(quotationDateRaw),
      validUntil: validUntilRaw == null
          ? null
          : DateTime.tryParse(validUntilRaw),
      totalAmount: _doubleValue(
        source['totalAmount'] ?? source['total_amount'],
      ),
      rank: _intValue(source['rank']),
      items: itemsJson.map(RfqComparisonItemDto.fromJson).toList(),
    );
  }

  final String quotationId;
  final String vendorId;
  final String vendorName;
  final String quotationNumber;
  final DateTime? quotationDate;
  final DateTime? validUntil;
  final double totalAmount;
  final int rank;
  final List<RfqComparisonItemDto> items;
}

class RfqComparisonItemDto {
  const RfqComparisonItemDto({
    required this.rfqItemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory RfqComparisonItemDto.fromJson(Map<String, dynamic> json) {
    final quantity = _doubleValue(json['quantity'], fallback: 1);
    final unitPrice = _doubleValue(json['unitPrice'] ?? json['unit_price']);
    return RfqComparisonItemDto(
      rfqItemId: _string(json, const ['rfqItemId', 'rfq_item_id']) ?? '',
      itemName: _string(json, const ['itemName', 'item_name', 'name']) ?? '',
      quantity: quantity,
      unit: _string(json, const ['unit']) ?? 'pcs',
      unitPrice: unitPrice,
      lineTotal: _doubleValue(
        json['lineTotal'] ?? json['line_total'] ?? json['totalPrice'],
        fallback: quantity * unitPrice,
      ),
    );
  }

  final String rfqItemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;
}

class PurchaseOrderPageDto {
  const PurchaseOrderPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PurchaseOrderPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['purchaseOrders']) ??
        _objectList(source['purchase_orders']) ??
        _objectList(source['data']) ??
        _objectList(json['items']) ??
        const [];
    final meta =
        _object(source['meta']) ??
        _object(source['pagination']) ??
        _object(json['meta']) ??
        const {};

    return PurchaseOrderPageDto(
      items: itemsJson.map(PurchaseOrderDto.fromJson).toList(),
      page: _intValue(
        source['page'] ?? meta['page'] ?? source['currentPage'],
        fallback: 1,
      ),
      limit: _intValue(
        source['limit'] ?? meta['limit'] ?? source['perPage'],
        fallback: itemsJson.length,
      ),
      total: _intValue(
        source['total'] ?? meta['total'] ?? source['totalCount'],
        fallback: itemsJson.length,
      ),
    );
  }

  final List<PurchaseOrderDto> items;
  final int page;
  final int limit;
  final int total;
}

class PurchaseOrderDto {
  const PurchaseOrderDto({
    required this.id,
    required this.companyId,
    required this.poNumber,
    required this.vendorId,
    required this.vendorName,
    required this.rfqId,
    required this.rfqNumber,
    required this.quotationId,
    required this.purchaseRequestId,
    required this.purchaseRequestNumber,
    required this.purchaseRequestTitle,
    required this.createdById,
    required this.createdByName,
    required this.status,
    required this.totalAmount,
    required this.notes,
    required this.issueDate,
    required this.receivedDate,
    required this.closedDate,
    required this.cancelledDate,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseOrderDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final vendor =
        _object(source['vendor']) ?? _object(source['vendorDetails']);
    final rfq = _object(source['rfq']);
    final request =
        _object(source['purchaseRequest']) ??
        _object(source['purchase_request']);
    final creator =
        _object(source['createdBy']) ?? _object(source['created_by']);
    final createdAtRaw =
        _string(source, const ['createdAt', 'created_at']) ?? '';
    final updatedAtRaw =
        _string(source, const ['updatedAt', 'updated_at']) ?? createdAtRaw;
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['purchaseOrderItems']) ??
        _objectList(source['purchase_order_items']) ??
        const [];

    return PurchaseOrderDto(
      id:
          _string(source, const [
            'id',
            'localId',
            'local_id',
            'serverId',
            'server_id',
          ]) ??
          '',
      companyId:
          _string(source, const ['companyId', 'company_id']) ??
          _string(vendor ?? const {}, const ['companyId', 'company_id']) ??
          '',
      poNumber:
          _string(source, const ['poNumber', 'po_number', 'number']) ?? '',
      vendorId:
          _string(source, const ['vendorId', 'vendor_id']) ??
          _string(vendor ?? const {}, const ['id']) ??
          '',
      vendorName:
          _string(source, const ['vendorName', 'vendor_name']) ??
          _string(vendor ?? const {}, const ['name']) ??
          '',
      rfqId:
          _string(source, const ['rfqId', 'rfq_id']) ??
          _string(rfq ?? const {}, const ['id']) ??
          '',
      rfqNumber:
          _string(source, const ['rfqNumber', 'rfq_number']) ??
          _string(rfq ?? const {}, const [
            'rfqNumber',
            'rfq_number',
            'number',
          ]) ??
          '',
      quotationId: _string(source, const ['quotationId', 'quotation_id']) ?? '',
      purchaseRequestId:
          _string(source, const ['purchaseRequestId', 'purchase_request_id']) ??
          _string(request ?? const {}, const ['id']) ??
          '',
      purchaseRequestNumber:
          _string(source, const [
            'purchaseRequestNumber',
            'purchase_request_number',
          ]) ??
          _string(request ?? const {}, const [
            'requestNumber',
            'request_number',
            'number',
          ]) ??
          '',
      purchaseRequestTitle:
          _string(source, const [
            'purchaseRequestTitle',
            'purchase_request_title',
          ]) ??
          _string(request ?? const {}, const ['title']) ??
          '',
      createdById:
          _string(source, const ['createdById', 'created_by_id']) ??
          _string(creator ?? const {}, const ['id']) ??
          '',
      createdByName:
          _string(source, const ['createdByName', 'created_by_name']) ??
          _string(creator ?? const {}, const ['name']) ??
          '',
      status: _normalizePurchaseOrderStatus(
        _string(source, const ['status']) ?? 'DRAFT',
      ),
      totalAmount: _doubleValue(
        source['totalAmount'] ??
            source['total_amount'] ??
            source['grandTotal'] ??
            source['grand_total'],
      ),
      notes: _string(source, const ['notes']),
      issueDate: _parseOptionalDate(
        _string(source, const ['issueDate', 'issue_date', 'issuedAt']),
      ),
      receivedDate: _parseOptionalDate(
        _string(source, const ['receivedDate', 'received_date', 'receivedAt']),
      ),
      closedDate: _parseOptionalDate(
        _string(source, const ['closedDate', 'closed_date', 'closedAt']),
      ),
      cancelledDate: _parseOptionalDate(
        _string(source, const [
          'cancelledDate',
          'cancelled_date',
          'canceledDate',
          'canceled_date',
          'cancelledAt',
          'canceledAt',
        ]),
      ),
      items: itemsJson.map(PurchaseOrderItemDto.fromJson).toList(),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  final String id;
  final String companyId;
  final String poNumber;
  final String vendorId;
  final String vendorName;
  final String rfqId;
  final String rfqNumber;
  final String quotationId;
  final String purchaseRequestId;
  final String purchaseRequestNumber;
  final String purchaseRequestTitle;
  final String createdById;
  final String createdByName;
  final String status;
  final double totalAmount;
  final String? notes;
  final DateTime? issueDate;
  final DateTime? receivedDate;
  final DateTime? closedDate;
  final DateTime? cancelledDate;
  final List<PurchaseOrderItemDto> items;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PurchaseOrderItemDto {
  const PurchaseOrderItemDto({
    required this.id,
    required this.rfqItemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory PurchaseOrderItemDto.fromJson(Map<String, dynamic> json) {
    final quantity = _doubleValue(json['quantity'], fallback: 1);
    final unitPrice = _doubleValue(json['unitPrice'] ?? json['unit_price']);
    return PurchaseOrderItemDto(
      id: _string(json, const ['id', 'localId', 'local_id', 'serverId']) ?? '',
      rfqItemId: _string(json, const ['rfqItemId', 'rfq_item_id']) ?? '',
      itemName: _string(json, const ['itemName', 'item_name', 'name']) ?? '',
      quantity: quantity,
      unit: _string(json, const ['unit']) ?? 'pcs',
      unitPrice: unitPrice,
      lineTotal: _doubleValue(
        json['lineTotal'] ??
            json['line_total'] ??
            json['totalPrice'] ??
            json['total_price'],
        fallback: quantity * unitPrice,
      ),
    );
  }

  final String id;
  final String rfqItemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;
}

class CreatePurchaseOrderPayloadDto {
  const CreatePurchaseOrderPayloadDto({
    required this.quotationId,
    required this.notes,
  });

  final String quotationId;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'quotationId': quotationId,
    if (notes != null) 'notes': notes,
  };
}

class UpdatePurchaseOrderPayloadDto {
  const UpdatePurchaseOrderPayloadDto({required this.notes});

  final String? notes;

  Map<String, dynamic> toJson() => {if (notes != null) 'notes': notes};
}

class InvoicePageDto {
  const InvoicePageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory InvoicePageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['invoices']) ??
        _objectList(source['data']) ??
        _objectList(json['items']) ??
        const [];
    final meta =
        _object(source['meta']) ??
        _object(source['pagination']) ??
        _object(json['meta']) ??
        const {};

    return InvoicePageDto(
      items: itemsJson.map(InvoiceDto.fromJson).toList(),
      page: _intValue(
        source['page'] ?? meta['page'] ?? source['currentPage'],
        fallback: 1,
      ),
      limit: _intValue(
        source['limit'] ?? meta['limit'] ?? source['perPage'],
        fallback: itemsJson.length,
      ),
      total: _intValue(
        source['total'] ?? meta['total'] ?? source['totalCount'],
        fallback: itemsJson.length,
      ),
    );
  }

  final List<InvoiceDto> items;
  final int page;
  final int limit;
  final int total;
}

class InvoiceDto {
  const InvoiceDto({
    required this.id,
    required this.companyId,
    required this.invoiceNumber,
    required this.vendorId,
    required this.vendorName,
    required this.purchaseOrderId,
    required this.purchaseOrderNumber,
    required this.status,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final vendor = _object(source['vendor']);
    final order =
        _object(source['purchaseOrder']) ??
        _object(source['purchase_order']) ??
        _object(source['po']);
    final createdAtRaw =
        _string(source, const ['createdAt', 'created_at']) ?? '';
    final updatedAtRaw =
        _string(source, const ['updatedAt', 'updated_at']) ?? createdAtRaw;
    final invoiceAmount = _doubleValue(
      source['invoiceAmount'] ??
          source['invoice_amount'] ??
          source['amount'] ??
          source['totalAmount'],
    );
    final paidAmount = _doubleValue(
      source['paidAmount'] ?? source['paid_amount'],
    );

    return InvoiceDto(
      id:
          _string(source, const [
            'id',
            'localId',
            'local_id',
            'serverId',
            'server_id',
          ]) ??
          '',
      companyId:
          _string(source, const ['companyId', 'company_id']) ??
          _string(vendor ?? const {}, const ['companyId', 'company_id']) ??
          '',
      invoiceNumber:
          _string(source, const [
            'invoiceNumber',
            'invoice_number',
            'number',
          ]) ??
          '',
      vendorId:
          _string(source, const ['vendorId', 'vendor_id']) ??
          _string(vendor ?? const {}, const ['id']) ??
          _string(order ?? const {}, const ['vendorId', 'vendor_id']) ??
          '',
      vendorName:
          _string(source, const ['vendorName', 'vendor_name']) ??
          _string(vendor ?? const {}, const ['name']) ??
          _string(order ?? const {}, const ['vendorName', 'vendor_name']) ??
          '',
      purchaseOrderId:
          _string(source, const ['purchaseOrderId', 'purchase_order_id']) ??
          _string(order ?? const {}, const ['id']) ??
          '',
      purchaseOrderNumber:
          _string(source, const [
            'purchaseOrderNumber',
            'purchase_order_number',
            'poNumber',
            'po_number',
          ]) ??
          _string(order ?? const {}, const [
            'poNumber',
            'po_number',
            'number',
          ]) ??
          '',
      status: _normalizeInvoiceStatus(
        _string(source, const ['status']) ?? 'PENDING',
      ),
      invoiceDate: _parseOptionalDate(
        _string(source, const ['invoiceDate', 'invoice_date']),
      ),
      dueDate: _parseOptionalDate(
        _string(source, const ['dueDate', 'due_date']),
      ),
      invoiceAmount: invoiceAmount,
      paidAmount: paidAmount,
      dueAmount: _doubleValue(
        source['dueAmount'] ?? source['due_amount'],
        fallback: invoiceAmount - paidAmount,
      ),
      notes: _string(source, const ['notes']),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  final String id;
  final String companyId;
  final String invoiceNumber;
  final String vendorId;
  final String vendorName;
  final String purchaseOrderId;
  final String purchaseOrderNumber;
  final String status;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double invoiceAmount;
  final double paidAmount;
  final double dueAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CreateInvoicePayloadDto {
  const CreateInvoicePayloadDto({
    required this.purchaseOrderId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.notes,
  });

  final String purchaseOrderId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double invoiceAmount;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'purchaseOrderId': purchaseOrderId,
    'invoiceNumber': invoiceNumber,
    'invoiceDate': _dateOnly(invoiceDate),
    'dueDate': _dateOnly(dueDate),
    'invoiceAmount': invoiceAmount,
    if (notes != null) 'notes': notes,
  };
}

class UpdateInvoicePayloadDto {
  const UpdateInvoicePayloadDto({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.notes,
  });

  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double invoiceAmount;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'invoiceNumber': invoiceNumber,
    'invoiceDate': _dateOnly(invoiceDate),
    'dueDate': _dateOnly(dueDate),
    'invoiceAmount': invoiceAmount,
    if (notes != null) 'notes': notes,
  };
}

class PaymentPageDto {
  const PaymentPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PaymentPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final itemsJson =
        _objectList(source['items']) ??
        _objectList(source['payments']) ??
        _objectList(source['data']) ??
        _objectList(json['items']) ??
        const [];
    final meta =
        _object(source['meta']) ??
        _object(source['pagination']) ??
        _object(json['meta']) ??
        const {};

    return PaymentPageDto(
      items: itemsJson.map(PaymentDto.fromJson).toList(),
      page: _intValue(
        source['page'] ?? meta['page'] ?? source['currentPage'],
        fallback: 1,
      ),
      limit: _intValue(
        source['limit'] ?? meta['limit'] ?? source['perPage'],
        fallback: itemsJson.length,
      ),
      total: _intValue(
        source['total'] ?? meta['total'] ?? source['totalCount'],
        fallback: itemsJson.length,
      ),
    );
  }

  final List<PaymentDto> items;
  final int page;
  final int limit;
  final int total;
}

class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.companyId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.vendorId,
    required this.vendorName,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.notes,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']);
    final source = data ?? json;
    final invoice = _object(source['invoice']);
    final vendor = _object(source['vendor']) ?? _object(invoice?['vendor']);
    final creator =
        _object(source['createdBy']) ??
        _object(source['created_by']) ??
        _object(source['user']);
    final createdAtRaw =
        _string(source, const ['createdAt', 'created_at']) ?? '';
    final updatedAtRaw =
        _string(source, const ['updatedAt', 'updated_at']) ?? createdAtRaw;

    return PaymentDto(
      id:
          _string(source, const [
            'id',
            'localId',
            'local_id',
            'serverId',
            'server_id',
          ]) ??
          '',
      companyId:
          _string(source, const ['companyId', 'company_id']) ??
          _string(invoice ?? const {}, const ['companyId', 'company_id']) ??
          '',
      invoiceId:
          _string(source, const ['invoiceId', 'invoice_id']) ??
          _string(invoice ?? const {}, const ['id']) ??
          '',
      invoiceNumber:
          _string(source, const ['invoiceNumber', 'invoice_number']) ??
          _string(invoice ?? const {}, const [
            'invoiceNumber',
            'invoice_number',
            'number',
          ]) ??
          '',
      vendorId:
          _string(source, const ['vendorId', 'vendor_id']) ??
          _string(vendor ?? const {}, const ['id']) ??
          _string(invoice ?? const {}, const ['vendorId', 'vendor_id']) ??
          '',
      vendorName:
          _string(source, const ['vendorName', 'vendor_name']) ??
          _string(vendor ?? const {}, const ['name']) ??
          _string(invoice ?? const {}, const ['vendorName', 'vendor_name']) ??
          '',
      paymentDate: _parseOptionalDate(
        _string(source, const ['paymentDate', 'payment_date', 'date']),
      ),
      amount: _doubleValue(source['amount'] ?? source['paymentAmount']),
      paymentMethod: _normalizePaymentMethod(
        _string(source, const ['paymentMethod', 'payment_method', 'method']) ??
            'OTHER',
      ),
      referenceNumber: _string(source, const [
        'referenceNumber',
        'reference_number',
        'reference',
      ]),
      notes: _string(source, const ['notes']),
      createdById:
          _string(source, const ['createdById', 'created_by_id']) ??
          _string(creator ?? const {}, const ['id']) ??
          '',
      createdByName:
          _string(source, const ['createdByName', 'created_by_name']) ??
          _string(creator ?? const {}, const [
            'name',
            'fullName',
            'full_name',
          ]) ??
          '',
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  final String id;
  final String companyId;
  final String invoiceId;
  final String invoiceNumber;
  final String vendorId;
  final String vendorName;
  final DateTime? paymentDate;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CreatePaymentPayloadDto {
  const CreatePaymentPayloadDto({
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.notes,
  });

  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'paymentDate': _dateOnly(paymentDate),
    'amount': amount,
    'paymentMethod': _normalizePaymentMethod(paymentMethod),
    if (referenceNumber != null) 'referenceNumber': referenceNumber,
    if (notes != null) 'notes': notes,
  };
}

class BudgetPageDto {
  BudgetPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory BudgetPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final list =
        _objectList(data['items']) ??
        _objectList(data['budgets']) ??
        _objectList(json['data']) ??
        const [];
    return BudgetPageDto(
      items: list.map(BudgetDto.fromJson).toList(),
      page: _intValue(data['page'], fallback: 1),
      limit: _intValue(data['limit'], fallback: list.length),
      total: _intValue(data['total'], fallback: list.length),
    );
  }

  final List<BudgetDto> items;
  final int page;
  final int limit;
  final int total;
}

class BudgetDto {
  BudgetDto({
    required this.id,
    required this.companyId,
    required this.departmentId,
    required this.departmentName,
    required this.name,
    required this.periodType,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.availableAmount,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.activatedAt,
    required this.closedAt,
  });

  factory BudgetDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final department = _object(data['department']);
    final startRaw =
        _string(data, const ['periodStartDate', 'period_start_date']) ??
        DateTime.now().toIso8601String();
    final endRaw =
        _string(data, const ['periodEndDate', 'period_end_date']) ??
        DateTime.now().toIso8601String();
    final createdRaw =
        _string(data, const ['createdAt', 'created_at']) ??
        DateTime.now().toIso8601String();
    final updatedRaw =
        _string(data, const ['updatedAt', 'updated_at']) ?? createdRaw;
    return BudgetDto(
      id: _string(data, const ['id', 'localId', 'serverId']) ?? '',
      companyId: _string(data, const ['companyId', 'company_id']) ?? '',
      departmentId:
          _string(data, const ['departmentId', 'department_id']) ??
          _string(department ?? const {}, const ['id']) ??
          '',
      departmentName:
          _string(data, const ['departmentName', 'department_name']) ??
          _string(department ?? const {}, const ['name']) ??
          '',
      name: _string(data, const ['name', 'budgetName', 'budget_name']) ?? '',
      periodType: _normalizeBudgetPeriodType(
        _string(data, const ['periodType', 'period_type']) ?? 'MONTHLY',
      ),
      periodStartDate: DateTime.tryParse(startRaw) ?? DateTime.now(),
      periodEndDate: DateTime.tryParse(endRaw) ?? DateTime.now(),
      allocatedAmount: _doubleValue(
        data['allocatedAmount'] ?? data['allocated_amount'],
      ),
      spentAmount: _doubleValue(data['spentAmount'] ?? data['spent_amount']),
      availableAmount: _doubleValue(
        data['availableAmount'] ?? data['available_amount'],
      ),
      status: _normalizeBudgetStatus(
        _string(data, const ['status']) ?? 'DRAFT',
      ),
      notes: _string(data, const ['notes']),
      createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedRaw) ?? DateTime.now(),
      activatedAt: _parseOptionalDate(
        _string(data, const ['activatedAt', 'activated_at']),
      ),
      closedAt: _parseOptionalDate(
        _string(data, const ['closedAt', 'closed_at']),
      ),
    );
  }

  final String id;
  final String companyId;
  final String departmentId;
  final String departmentName;
  final String name;
  final String periodType;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final double allocatedAmount;
  final double spentAmount;
  final double availableAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? activatedAt;
  final DateTime? closedAt;
}

class BudgetPayloadDto {
  const BudgetPayloadDto({
    required this.departmentId,
    required this.name,
    required this.periodType,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.allocatedAmount,
    this.notes,
  });

  final String departmentId;
  final String name;
  final String periodType;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final double allocatedAmount;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'departmentId': departmentId,
    'name': name,
    'periodType': _normalizeBudgetPeriodType(periodType),
    'periodStartDate': _dateOnly(periodStartDate),
    'periodEndDate': _dateOnly(periodEndDate),
    'allocatedAmount': allocatedAmount,
    if (notes != null) 'notes': notes,
  };
}

class BudgetAdjustmentPayloadDto {
  const BudgetAdjustmentPayloadDto({
    required this.amount,
    required this.description,
  });

  final double amount;
  final String description;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'description': description,
  };
}

class BudgetTransactionPageDto {
  BudgetTransactionPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory BudgetTransactionPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final list =
        _objectList(data['items']) ??
        _objectList(data['transactions']) ??
        _objectList(json['data']) ??
        const [];
    return BudgetTransactionPageDto(
      items: list.map(BudgetTransactionDto.fromJson).toList(),
      page: _intValue(data['page'], fallback: 1),
      limit: _intValue(data['limit'], fallback: list.length),
      total: _intValue(data['total'], fallback: list.length),
    );
  }

  final List<BudgetTransactionDto> items;
  final int page;
  final int limit;
  final int total;
}

class BudgetTransactionDto {
  BudgetTransactionDto({
    required this.id,
    required this.companyId,
    required this.budgetId,
    required this.transactionType,
    required this.amount,
    required this.referenceType,
    required this.referenceId,
    required this.description,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetTransactionDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final creator = _object(data['createdBy']) ?? _object(data['created_by']);
    final createdRaw =
        _string(data, const ['createdAt', 'created_at']) ??
        DateTime.now().toIso8601String();
    final updatedRaw =
        _string(data, const ['updatedAt', 'updated_at']) ?? createdRaw;
    return BudgetTransactionDto(
      id: _string(data, const ['id']) ?? '',
      companyId: _string(data, const ['companyId', 'company_id']) ?? '',
      budgetId: _string(data, const ['budgetId', 'budget_id']) ?? '',
      transactionType:
          _string(data, const ['transactionType', 'transaction_type']) ??
          'ADJUSTMENT',
      amount: _doubleValue(data['amount']),
      referenceType: _string(data, const ['referenceType', 'reference_type']),
      referenceId: _string(data, const ['referenceId', 'reference_id']),
      description: _string(data, const ['description', 'notes']),
      createdByName:
          _string(data, const ['createdByName', 'created_by_name']) ??
          _string(creator ?? const {}, const ['name']) ??
          '',
      createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedRaw) ?? DateTime.now(),
    );
  }

  final String id;
  final String companyId;
  final String budgetId;
  final String transactionType;
  final double amount;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class BudgetAvailabilityDto {
  BudgetAvailabilityDto({
    required this.available,
    required this.availableAmount,
    required this.message,
  });

  factory BudgetAvailabilityDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    return BudgetAvailabilityDto(
      available: _bool(data, const ['available', 'isAvailable']) ?? false,
      availableAmount: _doubleValue(
        data['availableAmount'] ?? data['available_amount'],
      ),
      message: _string(data, const ['message']) ?? '',
    );
  }

  final bool available;
  final double availableAmount;
  final String message;
}

class ReportResponseDto {
  ReportResponseDto({
    required this.items,
    required this.summary,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory ReportResponseDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final list =
        _objectList(data['items']) ??
        _objectList(data['rows']) ??
        _objectList(data['data']) ??
        _objectList(json['data']) ??
        const [];
    return ReportResponseDto(
      items: list,
      summary: _object(data['summary']) ?? const {},
      page: _intValue(data['page'], fallback: 1),
      limit: _intValue(data['limit'], fallback: list.length),
      total: _intValue(data['total'], fallback: list.length),
    );
  }

  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> summary;
  final int page;
  final int limit;
  final int total;
}

class AttachmentPageDto {
  AttachmentPageDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory AttachmentPageDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final list =
        _objectList(data['items']) ??
        _objectList(data['attachments']) ??
        _objectList(json['data']) ??
        const [];
    return AttachmentPageDto(
      items: list.map(AttachmentDto.fromJson).toList(),
      page: _intValue(data['page'], fallback: 1),
      limit: _intValue(data['limit'], fallback: list.length),
      total: _intValue(data['total'], fallback: list.length),
    );
  }

  final List<AttachmentDto> items;
  final int page;
  final int limit;
  final int total;
}

class AttachmentDto {
  AttachmentDto({
    required this.id,
    required this.companyId,
    required this.entityType,
    required this.entityId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    required this.uploadedByName,
  });

  factory AttachmentDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final uploadedBy =
        _object(data['uploadedBy']) ?? _object(data['uploaded_by']);
    final createdRaw =
        _string(data, const ['createdAt', 'created_at']) ??
        DateTime.now().toIso8601String();
    final updatedRaw =
        _string(data, const ['updatedAt', 'updated_at']) ?? createdRaw;
    return AttachmentDto(
      id: _string(data, const ['id']) ?? '',
      companyId: _string(data, const ['companyId', 'company_id']) ?? '',
      entityType: _string(data, const ['entityType', 'entity_type']) ?? '',
      entityId: _string(data, const ['entityId', 'entity_id']) ?? '',
      fileName: _string(data, const ['fileName', 'file_name', 'name']) ?? '',
      mimeType: _string(data, const ['mimeType', 'mime_type']),
      fileSize: _intValue(data['fileSize'] ?? data['file_size']),
      createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedRaw) ?? DateTime.now(),
      uploadedByName:
          _string(data, const ['uploadedByName', 'uploaded_by_name']) ??
          _string(uploadedBy ?? const {}, const ['name']) ??
          '',
    );
  }

  final String id;
  final String companyId;
  final String entityType;
  final String entityId;
  final String fileName;
  final String? mimeType;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String uploadedByName;
}

class AttachmentDownloadUrlDto {
  AttachmentDownloadUrlDto({required this.url});

  factory AttachmentDownloadUrlDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    return AttachmentDownloadUrlDto(
      url: _string(data, const ['url', 'downloadUrl', 'download_url']) ?? '',
    );
  }

  final String url;
}

class DeviceTokenPayloadDto {
  const DeviceTokenPayloadDto({
    required this.deviceId,
    required this.platform,
    required this.fcmToken,
  });

  final String deviceId;
  final String platform;
  final String fcmToken;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'platform': platform,
    'fcmToken': fcmToken,
  };
}

class SyncPushRequestDto {
  const SyncPushRequestDto({required this.changes});

  final List<SyncChangeDto> changes;

  Map<String, dynamic> toJson() => {
    'changes': changes.map((item) => item.toJson()).toList(),
  };
}

class SyncChangeDto {
  const SyncChangeDto({
    required this.entityType,
    required this.operation,
    required this.localId,
    required this.data,
  });

  final String entityType;
  final String operation;
  final String localId;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'entityType': entityType,
    'operation': operation,
    'localId': localId,
    'data': data,
  };
}

class SyncPushResponseDto {
  SyncPushResponseDto({required this.results, required this.syncedAt});

  factory SyncPushResponseDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final list =
        _objectList(data['results']) ?? _objectList(data['items']) ?? const [];
    final syncedRaw =
        _string(data, const ['syncedAt', 'synced_at']) ??
        DateTime.now().toIso8601String();
    return SyncPushResponseDto(
      results: list.map(SyncPushResultDto.fromJson).toList(),
      syncedAt: DateTime.tryParse(syncedRaw) ?? DateTime.now(),
    );
  }

  final List<SyncPushResultDto> results;
  final DateTime syncedAt;
}

class SyncPushResultDto {
  SyncPushResultDto({
    required this.localId,
    required this.serverId,
    required this.status,
    required this.message,
    required this.serverUpdatedAt,
  });

  factory SyncPushResultDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    return SyncPushResultDto(
      localId: _string(data, const ['localId', 'local_id']) ?? '',
      serverId: _string(data, const ['serverId', 'server_id', 'id']) ?? '',
      status: _string(data, const ['status']) ?? 'synced',
      message: _string(data, const ['message']),
      serverUpdatedAt: _parseOptionalDate(
        _string(data, const ['serverUpdatedAt', 'server_updated_at']),
      ),
    );
  }

  final String localId;
  final String serverId;
  final String status;
  final String? message;
  final DateTime? serverUpdatedAt;
}

class SyncPullResponseDto {
  SyncPullResponseDto({required this.purchaseRequests, required this.syncedAt});

  factory SyncPullResponseDto.fromJson(Map<String, dynamic> json) {
    final data = _object(json['data']) ?? json;
    final changes = _object(data['changes']) ?? data;
    final list =
        _objectList(changes['purchaseRequests']) ??
        _objectList(changes['purchase_requests']) ??
        const [];
    final syncedRaw =
        _string(data, const ['syncedAt', 'synced_at']) ??
        DateTime.now().toIso8601String();
    return SyncPullResponseDto(
      purchaseRequests: list.map(PurchaseRequestDto.fromJson).toList(),
      syncedAt: DateTime.tryParse(syncedRaw) ?? DateTime.now(),
    );
  }

  final List<PurchaseRequestDto> purchaseRequests;
  final DateTime syncedAt;
}

List<DashboardSummaryCardDto> _dashboardCards(Map<String, dynamic> data) {
  final cardsJson = _objectList(data['cards']);
  if (cardsJson != null) {
    return cardsJson.map(DashboardSummaryCardDto.fromJson).toList();
  }

  const knownCards = {
    'my_requests': ('My Requests', 'purchase_requests.view'),
    'myRequests': ('My Requests', 'purchase_requests.view'),
    'pending_approvals': ('Pending Approvals', 'approvals.manage'),
    'pendingApprovals': ('Pending Approvals', 'approvals.manage'),
    'purchase_orders': ('Purchase Orders', 'purchase_orders.view'),
    'purchaseOrders': ('Purchase Orders', 'purchase_orders.view'),
    'invoices': ('Invoices', 'invoices.view'),
    'total_spend': ('Total Spend', 'finance.view'),
    'totalSpend': ('Total Spend', 'finance.view'),
    'due_amount': ('Due Amount', 'finance.view'),
    'dueAmount': ('Due Amount', 'finance.view'),
  };

  return [
    for (final entry in knownCards.entries)
      if (data.containsKey(entry.key))
        DashboardSummaryCardDto(
          key: entry.key,
          label: entry.value.$1,
          value: _displayValue(data[entry.key]),
          permission: entry.value.$2,
        ),
  ];
}

Map<String, dynamic>? _object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>>? _objectList(Object? value) {
  if (value is List) {
    final objects = <Map<String, dynamic>>[];
    for (final item in value) {
      final object = _object(item);
      if (object != null) {
        objects.add(object);
      }
    }
    return objects;
  }
  return null;
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is num || value is bool) return value.toString();
  }
  return null;
}

String _displayValue(Object? value) {
  if (value == null) return '0';
  if (value is num) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
  return value.toString();
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String _normalizeStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'SUBMITTED' => 'SUBMITTED',
    'APPROVED' => 'APPROVED',
    'REJECTED' => 'REJECTED',
    'CANCELLED' || 'CANCELED' => 'CANCELLED',
    'PO_CREATED' => 'PO_CREATED',
    _ => 'DRAFT',
  };
}

String _normalizePriority(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'LOW' => 'LOW',
    'HIGH' => 'HIGH',
    'URGENT' => 'URGENT',
    _ => 'NORMAL',
  };
}

String _normalizeVendorStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return normalized == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
}

String _normalizeRfqStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'OPEN' => 'OPEN',
    'QUOTATION_RECEIVED' => 'QUOTATION_RECEIVED',
    'COMPLETED' => 'COMPLETED',
    'CANCELLED' || 'CANCELED' => 'CANCELLED',
    _ => 'DRAFT',
  };
}

String _normalizePurchaseOrderStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'ISSUED' => 'ISSUED',
    'RECEIVED' => 'RECEIVED',
    'CLOSED' => 'CLOSED',
    'CANCELLED' || 'CANCELED' => 'CANCELLED',
    _ => 'DRAFT',
  };
}

String _normalizeInvoiceStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'PARTIALLY_PAID' || 'PARTIAL' => 'PARTIALLY_PAID',
    'PAID' => 'PAID',
    'CANCELLED' || 'CANCELED' => 'CANCELLED',
    _ => 'PENDING',
  };
}

String _normalizePaymentMethod(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'CASH' => 'CASH',
    'BANK_TRANSFER' || 'BANK' || 'TRANSFER' => 'BANK_TRANSFER',
    'CHEQUE' || 'CHECK' => 'CHEQUE',
    'MOBILE_BANKING' || 'MOBILE' => 'MOBILE_BANKING',
    'CARD' || 'CREDIT_CARD' || 'DEBIT_CARD' => 'CARD',
    'ONLINE' || 'ONLINE_PAYMENT' => 'ONLINE',
    _ => 'OTHER',
  };
}

String _normalizeBudgetStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'ACTIVE' => 'ACTIVE',
    'CLOSED' => 'CLOSED',
    _ => 'DRAFT',
  };
}

String _normalizeBudgetPeriodType(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    'QUARTERLY' => 'QUARTERLY',
    'YEARLY' || 'ANNUAL' => 'YEARLY',
    'CUSTOM' => 'CUSTOM',
    _ => 'MONTHLY',
  };
}

String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;

DateTime? _parseOptionalDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

bool? _bool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
  }
  return null;
}

List<String>? _stringList(Object? value) {
  if (value is List) {
    return [
      for (final item in value)
        if (item is String)
          item
        else if (item is Map)
          _string(Map<String, dynamic>.from(item), const [
                'permission',
                'code',
                'key',
                'name',
              ]) ??
              '',
    ].where((item) => item.trim().isNotEmpty).toList();
  }
  return null;
}
