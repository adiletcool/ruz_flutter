import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruz/constants.dart';

import '../ruz.dart';

class Obj {
  // Group or Student
  final String name;
  final String id;
  final String description;
  const Obj(this.name, this.id, this.description);

  @override
  String toString() => 'Obj(name: $name, id: $id, description: $description)';
}

class ObjSearch extends SearchDelegate<Obj> {
  final Bloc<ObjSearchEvent, ObjSearchState> objectBloc;
  final String searchType; // group / name

  ObjSearch(this.objectBloc, this.searchType);

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
    objectBloc.add(ObjSearchEvent(query, searchType));

    return BlocBuilder(
        cubit: objectBloc,
        builder: (context, state) {
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return Container(child: Text('Error'));
          }

          return ListView.builder(
            itemCount: state.objects.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: searchIcons[searchType],
                title: Text(state.objects[index].name, style: searchTextStyle),
                subtitle: Text(state.objects[index].description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => close(context, state.objects[index]),
              );
            },
          );
        });
  }

  Future _getSuggestions() async {
    return await getSearchSuggestion(query: query, type: searchType);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if ((searchType == 'name') && (query.length <= 2)) {
      return Container();
    } else {
      return FutureBuilder(
        future: _getSuggestions(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Obj> res = List.generate(snapshot.data.length, (index) {
              return Obj(
                  snapshot.data[index]['label'],
                  snapshot.data[index]['id'],
                  snapshot.data[index]['description']);
            });

            return ListView.builder(
              itemCount: res.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: searchIcons[searchType],
                  title: Text(res[index].name, style: searchTextStyle),
                  subtitle: Text(res[index].description,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => close(context, res[index]),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Container();
          } else {
            return Center(child: Text('Nothing found'));
          }
        },
      );
    }
  }
}

class ObjSearchEvent {
  final String query;
  final String searchType;
  const ObjSearchEvent(this.query, this.searchType);
}

class ObjSearchState {
  final bool isLoading;
  final List<Obj> objects;
  final bool hasError;

  const ObjSearchState({this.isLoading, this.objects, this.hasError});

  factory ObjSearchState.initial() {
    return ObjSearchState(objects: [], isLoading: false, hasError: false);
  }

  factory ObjSearchState.loading() {
    return ObjSearchState(objects: [], isLoading: true, hasError: false);
  }

  factory ObjSearchState.success(List<Obj> objects) {
    return ObjSearchState(objects: objects, isLoading: false, hasError: false);
  }

  factory ObjSearchState.error() {
    return ObjSearchState(objects: [], isLoading: false, hasError: true);
  }
}

class ObjBloc extends Bloc<ObjSearchEvent, ObjSearchState> {
  ObjBloc() : super(ObjSearchState.initial());

  @override
  Stream<ObjSearchState> mapEventToState(ObjSearchEvent event) async* {
    yield ObjSearchState.loading();

    try {
      List<Obj> objects =
          await _getSearchResults(event.query, event.searchType);
      yield ObjSearchState.success(objects);
    } catch (_) {
      yield ObjSearchState.error();
    }
  }

  Future<List<Obj>> _getSearchResults(String query, String searchType) async {
    var suggestions = await getSearchSuggestion(query: query, type: searchType);

    List<Obj> res = List.generate(suggestions.length, (index) {
      return Obj(
        suggestions[index]['label'],
        suggestions[index]['id'],
        suggestions[index]['description'],
      );
    });

    return res;
  }
}
