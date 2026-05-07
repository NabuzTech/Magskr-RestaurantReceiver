


validateName(String? name) {
  if (name == null || name.isEmpty) {
    return "Please enter Name.";
  } else {
    return null;
  }
}

validateLastName(String? name) {
  if (name == null || name.isEmpty) {
    return "Please enter Surame.";
  } else {
    return null;
  }
}

bool validateAddress(String? name) {
  if (name!.length < 5) {
    return false;
  }
  return true;
}

bool validateEmail(String? email) {
  RegExp regex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  if (!regex.hasMatch(email!)) {
    return false;
  } else {
    return true;
  }
}

String? emailValidate(String? email) {
  RegExp regex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  if (!regex.hasMatch(email!)) {
    return 'Enter valid email';
  } else {
    return null;
  }
}

String? validatePassword(String? name) {
  if (name!.length < 6) {
    return 'Password must be greater than 6 characters';
  }
  return null;
}

String? validateDob(String name) {
  if (name.length < 10) {
    return 'Enter valid DOB';
  }
  return null;
}

bool validatePhoneNumber(String? phone) {
  if (phone!.length == 10) {
    return true;
  }
  return false;
}

String? validateQuantity(String quantity) {
  if (quantity.isEmpty) {
    return 'Enter a value';
  }
  return null;
}

//(**************************************)

String? validateFieldForValue(String name) {
  if (name.isEmpty) {
    return "Please enter input.";
  } else if (name.isEmpty) {
    return 'Enter valid input';
  }
  return null;
}

String? validateFieldText(String name, String content) {
  if (name.trim().isEmpty) {
    return content;
  } else if (name.isEmpty) {
    return content;
  }
  return null;
}

String? validateFieldCustomText(String name, String content) {
  if (name.trim().isEmpty) {
    return content;
  } else if (name.isEmpty) {
    return content;
  }
  return null;
}

String? validateNull() {
  return null;
}

String validateDate(String name) {
  /* String Date = DateFormat.yMMMd().format(DateTime.parse(name));
  return Date;*/
  /*print("Date Today" + name);
  var inputFormat = DateFormat('yyyy-MM-dd');
  var inputDate = inputFormat.parse(name);
  var outputFormat = DateFormat('MM-dd-yyyy');
  return outputFormat.format(inputDate);*/
  return name;
}

confrimPassword(String? txt, String passowrd) {
  if (txt == null || txt.isEmpty) {
    return "Please enter password.";
  }
  if (passowrd != txt) {
    return "Confirm password should equal Password";
  } else {
    return null;
  }
}

password(String? txt) {
  if (txt == null || txt.isEmpty) {
    return "Please enter password.";
  }
  if (txt.length < 8) {
    return "Password must has 8 characters";
  }
  if (!txt.contains(RegExp(r'[A-Z]'))) {
    return "Password must has uppercase";
  }
  if (!txt.contains(RegExp(r'[0-9]'))) {
    return "Password must has digits";
  }
  if (!txt.contains(RegExp(r'[a-z]'))) {
    return "Password must has lowercase";
  } else {
    return null;
  }
}

emailValidation(String? email) {
  RegExp regex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  if (email == null || email.isEmpty) {
    return "Please enter Email.";
  } else if (!regex.hasMatch(email)) {
    return "Email is not valid!";
  } else
    return null;
}

/*dateTime(int? timestamp) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp!);

  // Format the DateTime object to the desired format
  String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);

  return formattedDate;
}*/
/*
dateOverTime(int? timestamp) {
  print("timeStamp Log " + timestamp.toString());

  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(*//*timestamp! * 1000*//*
      timestamp != 10 ? timestamp! * 1000 : timestamp!);

  // Format the DateTime object to the desired format
  String formattedDate = DateFormat('MM/dd/yyyy \n HH:mm').format(dateTime);

  return formattedDate;
}*/

/*dateShort(int? timestamp) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000);
  String formattedDate = DateFormat('MM-dd-yyyy | hh:mm a').format(date);
  return formattedDate;
}*/

/*convertToTimeStamp(String date) {
  *//* DateFormat dateFormat = DateFormat("MM-dd-yyyy | hh:mm a");
  DateTime dateTime = dateFormat.parse(date);
  int timestamp = (dateTime.millisecondsSinceEpoch / 1000).round();*//*
  // Correct date format based on the input string
  DateFormat dateFormat = DateFormat('MM-dd-yyyy | h:mm a');

  // Parse the date string to a DateTime object
  DateTime dateTime = dateFormat.parse(date);

  // Convert the DateTime object to Unix timestamp in seconds
  int timestamp = (dateTime.millisecondsSinceEpoch / 1000).round();
  print("TimeSpam Data" + timestamp.toString());
  return timestamp;
}*/

currentTimeStamp() {
  DateTime now = DateTime.now();
  int currentTime = (now.millisecondsSinceEpoch / 1000).round();
  return currentTime;
}
/*

Future<String> deviceUDID() async {
  String udid = await FlutterUdid.udid;
  return udid;
}
*/

getSyncingData(String envornment) {
  String data =
      "Synchronizing\n\nPlease wait while your projects are being synchronized with the $envornment environment.\nThis operation may take a few minutes.";

  return data;
}

/*String? findAssignedNameById(int? id) {
  for (var item in app.appController.syncUserList) {
    if (item.ID == id) {
      app.appController.setUserNameData(item.first_name!, item.ID!);
      return item.first_name;
    }
  }
}*/

String getEnvName(String? baseURL) {
  print("RaxarDataBaseURL ${baseURL!}");
  String enviromentType = "";
  if (baseURL.contains("api.raxar.com")) {
    enviromentType = "Production";
  } else if (baseURL.contains("apitest.raxar.com")) {
    enviromentType = "Test";
  } else if (baseURL.contains("apibeta.raxar.com")) {
    enviromentType = "Beta";
  } else if (baseURL.contains("apidev.raxar.com")) {
    enviromentType = "Development";
  } else if (baseURL.contains("apiprep.raxar.com")) {
    enviromentType = "Prep";
  }
  print("RaxarData $enviromentType");
  return enviromentType;
}
