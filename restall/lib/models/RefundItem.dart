import 'package:restall/models/Order.dart';
import 'package:restall/models/ReturnRequest.dart';

enum RefundItemType { order, returnRequest }

class RefundItem {
  final RefundItemType type;
  final Order? order;
  final ReturnRequest? request;

  RefundItem._({required this.type, this.order, this.request});

  factory RefundItem.fromOrder(Order order) {
    return RefundItem._(type: RefundItemType.order, order: order);
  }

  factory RefundItem.fromRequest(ReturnRequest request) {
    return RefundItem._(type: RefundItemType.returnRequest, request: request);
  }

  /// Date string used for sorting
  String get dateString {
    if (type == RefundItemType.order) return order?.dateCreated ?? '';
    return request?.createdAt ?? '';
  }
}
