import 'package:provider/provider.dart';
import 'package:selfhelper/vm/bottom_nav_index_vm.dart';
import 'package:selfhelper/vm/chosen_path_viewmodel.dart';
import 'package:selfhelper/model/models.dart' as model;
import 'package:flutter/material.dart';

/// The dialog shown after user wants to subscribe to a path, allowing
/// user to choose preferences.
/// This is lots of boilerplate code.
class ChoosePathDialog extends StatefulWidget {
  final model.Path path;

  ChoosePathDialog(this.path) : assert(path != null);

  @override
  _ChoosePathDialogState createState() => _ChoosePathDialogState(path);
}

class _ChoosePathDialogState extends State<ChoosePathDialog> {
  bool sendMorningNotif = true, sendNoonNotif = true, sendEveningNotif = true;
  int oneNotif = 1, twoNotifs = 2, threeNotifs = 3, selectedNotifsPerDay = 3;
  final model.Path path;

  _ChoosePathDialogState(this.path) : assert(path != null);

  @override
  Widget build(BuildContext context) {
    BottomNav bottomNav = Provider.of<BottomNav>(context);
    return AlertDialog(
      title: Text('How Many Reminders Do You Wish To Receive?',
          style: TextStyle(color: Colors.black)),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Your attention is the most precious thing you have."
                " Please choose when you don't want to receive reminders.\n",
            style: TextStyle(color: Colors.black),
          ),
          Text("How many reminders do you wish to receive at most per day?",
              style: TextStyle(color: Colors.black)),
          Row(
            children: [
              Expanded(
                child: RadioListTile(
                  title: Text("1", style: TextStyle(color: Colors.black)),
                  groupValue: selectedNotifsPerDay,
                  value: oneNotif,
                  onChanged: (int newVal) => setState(() {
                    selectedNotifsPerDay = newVal;
                  }),
                ),
              ),
              Expanded(
                child: RadioListTile(
                  title: Text("2", style: TextStyle(color: Colors.black)),
                  groupValue: selectedNotifsPerDay,
                  value: twoNotifs,
                  onChanged: (int newVal) => setState(() {
                    selectedNotifsPerDay = newVal;
                  }),
                ),
              ),
              Expanded(
                child: RadioListTile(
                  title: Text("3", style: TextStyle(color: Colors.black)),
                  groupValue: selectedNotifsPerDay,
                  value: threeNotifs,
                  onChanged: (int newVal) => setState(() {
                    selectedNotifsPerDay = newVal;
                  }),
                ),
              ),
            ],
          ),
          Text("At what time do you wish to receive reminders?",
              style: TextStyle(color: Colors.black)),
          CheckboxListTile(
            title:
            Text("After waking up", style: TextStyle(color: Colors.black)),
            value: sendMorningNotif,
            onChanged: (bool newVal) => setState(() {
              sendMorningNotif = newVal;
            }),
          ),
          CheckboxListTile(
            title: Text("Around midday", style: TextStyle(color: Colors.black)),
            value: sendNoonNotif,
            onChanged: (bool newVal) => setState(() {
              sendNoonNotif = newVal;
            }),
          ),
          CheckboxListTile(
            title: Text("Before bed", style: TextStyle(color: Colors.black)),
            value: sendEveningNotif,
            onChanged: (bool newVal) => setState(() {
              sendEveningNotif = newVal;
            }),
          ),
        ],
      ),
      actions: [
        FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(color: Colors.black))),
        FlatButton(
            onPressed: () {
              ChosenPath chosenPath =
              Provider.of<ChosenPath>(context, listen: false);
              chosenPath.updateChosenPath(path.uid, path.id, sendMorningNotif,
                  sendNoonNotif, sendEveningNotif, selectedNotifsPerDay);
              Navigator.pop(context);
              Navigator.pop(context);
              bottomNav.index = 0; // first screen, i.e. 'Your Path'
            },
            child: Text('Proceed with Path',
                style: TextStyle(color: Colors.black)))
      ],
    );
  }
}

/// The Button to subscribe to one path, shown in a preview path
class PathChoosingBtn extends StatelessWidget {
  final model.Path path;

  PathChoosingBtn(this.path) : assert(path != null);

  @override
  Widget build(BuildContext context) {
    ChosenPath chosenPath = Provider.of<ChosenPath>(context);
    return FutureBuilder<model.Path>(
      future: chosenPath.chosenPath,
      builder: (context, snapshot) => !snapshot.hasData
          ? Center(child:CircularProgressIndicator())
          : Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: RaisedButton(
              elevation: 8,
              onPressed: snapshot.data.id == path.id ? null :  () {
                showDialog(
                  context: context,
                  builder:  (_) => ChoosePathDialog(path),
                );
              },
              child: Text(
                'Follow Path',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )),
    );
  }
}