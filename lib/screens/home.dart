import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Color primaryColor = Colors.blueAccent;

  final _todoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastItem;
  int _lastItemPos;

  void _addTodo() {
    Map<String, dynamic> newTodo = Map();
    newTodo["ok"] = false;
    newTodo["title"] = _todoController.text;
    _todoController.text = '';
    setState(() {
      _toDoList.insert(0, newTodo);
      _saveData();
    });
  }

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Lista de Tarefas'),
          backgroundColor: primaryColor,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                          labelText: 'Nova Tarefa',
                          labelStyle: TextStyle(color: primaryColor)),
                    ),
                  ),
                  RaisedButton(
                    onPressed: _addTodo,
                    child: Text("ADD"),
                    textColor: Colors.white,
                    color: primaryColor,
                  )
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10),
                    itemCount: _toDoList.length,
                    itemBuilder: _buildItemList),
              ),
            )
          ],
        ));
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  Widget _buildItemList(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecond.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        onChanged: (bool value) {
          setState(() {
            _toDoList[index]["ok"] = value;
            _saveData();
          });
        },
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastItem = Map.from(_toDoList[index]);
          _lastItemPos = index;
          _toDoList.removeAt(index);
          _saveData();
        });

        final snack = SnackBar(
          content: Text("Tarefa \"${_lastItem['title']}\" removida!"),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              setState(() {
                _toDoList.insert(_lastItemPos, _lastItem);
                _saveData();
              });
            },
          ),
          duration: Duration(seconds: 3),
        );

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      print(e);
      return null;
    }
  }
}
