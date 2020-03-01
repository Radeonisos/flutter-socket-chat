import 'package:flutter/material.dart';
import 'package:flutter_app_chat_websocket/ConnectionPage.dart';
import 'package:flutter_app_chat_websocket/Event.dart';
import 'package:flutter_app_chat_websocket/Socket.dart';

enum InfoType { typing, joined, left }

class ChatPage extends StatefulWidget {
  ChatPage({@required this.userName, @required this.userNumber});

  final String userName;
  final int userNumber;

  ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  Socket _socket = Socket.instance;
  Event _event = Event.instance;

  double widthScreen;
  double heightScreen;

  double topChatHeight = 30;
  double bottomChatHeight = 70;

  List<Widget> _listMesssages = [];
  int _currentUserNumber;

  String _userTyping = "";
  ScrollController _scrollController = new ScrollController();
  TextEditingController _inputMessage = new TextEditingController();

  void computeEvent(GlobalEvent event) {
    setState(() {
      switch (event.flag) {
        case EventFlag.socketUserJoined:
          _currentUserNumber = event.value['numUsers'];
          _listMesssages
              .add(buildInformation(InfoType.joined, event.value['username']));
          break;
        case EventFlag.socketUserLeft:
          _currentUserNumber = event.value['numUsers'];
          _listMesssages
              .add(buildInformation(InfoType.left, event.value['username']));
          break;
        case EventFlag.socketUserNewMessage:
          print(event.value);
          _listMesssages.add(buildMessage(event.value));
          break;
        case EventFlag.socketTyping:
          _userTyping = event.value['username'];
          break;
        case EventFlag.socketStopTyping:
          _userTyping = "";
          break;
        case EventFlag.socketError:
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ConnectionPage(showError: true),
              ));
          break;
        default:
      }
      scrollBottom();
    });
  }

  void scrollBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUserNumber = widget.userNumber;

    _inputMessage.addListener(() {
      if (_inputMessage.text.length > 1) {
        _socket.beginTyping();
        Future.delayed(const Duration(milliseconds: 500), () {
          _socket.stopTyping();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _event.getBus().on<GlobalEvent>().listen(computeEvent);
    });
  }

  Widget buildMessage(data) {
    return Container(
      margin: EdgeInsets.only(bottom: widthScreen * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: widthScreen * 0.015, bottom: 2),
            child: Text(
              data['username'],
              style: TextStyle(color: Colors.black),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            padding: EdgeInsets.symmetric(
                vertical: widthScreen * 0.02, horizontal: widthScreen * 0.04),
            child: Text(
              data['message'],
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInformation(InfoType type, String username) {
    String text;

    switch (type) {
      case InfoType.typing:
        text = username + " est entrain d'écrire ...";
        break;
      case InfoType.joined:
        text = username + " a rejoint";
        break;
      case InfoType.left:
        text = username + " a quitté";
        break;
    }

    return Container(
      alignment:
          type == InfoType.typing ? Alignment.centerLeft : Alignment.center,
      width: widthScreen,
      margin: EdgeInsets.only(bottom: widthScreen * 0.02),
      child: Text(
        text,
        style: TextStyle(
            color: type == InfoType.typing ? Colors.grey : Colors.black),
      ),
    );
  }

  Widget buildBottomChat() {
    return Container(
      height: bottomChatHeight,
      padding: EdgeInsets.symmetric(horizontal: widthScreen * 0.02),
      color: Colors.grey[300],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _inputMessage,
              maxLines: 1,
            ),
          ),
          IconButton(
            iconSize: 30,
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              String text = _inputMessage.text;
              if (text.length > 1) {
                setState(() {
                  print("pressed");

                  _listMesssages.add(buildMessage(
                      {"username": widget.userName, "message": text}));
                });
                _socket.sendMessage(text);
                _inputMessage.clear();
                FocusScope.of(context).requestFocus(FocusNode());
                scrollBottom();
              }
            },
          )
        ],
      ),
    );
  }

  Widget buildChat() {
    List<Widget> body = [];
    body.addAll(_listMesssages);
    if (_userTyping.length > 1) {
      body.add(buildInformation(InfoType.typing, _userTyping));
    }
    print(body.length);

    return Container(
      width: widthScreen,
      height: heightScreen,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                bottom: bottomChatHeight,
                top: topChatHeight,
                left: widthScreen * 0.04,
                right: widthScreen * 0.04),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: body,
              ),
            ),
          ),
          Positioned(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: widthScreen * 0.04),
              color: Colors.green,
              height: topChatHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    " Connecté : ${widget.userName}",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "${_currentUserNumber} participants",
                    style: TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
            top: 0,
            width: widthScreen,
          ),
          Positioned(width: widthScreen, bottom: 0, child: buildBottomChat())
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widthScreen = MediaQuery.of(context).size.width;
    heightScreen = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Real time chat'),
      ),
      body: buildChat(),
    );
  }
}
