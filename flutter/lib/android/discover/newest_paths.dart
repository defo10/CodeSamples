import 'package:flutter/material.dart';
import 'package:selfhelper/android/path/snippet_path.dart';
import 'package:selfhelper/android/texts.dart';
import 'package:selfhelper/model/db.dart';
import 'package:selfhelper/model/models.dart' as model;

/// Wdget showing a list of path snippets
class ListOfPaths extends StatelessWidget {
  final List<model.Path> paths;

  ListOfPaths(this.paths);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (model.Path path in paths) Snippet(path),
      ],
    );
  }
}

/// Widget that fetches the newest paths and shows appropriate content
/// while waiting.
class NewPathsLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return (FutureBuilder(
      future: DatabaseService().getNewestPaths(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error.toString());
          return Icon(Icons.error);
        }
        if (snapshot.connectionState == ConnectionState.waiting)
          return CircularProgressIndicator(
            backgroundColor: Theme.of(context).primaryColor,
          );
        return ListOfPaths(snapshot.data);
      },
    ));
  }
}

/// The newest paths section in the explore tab
class NewestPaths extends StatelessWidget {
  @override
  Widget build(BuildContext context) => (Column(
        children: [
          Headline('Newcomers', 170),
          NewPathsLoader(),
        ],
      ));
}
