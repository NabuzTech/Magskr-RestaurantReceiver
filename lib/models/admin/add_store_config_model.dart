class AddStoreConfigModel {
  int? id;
  String? domain;
  String? subdomain;
  int? storeId;
  String? appName;
  String? appBaseRoute;
  String? copyrightText;
  List<Footer>? footer;
  String? language;

  AddStoreConfigModel(
      {this.id,
        this.domain,
        this.subdomain,
        this.storeId,
        this.appName,
        this.appBaseRoute,
        this.copyrightText,
        this.footer,
        this.language});

  AddStoreConfigModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    domain = json['domain'];
    subdomain = json['subdomain'];
    storeId = json['store_id'];
    appName = json['app_name'];
    appBaseRoute = json['app_base_route'];
    copyrightText = json['copyright_text'];
    if (json['footer'] != null) {
      footer = <Footer>[];
      json['footer'].forEach((v) {
        footer!.add(new Footer.fromJson(v));
      });
    }
    language = json['language'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['domain'] = this.domain;
    data['subdomain'] = this.subdomain;
    data['store_id'] = this.storeId;
    data['app_name'] = this.appName;
    data['app_base_route'] = this.appBaseRoute;
    data['copyright_text'] = this.copyrightText;
    if (this.footer != null) {
      data['footer'] = this.footer!.map((v) => v.toJson()).toList();
    }
    data['language'] = this.language;
    return data;
  }
}

class Footer {
  String? label;
  String? link;

  Footer({this.label, this.link});

  Footer.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = this.label;
    data['link'] = this.link;
    return data;
  }
}
