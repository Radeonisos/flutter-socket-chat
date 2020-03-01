import 'package:flutter/material.dart';
import 'package:flutter_app_chat_websocket/ChatPage.dart';
import 'package:flutter_app_chat_websocket/Event.dart';
import 'package:flutter_app_chat_websocket/Socket.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';

class ConnectionPage extends StatefulWidget {
  ConnectionPage({this.showError = false});

  final bool showError;

  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  Socket _socket = Socket.instance;
  Event _event = Event.instance;

  double widthScreen;
  double heightScreen;
  String userName = "";

  bool _isLoading = true;
  bool _isError = false;

  computeEvent(GlobalEvent event) {
    setState(() {
      switch (event.flag) {
        case EventFlag.socketConnected:
          _isLoading = false;
          break;
        case EventFlag.socketError:
          _isLoading = false;
          _isError = true;
          break;
        case EventFlag.socketUserLogged:
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatPage(
                        userName: userName,
                        userNumber: event.value['numUsers'],
                      )));
          break;
        default:
      }
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.showError) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      } else if (_socket.isConnected) {
        _isLoading = false;
      } else {
        _event.getBus().on<GlobalEvent>().listen(computeEvent);
        _socket.startSocket();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    widthScreen = MediaQuery.of(context).size.width;
    heightScreen = MediaQuery.of(context).size.height;

    Widget body;

    if (_isLoading) {
      body = buildLoader();
    } else if (_isError) {
      body = buildError();
    } else {
      body = buildUserNameInput();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: body);
  }

  Widget buildLoader() {
    return Container(
      child: Center(
        child: Loading(
            indicator: BallPulseIndicator(),
            size: widthScreen / 6,
            color: Colors.blue),
      ),
    );
  }

  Widget buildError() {
    return Container(
      child: Text(
        "Une erreur s'est produite",
        style: TextStyle(fontSize: 18, color: Colors.red),
      ),
    );
  }

  Widget buildUserNameInput() {
    return Center(
      child: Container(
        width: widthScreen / 1.3,
        child: TextField(
          maxLines: 1,
          maxLength: 25,
          autocorrect: false,
          onSubmitted: (text) {
            if (text != null && text.length > 1) {
              setState(() {
                userName = text;
                _socket.joinChat(userName);
                _isLoading = true;
              });
            }
          },
          decoration: InputDecoration(labelText: "Veuillez entre votre pseudo"),
        ),
      ),
    );
  }
}
