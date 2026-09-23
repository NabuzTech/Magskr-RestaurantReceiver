class GetStoreConfigModel {
  int? storeId;
  String? domain;
  String? subdomain;
  String? appName;
  String? appBaseRoute;
  String? copyrightText;
  dynamic footer;
  String? language;
  String? country;
  String? paypalLiveClientId;
  bool? useDistanceDelivery;
  dynamic metadata;

  GetStoreConfigModel(
      {this.storeId,
        this.domain,
        this.subdomain,
        this.appName,
        this.appBaseRoute,
        this.copyrightText,
        this.footer,
        this.language,
        this.country,
        this.paypalLiveClientId,
        this.useDistanceDelivery,
        this.metadata});

  GetStoreConfigModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    domain = json['domain'];
    subdomain = json['subdomain'];
    appName = json['app_name'];
    appBaseRoute = json['app_base_route'];
    copyrightText = json['copyright_text'];
    footer = json['footer'];
    language = json['language'];
    country = json['country'];
    paypalLiveClientId = json['paypal_live_client_id'];
    useDistanceDelivery = json['use_distance_delivery'];
    metadata = json['metadata'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['domain'] = this.domain;
    data['subdomain'] = this.subdomain;
    data['app_name'] = this.appName;
    data['app_base_route'] = this.appBaseRoute;
    data['copyright_text'] = this.copyrightText;
    data['footer'] = this.footer;
    data['language'] = this.language;
    data['country'] = this.country;
    data['paypal_live_client_id'] = this.paypalLiveClientId;
    data['use_distance_delivery'] = this.useDistanceDelivery;
    data['metadata'] = this.metadata;
    return data;
  }
}
