class GetStoreThemeModel {
  Colors? colors;
  Coupons? coupons;
  int? storeId;

  GetStoreThemeModel({this.colors, this.coupons, this.storeId});

  GetStoreThemeModel.fromJson(Map<String, dynamic> json) {
    colors =
    json['colors'] != null ? new Colors.fromJson(json['colors']) : null;
    coupons =
    json['coupons'] != null ? new Coupons.fromJson(json['coupons']) : null;
    storeId = json['store_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.colors != null) {
      data['colors'] = this.colors!.toJson();
    }
    if (this.coupons != null) {
      data['coupons'] = this.coupons!.toJson();
    }
    data['store_id'] = this.storeId;
    return data;
  }
}

class Colors {
  String? primary;
  String? secondary;
  String? accent;
  String? background;
  String? surface;
  String? text;
  String? textSecondary;
  String? icons;
  String? border;

  Colors(
      {this.primary,
        this.secondary,
        this.accent,
        this.background,
        this.surface,
        this.text,
        this.textSecondary,
        this.icons,
        this.border});

  Colors.fromJson(Map<String, dynamic> json) {
    primary = json['primary'];
    secondary = json['secondary'];
    accent = json['accent'];
    background = json['background'];
    surface = json['surface'];
    text = json['text'];
    textSecondary = json['text-secondary'];
    icons = json['icons'];
    border = json['border'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['primary'] = this.primary;
    data['secondary'] = this.secondary;
    data['accent'] = this.accent;
    data['background'] = this.background;
    data['surface'] = this.surface;
    data['text'] = this.text;
    data['text-secondary'] = this.textSecondary;
    data['icons'] = this.icons;
    data['border'] = this.border;
    return data;
  }
}

class Coupons {
  Percent? percent;
  Percent? amount;
  Percent? delivery;

  Coupons({this.percent, this.amount, this.delivery});

  Coupons.fromJson(Map<String, dynamic> json) {
    percent =
    json['percent'] != null ? new Percent.fromJson(json['percent']) : null;
    amount =
    json['amount'] != null ? new Percent.fromJson(json['amount']) : null;
    delivery = json['delivery'] != null
        ? new Percent.fromJson(json['delivery'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.percent != null) {
      data['percent'] = this.percent!.toJson();
    }
    if (this.amount != null) {
      data['amount'] = this.amount!.toJson();
    }
    if (this.delivery != null) {
      data['delivery'] = this.delivery!.toJson();
    }
    return data;
  }
}

class Percent {
  String? bg;
  String? text;
  String? subtext;

  Percent({this.bg, this.text, this.subtext});

  Percent.fromJson(Map<String, dynamic> json) {
    bg = json['bg'];
    text = json['text'];
    subtext = json['subtext'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bg'] = this.bg;
    data['text'] = this.text;
    data['subtext'] = this.subtext;
    return data;
  }
}
