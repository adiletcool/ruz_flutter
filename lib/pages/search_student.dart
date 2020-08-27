import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ruz/constants.dart';

import '../ruz.dart';

class Student {
  final String name;
  final String id;
  const Student(this.name, this.id);

  @override
  String toString() => 'Student(name: $name, id: $id)';
}

class StudentSearch extends SearchDelegate<Student> {
  final Bloc<StudentSearchEvent, StudentSearchState> studentBloc;
  StudentSearch(this.studentBloc);

  @override
  List<Widget> buildActions(BuildContext context) => null;

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: BackButtonIcon(),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    studentBloc.add(StudentSearchEvent(query));

    return BlocBuilder(
        cubit: studentBloc,
        builder: (context, state) {
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return Container(child: Text('Error'));
          }

          return ListView.builder(
            itemCount: state.students.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(MdiIcons.account, color: Colors.black),
                title: Text(state.students[index].name, style: searchTextStyle),
                onTap: () => close(context, state.students[index]),
              );
            },
          );
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container();
}

class StudentSearchEvent {
  final String query;
  const StudentSearchEvent(this.query);
}

class StudentSearchState {
  final bool isLoading;
  final List<Student> students;
  final bool hasError;

  const StudentSearchState({this.isLoading, this.students, this.hasError});

  factory StudentSearchState.initial() {
    return StudentSearchState(students: [], isLoading: false, hasError: false);
  }

  factory StudentSearchState.loading() {
    return StudentSearchState(students: [], isLoading: true, hasError: false);
  }

  factory StudentSearchState.success(List<Student> students) {
    return StudentSearchState(
        students: students, isLoading: false, hasError: false);
  }

  factory StudentSearchState.error() {
    return StudentSearchState(students: [], isLoading: false, hasError: true);
  }
}

class StudentBloc extends Bloc<StudentSearchEvent, StudentSearchState> {
  StudentBloc() : super(StudentSearchState.initial());

  @override
  Stream<StudentSearchState> mapEventToState(StudentSearchEvent event) async* {
    yield StudentSearchState.loading();

    try {
      List<Student> students = await _getSearchResults(event.query);
      yield StudentSearchState.success(students);
    } catch (_) {
      yield StudentSearchState.error();
    }
  }

  Future<List<Student>> _getSearchResults(String query) async {
    var studentsFound = await getStudentNameSuggestion(query);

    List<Student> res = List.generate(studentsFound.length, (index) {
      return Student(studentsFound[index]['label'], studentsFound[index]['id']);
    });

    return res;
  }
}
