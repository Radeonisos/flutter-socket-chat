import 'package:flutter_app_chat_websocket/Event.dart';
import 'package:adhara_socket_io/adhara_socket_io.dart';

const url = "https://socket-io-chat.now.sh/";

class Socket {
  static Socket _instance;

  Event _event = Event.instance;
  SocketIO _socketIO;
  bool isConnected = false;

  static Socket get instance {
    if (_instance == null) _instance = new Socket();
    return _instance;
  }

  Future startSocket() async {
    SocketIOManager manager = new SocketIOManager();
    SocketOptions options = SocketOptions(url);

    _socketIO = await manager.createInstance(options);

    _socketIO.onConnect((data) {
      isConnected = true;
      _event.getBus().fire(GlobalEvent(EventFlag.socketConnected, {}));
    });

    _socketIO.onConnectError((data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketError, {}));
    });

    _socketIO.onConnectTimeout((data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketError, {}));
    });

    _socketIO.onError((data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketError, {}));
    });

    _socketIO.on('reconnect', (_) {
      isConnected = true;
      _event.getBus().fire(GlobalEvent(EventFlag.socketConnected, {}));
    });

    _socketIO.on('login', (data) {
      isConnected = true;
      _event.getBus().fire(GlobalEvent(EventFlag.socketUserLogged, data));
    });

    _socketIO.on('new message', (data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketUserNewMessage, data));
    });

    _socketIO.on('user joined', (data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketUserJoined, data));
    });

    _socketIO.on('user left', (data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketUserLeft, data));
    });

    _socketIO.on('typing', (data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketTyping, data));
    });

    _socketIO.on('stop typing', (data) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketStopTyping, data));
    });

    _socketIO.on('disconnect', (_) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketError, {}));
    });

    _socketIO.on('reconnect_error', (_) {
      _event.getBus().fire(GlobalEvent(EventFlag.socketStopTyping, {}));
    });

    _socketIO.connect();
  }

  void joinChat(String name) {
    _socketIO.emit('add user', [name]);
  }

  void beginTyping() {
    _socketIO.emit('typing', []);
  }

  void stopTyping() {
    _socketIO.emit('stop typing', []);
  }

  void sendMessage(String message) {
    _socketIO.emit('new message', [message]);
  }
}
