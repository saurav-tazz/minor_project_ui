import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService instance = SocketService._internal();
  late IO.Socket? _socket;

  SocketService._internal();

  // Allow other files to access the socket
  IO.Socket? get socket => _socket;

  Future<void> connect(String url) async {
    // USE THE IP THAT WORKED IN YOUR PING
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();
    _socket!.onConnect((_) => print('✅ Matchroom Socket Connected'));
  }
}
