import 'package:chat/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:chat/platform_adaptive.dart';
import 'package:flutter/material.dart';
import 'package:chat/models/message.dart';
import 'package:chat/pages/edit_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  FirebaseUser _user;
  ChatScreen(this._user);
  @override
  _ChatScreenState createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  // List<Message> _messages = [];
  Firestore _db = Firestore.instance;
  User _profile;
  TextEditingController _textController = TextEditingController();
  bool _isComposing = false;

  @override
  initState() {
    super.initState();
    _db.collection('users').where("uid", isEqualTo: widget._user.uid).snapshots()
      .listen((data) {
        data.documents.forEach((document) {
          setState(() {
            _profile = User.fromSnapshot(document);
          });
        });
      });
  }

  void _handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(widget._user)),
    );
  }

  void _handlePhotoButtonPressed() {
    print("photo button pressed");
  }
  
  Future<Message> _handleSubmitted(String text) async {
    _textController.clear();

    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(_db.collection('chats').document('UAluilBWI4V129M2z8YX').collection('history').document());
  
      var dataMap = new Map<String, dynamic>();
      dataMap['sender'] = _profile.name;
      dataMap['text'] = text;
      dataMap['timestamp'] = DateTime.now();
  
      await tx.set(ds.reference, dataMap);
  
      return dataMap;
    };
  
    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return Message.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }
  
  void _handleMessageChanged(String text) {
    print("message changed");
    setState(() {
      _isComposing = text.length > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_profile?.name ?? "Chat"}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () => _handleEditProfile()
            )
        ]),
        body: Column(children: [
            Flexible(
                child: _buildChatList(context),
            ),
            Divider(height: 1.0),
            Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer()),
        ]));
  }

  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(color: Theme.of(context).accentColor),
        child: PlatformAdaptiveContainer(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child: IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _handlePhotoButtonPressed,
                ),
              ),
              Flexible(
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  onChanged: _handleMessageChanged,
                  decoration:
                      InputDecoration.collapsed(hintText: 'Send a message'),
                ),
              ),
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  child: PlatformAdaptiveButton(
                    icon: Icon(Icons.send),
                    onPressed: _isComposing
                        ? () => _handleSubmitted(_textController.text)
                        : null,
                    child: Text('Send'),
                  )),
            ])));
  }
 
  Widget _buildChatList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('chats').document('UAluilBWI4V129M2z8YX').collection('history').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return ListView(
          padding: const EdgeInsets.only(top: 20.0),
          children: snapshot.data.documents.map((data) => _buildListItem(context, data)).toList(),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final message = Message.fromSnapshot(data);
    return Padding(
      key: ValueKey(message.timestamp),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(message.sender),
          subtitle: Text(message.text),
          trailing: Text(DateFormat('yyyy').format(message.timestamp).toString()),
          onTap: () => print("clicked"),
        ),
      ),
    );
  }
}
