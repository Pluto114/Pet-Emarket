import 'product.dart';

class PetOrder {
  const PetOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.statusName,
    required this.totalAmount,
    required this.discountAmount,
    required this.payAmount,
    required this.paymentNo,
    required this.paidAt,
    required this.rewardPoints,
    required this.pointsReversed,
    required this.receiver,
    required this.phone,
    required this.addressDetail,
    required this.refundReason,
    required this.refundAuditStatus,
    required this.refundRollbackStatus,
    required this.auditRemark,
    required this.inventoryRestored,
    required this.items,
    required this.statusLogs,
  });

  final String id;
  final String orderNo;
  final int status;
  final String statusName;
  final double totalAmount;
  final double discountAmount;
  final double payAmount;
  final String paymentNo;
  final String paidAt;
  final int rewardPoints;
  final bool pointsReversed;
  final String receiver;
  final String phone;
  final String addressDetail;
  final String refundReason;
  final String refundAuditStatus;
  final int? refundRollbackStatus;
  final String auditRemark;
  final bool inventoryRestored;
  final List<OrderItem> items;
  final List<OrderStatusLog> statusLogs;

  factory PetOrder.fromJson(Map<String, dynamic> json) {
    return PetOrder(
      id: json['id']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      status: NumberParser.toInt(json['status']),
      statusName: json['statusName']?.toString() ?? '',
      totalAmount: NumberParser.toDouble(json['totalAmount']),
      discountAmount: NumberParser.toDouble(json['discountAmount']),
      payAmount: NumberParser.toDouble(json['payAmount']),
      paymentNo: json['paymentNo']?.toString() ?? '',
      paidAt: json['paidAt']?.toString() ?? '',
      rewardPoints: NumberParser.toInt(json['rewardPoints']),
      pointsReversed: json['pointsReversed'] == true,
      receiver: json['receiver']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressDetail: json['addressDetail']?.toString() ?? '',
      refundReason: json['refundReason']?.toString() ?? '',
      refundAuditStatus: json['refundAuditStatus']?.toString() ?? '',
      refundRollbackStatus:
          json['refundRollbackStatus'] == null
              ? null
              : NumberParser.toInt(json['refundRollbackStatus']),
      auditRemark: json['auditRemark']?.toString() ?? '',
      inventoryRestored: json['inventoryRestored'] == true,
      items:
          (json['items'] is List)
              ? (json['items'] as List)
                  .map(
                    (item) => OrderItem.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList()
              : const [],
      statusLogs:
          (json['statusLogs'] is List)
              ? (json['statusLogs'] as List)
                  .map(
                    (item) => OrderStatusLog.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList()
              : const [],
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.productName,
    required this.productType,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  final String productName;
  final String productType;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['productName']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
      unitPrice: NumberParser.toDouble(json['unitPrice']),
      quantity: NumberParser.toInt(json['quantity']),
      subtotal: NumberParser.toDouble(json['subtotal']),
    );
  }
}

class OrderStatusLog {
  const OrderStatusLog({
    required this.fromStatus,
    required this.toStatus,
    required this.toStatusName,
    required this.reason,
    required this.operatorRole,
    required this.createdAt,
  });

  final int? fromStatus;
  final int toStatus;
  final String toStatusName;
  final String reason;
  final String operatorRole;
  final String createdAt;

  factory OrderStatusLog.fromJson(Map<String, dynamic> json) {
    return OrderStatusLog(
      fromStatus:
          json['fromStatus'] == null
              ? null
              : NumberParser.toInt(json['fromStatus']),
      toStatus: NumberParser.toInt(json['toStatus']),
      toStatusName: json['toStatusName']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      operatorRole: json['operatorRole']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
