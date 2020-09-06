import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future getSubjectURL(disciplineinplan) async {
  var url =
      'https://www.hse.ru/api/timetable/proposal-items?ptm=$disciplineinplan&locale=ru';
  var resp = await http.get(url);
  return json.decode(resp.body);
}

Future<List> getSearchSuggestion({String query, String type}) async {
  final String url = 'https://ruz.hse.ru/api/search?term=$query&type=$type';
  final response = await http.Client().get(url);
  return json.decode(response.body);
}

Future<List> getSchedule(
    {@required String type, ruzId, startDate, endDate, lng = 1}) async {
  final String baseUrl = 'ruz.hse.ru';
  if (ruzId != '') {
    try {
      Map<String, String> qParams = {
        'start': '$startDate', // yyyy.mm.dd
        'finish': '$endDate', // yyyy.mm.dd
        'lng': '$lng', // 1 - RU, 2 - EN
      };
      var uri = Uri.https(baseUrl, '/api/schedule/$type/$ruzId', qParams);
      print('Request: $uri');
      var response = await http.get(uri);
      return json.decode(response.body);
    } on SocketException catch (error) {
      return [error];
    }
  } else
    return [];
}

Future<List<Appointment>> getAppointments({@required List scheduleJson}) async {
  List<String> saveData = [];

  List<Appointment> mySchedule = List.generate(scheduleJson.length, (index) {
    var date = scheduleJson[index]['date'];
    var beginLesson = scheduleJson[index]['beginLesson'];
    var endLesson = scheduleJson[index]['endLesson'];
    String discipline = scheduleJson[index]['discipline'];
    String kindOfWork = scheduleJson[index]['kindOfWork'];
    var auditorium = scheduleJson[index]['auditorium'];
    String building = scheduleJson[index]['building'];
    String lecturer = scheduleJson[index]['lecturer'];
    var appColor = getAppointmentColor(kindOfWork);
    String disciplineinplan = scheduleJson[index]['disciplineinplan'];
    String url1 = scheduleJson[index]['url1'];
    String group = scheduleJson[index]['group'];

    String notesEnc = json.encode({
      'date': date,
      'beginLesson': beginLesson,
      'endLesson': endLesson,
      'discipline': discipline,
      'kindOfWork': kindOfWork,
      'auditorium': auditorium,
      'building': building,
      'lecturer': lecturer,
      'disciplineinplan': disciplineinplan,
      'url1': url1,
      'group': group,
    });

    saveData.add(notesEnc);

    return Appointment(
        color: appColor,
        startTime: DateFormat("yyyy.MM.dd HH:mm").parse('$date $beginLesson'),
        endTime: DateFormat("yyyy.MM.dd HH:mm").parse('$date $endLesson'),
        subject: '$discipline, $kindOfWork',
        notes: notesEnc);
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('offlineData', saveData); // do I need await here?
  print('saved');

  return mySchedule;
}
