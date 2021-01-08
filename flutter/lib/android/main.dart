import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selfhelper/android/bottom_nav_scaffold.dart';
import 'package:selfhelper/vm/bottom_nav_index_vm.dart';
import 'package:selfhelper/vm/chosen_path_viewmodel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // theme may be accessed outside of the context scope, e.g. when the
  // widgets are prebuild within a class, so its saved as static
  static final ThemeData theme = ThemeData(
    colorScheme: ColorScheme(
      primary: Color.fromARGB(255, 37, 37, 37),
      primaryVariant: Color.fromARGB(255, 230, 230, 230),
      secondary: Color.fromARGB(255, 250, 226, 18),
      secondaryVariant: Color.fromARGB(255, 253, 240, 147),
      surface: Colors.white,
      background: Colors.white,
      error: Color.fromARGB(255, 176, 0, 32),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    primaryColor: Color.fromARGB(255, 37, 37, 37),
    brightness: Brightness.light,
    accentColor: Color.fromARGB(255, 37, 37, 37),
    buttonTheme: ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
      padding: EdgeInsets.all(16),
      splashColor: Color.fromARGB(255, 250, 226, 18),
      buttonColor: Color.fromARGB(255, 37, 37, 37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      clipBehavior: Clip.antiAlias,
    ),
    textTheme: TextTheme(
        headline4: TextStyle(
          // path screen title
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
        headline5: TextStyle(
          // yellow underlined main headline
          fontSize: 34,
          fontWeight: FontWeight.w700,
          textBaseline: TextBaseline.alphabetic,
          letterSpacing: -0.7,
          color: Colors.black87,
        ),
        headline6: TextStyle(
          // card headline
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.4,
          wordSpacing: 0.5,
        ),
        subtitle1: TextStyle(
          // card subtitle
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: Colors.white,
          letterSpacing: 0.3,
          wordSpacing: 0.3,
        ),
        bodyText2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.1,
          wordSpacing: 0.1,
        ),
        button: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        )),
  );
  static const String _title = 'Flutter Demo';
  static final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChosenPath>(
          lazy: false,
          create: (_) => ChosenPath(),
        ),
        ChangeNotifierProvider<BottomNav>(
          lazy: false,
          create: (_) => BottomNav(),
        )
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: _title,
        theme: theme,
        home: BottomNavScaffold(),
      ),
    );
  }
}
