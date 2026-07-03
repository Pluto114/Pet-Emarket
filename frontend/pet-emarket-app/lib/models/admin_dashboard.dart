import 'product.dart';

class AdminDashboard {
  const AdminDashboard({
    required this.userCount,
    required this.activeUserCount,
    required this.merchantCount,
    required this.productCount,
    required this.onSaleProductCount,
    required this.livePetCount,
    required this.pendingLivePetAuditCount,
    required this.storeCount,
    required this.openStoreCount,
    required this.orderCount,
    required this.refundPendingCount,
    required this.totalPayAmount,
    required this.orderStatusDistribution,
    required this.topProducts,
    required this.recentOrders,
  });

  final int userCount;
  final int activeUserCount;
  final int merchantCount;
  final int productCount;
  final int onSaleProductCount;
  final int livePetCount;
  final int pendingLivePetAuditCount;
  final int storeCount;
  final int openStoreCount;
  final int orderCount;
  final int refundPendingCount;
  final double totalPayAmount;
  final List<OrderStatusCount> orderStatusDistribution;
  final List<TopProduct> topProducts;
  final List<DashboardOrder> recentOrders;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      userCount: NumberParser.toInt(json['userCount']),
      activeUserCount: NumberParser.toInt(json['activeUserCount']),
      merchantCount: NumberParser.toInt(json['merchantCount']),
      productCount: NumberParser.toInt(json['productCount']),
      onSaleProductCount: NumberParser.toInt(json['onSaleProductCount']),
      livePetCount: NumberParser.toInt(json['livePetCount']),
      pendingLivePetAuditCount: NumberParser.toInt(
        json['pendingLivePetAuditCount'],
      ),
      storeCount: NumberParser.toInt(json['storeCount']),
      openStoreCount: NumberParser.toInt(json['openStoreCount']),
      orderCount: NumberParser.toInt(json['orderCount']),
      refundPendingCount: NumberParser.toInt(json['refundPendingCount']),
      totalPayAmount: NumberParser.toDouble(json['totalPayAmount']),
      orderStatusDistribution:
          (json['orderStatusDistribution'] is List)
              ? (json['orderStatusDistribution'] as List)
                  .map(
                    (item) => OrderStatusCount.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList()
              : const [],
      topProducts:
          (json['topProducts'] is List)
              ? (json['topProducts'] as List)
                  .map(
                    (item) => TopProduct.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList()
              : const [],
      recentOrders:
          (json['recentOrders'] is List)
              ? (json['recentOrders'] as List)
                  .map(
                    (item) => DashboardOrder.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList()
              : const [],
    );
  }
}

class OrderStatusCount {
  const OrderStatusCount({
    required this.status,
    required this.statusName,
    required this.count,
  });

  final int status;
  final String statusName;
  final int count;

  factory OrderStatusCount.fromJson(Map<String, dynamic> json) {
    return OrderStatusCount(
      status: NumberParser.toInt(json['status']),
      statusName: json['statusName']?.toString() ?? '',
      count: NumberParser.toInt(json['count']),
    );
  }
}

class TopProduct {
  const TopProduct({
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.amount,
  });

  final String productId;
  final String productName;
  final String category;
  final int quantity;
  final double amount;

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      quantity: NumberParser.toInt(json['quantity']),
      amount: NumberParser.toDouble(json['amount']),
    );
  }
}

class DashboardOrder {
  const DashboardOrder({
    required this.id,
    required this.orderNo,
    required this.userId,
    required this.status,
    required this.statusName,
    required this.payAmount,
  });

  final String id;
  final String orderNo;
  final String userId;
  final int status;
  final String statusName;
  final double payAmount;

  factory DashboardOrder.fromJson(Map<String, dynamic> json) {
    return DashboardOrder(
      id: json['id']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: NumberParser.toInt(json['status']),
      statusName: json['statusName']?.toString() ?? '',
      payAmount: NumberParser.toDouble(json['payAmount']),
    );
  }
}
