import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'HexColor.dart';

Future<List> getGroupSuggestion(String group) async {
  final String url = 'https://ruz.hse.ru/api/search?term=$group&type=group';
  final response = await http.Client().get(url);
  return json.decode(response.body);
}

Future<List> getGroupSchedule({groupId, startDate, endDate, lng = 1}) async {
  final String baseUrl = 'ruz.hse.ru';

  Map<String, String> qParams = {
    'start': '$startDate', // yyyy.mm.dd
    'finish': '$endDate', // yyyy.mm.dd
    'lng': '$lng', // 1 - RU, 2 - EN
  };
  var uri = Uri.https(baseUrl, '/api/schedule/group/$groupId', qParams);
  var response = await http.get(uri);
  return json.decode(response.body);
}

Future<List<Appointment>> getAppointments({groupId, startDate, endDate}) async {
  List groupSchedule = await getGroupSchedule(
      groupId: groupId, startDate: startDate, endDate: endDate);

  List<Appointment> mySchedule = List.generate(groupSchedule.length, (index) {
    var date = groupSchedule[index]['date'];
    var beginTime = groupSchedule[index]['beginLesson'];
    var endTime = groupSchedule[index]['endLesson'];
    var discipline = groupSchedule[index]['discipline'];
    var lessonType = groupSchedule[index]['kindOfWork'];
    var auditorium = groupSchedule[index]['auditorium'];
    var location = groupSchedule[index]['building'];
    var teacher = groupSchedule[index]['lecturer'];

    return Appointment(
        color: HexColor.fromHex('#346E86'),
        startTime: DateFormat("yyyy.MM.dd HH:mm").parse('$date $beginTime'),
        endTime: DateFormat("yyyy.MM.dd HH:mm").parse('$date $endTime'),
        subject: '$discipline, $lessonType',
        notes: 'Адрес: $location\n$teacher',
        location: auditorium);
  });
  return mySchedule;
}
