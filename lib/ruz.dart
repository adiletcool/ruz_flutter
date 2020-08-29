import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'constants.dart';

Future<List> getGroupSuggestion(String group) async {
  final String url = 'https://ruz.hse.ru/api/search?term=$group&type=group';
  final response = await http.Client().get(url);
  return json.decode(response.body);
}

Future<List> getStudentNameSuggestion(String name) async {
  final String url = 'https://ruz.hse.ru/api/search?term=$name&type=student';
  final response = await http.Client().get(url);
  return json.decode(response.body);
}

Future<List> getSchedule(
    {@required String type, ruzId, startDate, endDate, lng = 1}) async {
  final String baseUrl = 'ruz.hse.ru';
  if (ruzId != '') {
    Map<String, String> qParams = {
      'start': '$startDate', // yyyy.mm.dd
      'finish': '$endDate', // yyyy.mm.dd
      'lng': '$lng', // 1 - RU, 2 - EN
    };
    var uri = Uri.https(baseUrl, '/api/schedule/$type/$ruzId', qParams);
    print(uri);
    var response = await http.get(uri);
    return json.decode(response.body);
  } else
    return [];
}

Future getSubjectURL(disciplineinplan) async {
  var url =
      'https://www.hse.ru/api/timetable/proposal-items?ptm=$disciplineinplan&locale=ru';
  var resp = await http.get(url);
  return json.decode(resp.body);
}

Future<List<Appointment>> getAppointmentsByGroup(
    {@required String type, ruzId, startDate, endDate}) async {
  List groupSchedule = await getSchedule(
      type: type, ruzId: ruzId, startDate: startDate, endDate: endDate);

  List<Appointment> mySchedule = List.generate(groupSchedule.length, (index) {
    var date = groupSchedule[index]['date'];
    var beginTime = groupSchedule[index]['beginLesson'];
    var endTime = groupSchedule[index]['endLesson'];
    String discipline = groupSchedule[index]['discipline'];
    String lessonType = groupSchedule[index]['kindOfWork'];
    var auditorium = groupSchedule[index]['auditorium'];
    String location = groupSchedule[index]['building'];
    String teacher = groupSchedule[index]['lecturer'];
    var appColor = getAppointmentColor(lessonType);
    String disciplineId = groupSchedule[index]['disciplineinplan'];

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

Future<List<Appointment>> getAppointmentsByName(
  studentId,
  startDate,
  endDates,
) async {
  return null;
}
