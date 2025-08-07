import 'package:flutter/cupertino.dart';

class Management with ChangeNotifier {
  int _balance = 0;

  int get balance => _balance;

  void setBalance(int value){
    _balance = value;

    notifyListeners();
  }
}