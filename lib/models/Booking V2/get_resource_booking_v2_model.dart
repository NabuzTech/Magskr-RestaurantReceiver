class GetResourceBookingV2Model {
  int? id;
  int? storeId;
  String? name;
  int? capacity;
  String? capacityMode;
  bool? isActive;
  int? sortOrder;

  GetResourceBookingV2Model(
      {this.id,
        this.storeId,
        this.name,
        this.capacity,
        this.capacityMode,
        this.isActive,
        this.sortOrder});

  GetResourceBookingV2Model.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    name = json['name'];
    capacity = json['capacity'];
    capacityMode = json['capacity_mode'];
    isActive = json['is_active'];
    sortOrder = json['sort_order'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['store_id'] = this.storeId;
    data['name'] = this.name;
    data['capacity'] = this.capacity;
    data['capacity_mode'] = this.capacityMode;
    data['is_active'] = this.isActive;
    data['sort_order'] = this.sortOrder;
    return data;
  }
}