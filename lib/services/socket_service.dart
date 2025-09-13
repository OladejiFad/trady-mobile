import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(String userId) {
    socket = IO.io('http://172.20.10.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket server');
      socket.emit('join', userId);
    });

    socket.onDisconnect((_) => print('Disconnected from socket server'));
  }

  void onNewMessage(void Function(dynamic data) callback) {
    socket.on('new-message', callback);
  }

  void dispose() {
    socket.dispose();
  }
}
