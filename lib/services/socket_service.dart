import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ServerStatus { Online, Offline, Connecting }

class SocketService with ChangeNotifier {
  // controlar la manera de como se exponen a todas las clases del proyecto
  ServerStatus _serverStatus = ServerStatus.Connecting;
  late IO.Socket _socket;

// Getter para obtener el estado del servidor
  ServerStatus get serverStatus => _serverStatus;

// Getter para obtener el socket
  IO.Socket get socket => _socket;
// Getter para obtener la función emit del socket
  Function get emit => _socket.emit;

  SocketService() {
// Se inicializa la configuración del socket
    _initConfig();
  }

  void _initConfig() {
// Se instancia el cliente de Dart para el socket
    _socket = IO.io('http://192.168.100.10:3000/', {
      'transports': ['websocket'], // Se utiliza el transporte websocket
      'autoConnect': true // Se conecta automáticamente al instanciar el socket
    });

// Se escucha el evento 'connect' para cambiar el estado del servidor a 'Online'
    _socket.onConnect((_) {
      _serverStatus = ServerStatus.Online;
      notifyListeners();
    });

// Se escucha el evento 'disconnect' para cambiar el estado del servidor a 'Offline'
    _socket.onDisconnect((_) {
      _serverStatus = ServerStatus.Offline;
      notifyListeners();
    });

    // _socket.on('nuevo-mensaje', (data) => print('nuevo-mensaje: $data'));
  }
}
