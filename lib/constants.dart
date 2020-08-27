import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String licenseKey =
    'NT8mJyc2IWhia31hfWN9Z2doYmF8YGJ8ampqanNiYmlmamlmanMDHmgyNzo/NicwPDw/YhM0PjI6P30wPD4=';
TextStyle mainStyle = TextStyle(fontFamily: 'PTRootUI');
TextStyle dateStyle = mainStyle.copyWith(color: Colors.black, fontSize: 24);
TextStyle monthStyle = mainStyle.copyWith(fontSize: 30);
TextStyle headerStyle =
    dateStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
TextStyle timeTextStyle = mainStyle.copyWith(color: Colors.black54);
TextStyle dateTextStyle =
    mainStyle.copyWith(color: Colors.black, fontWeight: FontWeight.w600);
TextStyle drawerTextStyle = mainStyle.copyWith(
    fontSize: 22, color: Colors.white, fontWeight: FontWeight.w300);
TextStyle settingsTextStyle = mainStyle.copyWith(
    fontSize: 18, color: Colors.white, fontWeight: FontWeight.w300);
TextStyle searchTextStyle =
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
