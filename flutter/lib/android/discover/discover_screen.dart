import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selfhelper/android/discover/newest_paths.dart';


/// the screen where user can explore new paths
class DiscoverScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return ListView(
      children: [
        NewestPaths(),
      ],
    );
  }
}