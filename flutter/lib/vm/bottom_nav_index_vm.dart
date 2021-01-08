import 'package:flutter/material.dart';

/// this contains the index for the bottom navigation bar shown.
/// 
/// When a path is chosen, the index is switched to the 'your path'
/// screen.
class BottomNav with ChangeNotifier {
  int _index = 0;
  
  int get index => _index;
  set index(int index) {
    _index = index;
    notifyListeners();
  }
  
}