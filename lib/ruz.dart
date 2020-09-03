import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'constants.dart';

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
  print(scheduleJson[0]);
  List<Appointment> mySchedule = List.generate(scheduleJson.length, (index) {
    var date = scheduleJson[index]['date'];
    var beginTime = scheduleJson[index]['beginLesson'];
    var endTime = scheduleJson[index]['endLesson'];
    String discipline = scheduleJson[index]['discipline'];
    String lessonType = scheduleJson[index]['kindOfWork'];
    var auditorium = scheduleJson[index]['auditorium'];
    String location = scheduleJson[index]['building'];
    String teacher = scheduleJson[index]['lecturer'];
    var appColor = getAppointmentColor(lessonType);
    String disciplineId = scheduleJson[index]['disciplineinplan'];
    String onlineUrl = scheduleJson[index]['url1'];

    String notesEnc = json.encode({
      'date': date,
      'beginTime': beginTime,
      'endTime': endTime,
      'discipline': discipline,
      'lessonType': lessonType,
      'auditorium': auditorium,
      'location': location,
      'teacher': teacher,
      'disciplineId': disciplineId,
      'url1': onlineUrl
    });

    return Appointment(
        color: appColor,
        startTime: DateFormat("yyyy.MM.dd HH:mm").parse('$date $beginTime'),
        endTime: DateFormat("yyyy.MM.dd HH:mm").parse('$date $endTime'),
        subject: '$discipline, $lessonType',
        notes: notesEnc);
  });
  return mySchedule;
}
