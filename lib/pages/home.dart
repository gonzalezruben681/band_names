import 'dart:io';

import 'package:band_names/services/notification_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];
  final voterNameController = TextEditingController();
  bool enabled = true;

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Votaciones', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online)
                ? Icon(Icons.check_circle, color: Colors.blue[300])
                : const Icon(Icons.offline_bolt, color: Colors.red),
          )
        ],
      ),
      body: socketService.serverStatus == ServerStatus.Offline
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("No hay conexión con el servidor"),
                  SizedBox(height: 10),
                  MaterialButton(
                    minWidth: 200.0,
                    height: 40.0,
                    onPressed: () {
                      socketService.socket.connect();
                    },
                    color: Colors.lightBlue,
                    child: Text('Reconectar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _showGraph(),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    enabled: enabled,
                    controller: voterNameController,
                    decoration: InputDecoration(labelText: "Ingrese su nombre"),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: bands.length,
                      itemBuilder: (context, i) => _bandTile(bands[i])),
                )
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Botón para eliminar voto
            FloatingActionButton(
                elevation: 1,
                child: const Text(
                  "Eliminar votante",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10),
                ),
                onPressed: () =>
                    deleteVoter(voterNameController.text.toLowerCase())),
            const SizedBox(width: 20),
            FloatingActionButton(
              elevation: 1,
              child: Icon(Icons.refresh),
              onPressed: resetVotes,
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              child: const Icon(Icons.add),
              elevation: 1,
              onPressed: addNewBand,
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              elevation: 1,
              onPressed: resetVoters,
              child: const Text(
                "Eliminar votantes",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) {
        socketService.emit('delete-band', {'id': band.id});
        bands.remove(band);
        setState(() {});
      },
      background: Container(
          padding: const EdgeInsets.only(left: 8.0),
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerLeft,
            child:
                Text('Borrar candidato', style: TextStyle(color: Colors.white)),
          )),
      child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(band.name.substring(0, 2)),
          ),
          title: Text(band.name),
          trailing: Text('${band.votes}', style: const TextStyle(fontSize: 20)),
          onTap: () => addVotante(voterNameController.text, band)),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    // if (Platform.isAndroid) {
    //   // Android
    //   return showDialog(
    //       context: context,
    //       builder: (_) => AlertDialog(
    //             title: const Text('New band name:'),
    //             content: TextField(
    //               controller: textController,
    //             ),
    //             actions: [
    //               MaterialButton(
    //                   child: const Text('Add'),
    //                   elevation: 5,
    //                   textColor: Colors.blue,
    //                   onPressed: () => addBandToList(textController.text))
    //             ],
    //           ));
    // }
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Nuevo candidado:'),
              content: TextField(
                controller: textController,
              ),
              actions: [
                MaterialButton(
                    child: const Text('Add'),
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () => addBandToList(textController.text))
              ],
            ));

    // showCupertinoDialog(
    //     context: context,
    //     builder: (_) => CupertinoAlertDialog(
    //           title: const Text('New band name:'),
    //           content: CupertinoTextField(
    //             controller: textController,
    //           ),
    //           actions: [
    //             CupertinoDialogAction(
    //                 isDefaultAction: true,
    //                 child: const Text('Add'),
    //                 onPressed: () => addBandToList(textController.text)),
    //             CupertinoDialogAction(
    //                 isDestructiveAction: true,
    //                 child: const Text('Dismiss'),
    //                 onPressed: () => Navigator.pop(context))
    //           ],
    //         ));
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }

    Navigator.pop(context);
  }

  void addVotante(String voterName, Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    if (voterName.length > 1) {
      enabled = false;
      socketService.emit(
          'vote-band', {'id': band.id, 'voterName': voterName.toLowerCase()});
    }
    socketService.socket.on(
        "vote-error",
        (data) => NotificationSocketService.handleNotification(
            context: context, message: data, color: Colors.red[400]));
  }

  void resetVotes() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit('reset-votes');
  }

  deleteVoter(String voterName) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    // Emitir evento al servidor para eliminar votante
    socketService.emit('delete-voter', voterName);
    voterNameController.clear();
    enabled = true;
    setState(() {});
  }

  void resetVoters() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit('delete-all-voters');
    enabled = true;
    setState(() {});
  }

  // Mostrar gráfica
  Widget _showGraph() {
    Map<String, double> dataMap = {};
    for (var band in bands) {
      dataMap.putIfAbsent(band.name, () => band.votes!.toDouble());
    }

    if (dataMap.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.4,
        child: PieChart(
          dataMap: dataMap,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
