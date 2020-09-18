import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString, {double opacity}) {
    final buffer = StringBuffer();
    opacity ??= 1;
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16)).withOpacity(opacity);
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

extension HomeDrawerIcon on Icon {
  static Icon icon(IconData icon) {
    return Icon(icon, color: Colors.white, size: 18);
  }
}

String licenseKey =
    'NT8mJyc2IWhia31hfWN9Z2doYmF8YGJ8ampqanNiYmlmamlmanMDHmgyNzo/NicwPDw/YhM0PjI6P30wPD4=';
TextStyle mainStyle = TextStyle(fontFamily: 'PTRootUI');
TextStyle dateStyle = mainStyle.copyWith(color: Colors.black, fontSize: 24);
TextStyle monthStyle = mainStyle.copyWith(fontSize: 30);
TextStyle headerStyle =
    dateStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 2);
TextStyle timeTextStyle = mainStyle.copyWith(color: Colors.black54);
TextStyle dateTextStyle =
    mainStyle.copyWith(color: Colors.black, fontWeight: FontWeight.w600);
TextStyle drawerTextStyle = mainStyle.copyWith(
    fontSize: 22, color: Colors.white, fontWeight: FontWeight.w300);
TextStyle settingsTextStyle = mainStyle.copyWith(
    fontSize: 18, color: Colors.white, fontWeight: FontWeight.w300);
TextStyle searchTextStyle =
    mainStyle.copyWith(fontSize: 18, color: Colors.black);
TextStyle settingsMidRowStyle = mainStyle.copyWith(fontSize: 16);
TextStyle homeDrawerTextStyle =
    drawerTextStyle.copyWith(fontSize: 18, height: .7);
TextStyle dlinesDDTextStyle =
    mainStyle.copyWith(fontSize: 18, color: Colors.black);

void saveSettings(
  String selectedType,
  String selectedGroupName,
  String selectedGroupId,
  String selectedStudentName,
  String selectedStudentId,
) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  prefs.setString('selectedType', selectedType);
  prefs.setString('selectedGroupName', selectedGroupName);
  prefs.setString('selectedGroupId', selectedGroupId);
  prefs.setString('selectedStudentName', selectedStudentName);
  prefs.setString('selectedStudentId', selectedStudentId);

  print('Settings were saved.');
}

Future<Map<String, String>> getSettings() async {
  Map<String, String> settings = {};
  SharedPreferences prefs = await SharedPreferences.getInstance();

  for (var value in [
    'selectedType',
    'selectedGroupName',
    'selectedGroupId',
    'selectedStudentName',
    'selectedStudentId'
  ]) {
    settings[value] = prefs.getString(value);
  }
  return settings;
}

Color getAppointmentColor(lessonType) {
  lessonType ??= '';
  return ['лекция', 'lecture'].contains(lessonType.toLowerCase())
      ? HexColor.fromHex('#2d767f')
      : HexColor.fromHex('#1a2639');
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

Map<String, Icon> searchIcons = {
  'group': Icon(MdiIcons.accountGroup, color: Colors.black),
  'name': Icon(MdiIcons.account, color: Colors.black),
  'lecturer': Icon(MdiIcons.teach, color: Colors.black),
  'auditorium': Icon(Icons.room, color: Colors.black),
};

void goBackHome(BuildContext context) {
  Navigator.pushNamed(context, 'HomePage');
}

const kDbFileName = 'deadlines.db';
const kDbTableName = 'main';
