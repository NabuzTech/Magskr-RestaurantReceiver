import 'dart:async';

class OrderRefreshNotifier {
  static final OrderRefreshNotifier _instance = OrderRefreshNotifier._internal();
  factory OrderRefreshNotifier() => _instance;
  OrderRefreshNotifier._internal();

  final _refreshController = StreamController<bool>.broadcast();

  Stream<bool> get refreshStream => _refreshController.stream;

  void notifyRefresh() {
    print('📢 Notifying OrderScreen to refresh local orders');
    _refreshController.add(true);
  }

  void dispose() {
    _refreshController.close();
  }
}