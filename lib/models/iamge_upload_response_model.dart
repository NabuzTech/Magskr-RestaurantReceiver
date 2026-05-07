class image_upload_response_model {
  String? filename;
  String? url;

  image_upload_response_model({this.filename, this.url});

  image_upload_response_model.fromJson(Map<String, dynamic> json) {
    filename = json['filename'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['filename'] = filename;
    data['url'] = url;
    return data;
  }
}
