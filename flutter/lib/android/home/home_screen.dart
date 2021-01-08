import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selfhelper/android/path/path_screen.dart';
import 'package:selfhelper/vm/chosen_path_viewmodel.dart';


/// the screen of the chosen path, i.e. the path where the user
/// wants to see the full content, not the preview.
class MyPathScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Provider.of<ChosenPath>(context).chosenPath,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return CircularProgressIndicator();
          if (!snapshot.hasData)
            return Text('Go and find some wisdom in the explore tab!');
          return PathScreen(snapshot.data, isChosenOne: true);
        });
  }
}
