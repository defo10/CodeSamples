import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selfhelper/android/discover/discover_screen.dart';
import 'package:selfhelper/android/home/home_screen.dart';
import 'package:selfhelper/vm/bottom_nav_index_vm.dart';

/// A [Scaffold] with a bottom navigation bar.
///
/// This is the main widget of the app, present in all main screens
class BottomNavScaffold extends StatelessWidget {
  final List<Widget> _screens = <Widget>[
    MyPathScreen(),
    DiscoverScreen(),
    Container(), // removed for sample
  ];

  @override
  Widget build(BuildContext context) {
    BottomNav btmNav = Provider.of<BottomNav>(context);

    return Scaffold(
      body: PageTransitionSwitcher(
          transitionBuilder: (Widget child, Animation<double> primaryAnimation,
              Animation<double> secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: Container(
            key: ValueKey<int>(btmNav.index),
            child: _screens[btmNav.index],
          )),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_upward),
            label: 'Your Path',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          )
        ],
        currentIndex: btmNav.index,
        onTap: (int i) => btmNav.index = i,
        selectedFontSize: 12,
        selectedItemColor: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }
}
