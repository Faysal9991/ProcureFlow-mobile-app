class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.userId,
    required this.userName,
    required this.email,
    required this.companyId,
    required this.companyName,
    required this.roles,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['access_token'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      email: json['email'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
    );
  }

  final String accessToken;
  final String userId;
  final String userName;
  final String email;
  final String companyId;
  final String companyName;
  final List<String> roles;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'user_id': userId,
    'user_name': userName,
    'email': email,
    'company_id': companyId,
    'company_name': companyName,
    'roles': roles,
  };
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

class VendorDto {
  const VendorDto({
    required this.serverId,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory VendorDto.fromJson(Map<String, dynamic> json) {
    return VendorDto(
      serverId: json['server_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );
  }

  final String serverId;
  final String name;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {
    'server_id': serverId,
    'name': name,
    'email': email,
    'phone': phone,
  };
}
