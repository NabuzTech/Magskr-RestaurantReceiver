import 'package:hive/hive.dart';


@HiveType(typeId: 27)
class UserModelH extends HiveObject {
  @HiveField(0)
  String? sessionid;
  @HiveField(1)
  int? userid;
  @HiveField(2)
  String? first_name;
  @HiveField(3)
  String? LastName;
  @HiveField(4)
  String? email;
  @HiveField(5)
  String? Icon;


  UserModelH(
      {this.sessionid,
      this.userid,
      this.first_name,
      this.LastName,
      this.email,
      this.Icon,
   });

  factory UserModelH.fromJson(Map<String, dynamic> json) {
    return UserModelH(
      sessionid: json['SessionID'],
      userid: json['UserID'],
      first_name: json['FirstName'],
      LastName: json['LastName'],
      email: json['Email'],
      Icon: json['Icon'],
    );
  }
}
