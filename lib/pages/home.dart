// import 'dart:io';

// import 'package:flutter/cupertino.dart';
import 'package:band_names/models/votante.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/services/notification_service.dart';
import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];
  List<Votante> votantes = [];
  final voterNameController = TextEditingController();
  bool enabled = true;

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);
    socketService.socket.on('active-voter', _handleVoter);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  _handleVoter(dynamic payload) {
    votantes =
        (payload as List).map((voter) => Votante.fromMap(voter)).toList();
    print(votantes);
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
                  const Text("No hay conexión con el servidor"),
                  const SizedBox(height: 10),
                  MaterialButton(
                    minWidth: 200.0,
                    height: 40.0,
                    onPressed: () {
                      socketService.socket.connect();
                    },
                    color: Colors.lightBlue,
                    child: const Text('Reconectar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _showGraph(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    enabled: enabled,
                    controller: voterNameController,
                    decoration:
                        const InputDecoration(labelText: "Ingrese su nombre"),
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
            // FloatingActionButton(
            //     elevation: 1,
            //     child: const Text(
            //       "Eliminar votante",
            //       textAlign: TextAlign.center,
            //       style: TextStyle(fontSize: 10),
            //     ),
            //     onPressed: () =>
            //         deleteVoter(votantes, voterNameController.text)),
            // const SizedBox(width: 20),
            // FloatingActionButton(
            //   elevation: 1,
            //   onPressed: resetVotes,
            //   child: const Icon(Icons.refresh),
            // ),
            // const SizedBox(width: 20),
            FloatingActionButton(
              elevation: 1,
              onPressed: () =>
                  resetCampos(votantes, voterNameController.text.trim()),
              child: const Icon(Icons.refresh_outlined),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              elevation: 1,
              onPressed: addNewBand,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              elevation: 1,
              onPressed: resetVoters,
              child: const Text(
                "Restaurar votación",
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
              child: Text('Borrar candidato',
                  style: TextStyle(color: Colors.white)),
            )),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(band.name.substring(0, 2)),
          ),
          title: Text(band.name),
          trailing: Text('${band.votes}', style: const TextStyle(fontSize: 20)),
          onTap:
              enabled ? () => addVotante(voterNameController.text, band) : null,
        ));
  }

  addNewBand() {
    final textController = TextEditingController();

    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Nuevo candidado:'),
              content: TextField(
                controller: textController,
              ),
              actions: [
                MaterialButton(
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () => addBandToList(textController.text),
                    child: const Text('Add'))
              ],
            ));
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
      socketService.emit('vote-band',
          {'id': band.id, 'voterName': voterName.toLowerCase().trim()});
      setState(() {});
    }
    socketService.socket.on("vote-error", (data) {
      NotificationSocketService.handleNotification(
          context: context, message: data, color: Colors.red[400]);
    });
  }

  void resetCampos(List<Votante> votantes, String voter) {
    // final votante = votantes.any((votante) => votante.name == voter);
    // print("hola ${votante}");
    // if (votante) {
    //   print("hola");
    // } else {
    //   enabled = true;
    //   setState(() {});
    //   print('adios');
    // }

    if (votantes.isEmpty) {
      enabled = true;
      setState(() {});
    }
  }

  void resetVotes() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit('reset-votes');
  }

  void deleteVoter(List<Votante> votante, String voter) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    for (var votante in votantes) {
      if (votante.name == voter.toLowerCase().trim()) {
        socketService.emit('delete-voter', votante.name);
        votantes.remove(votante);
        break;
      }
    }

    socketService.socket.on("voter-deleted", (data) {
      // print(data == voterNameController.text);
      print(data);
    });
  }

  void resetVoters() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit('delete-all-voters');
    socketService.emit('reset-votes');
    print('borrado de voters');
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
