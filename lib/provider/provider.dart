import 'package:flutter/cupertino.dart';

class Management with ChangeNotifier {
  int _balance = 0;

  int get balance => _balance;

  void setBalance(int value){
    _balance = value;

    notifyListeners();
  }

  String _address = "";
  String _nodeId = "";

  String get address => _address;
  String get nodeId => _nodeId;

  void setAddressId(String ad, String id){
    _address = ad;
    _nodeId = id;
    notifyListeners();
  }
}