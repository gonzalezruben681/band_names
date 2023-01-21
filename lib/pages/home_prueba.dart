// import 'dart:io';

// import 'package:flutter/cupertino.dart';
import 'package:band_names/models/category.dart';
import 'package:band_names/models/votante.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/services/notification_service.dart';
import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';

class HomePagePrueba extends StatefulWidget {
  @override
  _HomePagePruebaState createState() => _HomePagePruebaState();
}

class _HomePagePruebaState extends State<HomePagePrueba> {
  List<Band> bands = [];
  List<Votante> votantes = [];
  List<Category> categories = [];
  final voterNameController = TextEditingController();
  bool enabled = true;
  String? _selectedCategory;

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);
    socketService.socket.on('active-voter', _handleVoter);
    socketService.socket.on("categories", _handleCategories);
    socketService.emit("get-categories");
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

  _handleCategories(dynamic payload) {
    categories = (payload as List)
        .map((category) => Category.fromJson(category))
        .toList();
    setState(() {});
    _selectedCategory = categories.first.id;
  }

  // @override
  // void dispose() {
  //   final socketService = Provider.of<SocketService>(context, listen: false);
  //   socketService.socket.off('active-bands');
  //   super.dispose();
  // }

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
      body:
          // socketService.serverStatus == ServerStatus.Offline
          //     ? Center(
          //         child: Column(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             const Text("No hay conexión con el servidor"),
          //             const SizedBox(height: 10),
          //             MaterialButton(
          //               minWidth: 200.0,
          //               height: 40.0,
          //               onPressed: () {
          //                 socketService.socket.connect();
          //               },
          //               color: Colors.lightBlue,
          //               child: const Text('Reconectar',
          //                   style: TextStyle(color: Colors.white)),
          //             ),
          //           ],
          //         ),
          //       )
          // :
          Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton(
              value: _selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              hint: const Text("Selecciona una categoría"),
            ),
          ),
          _showGraph(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              enabled: enabled,
              controller: voterNameController,
              decoration: const InputDecoration(labelText: "Ingrese su nombre"),
            ),
          ),
          Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: bands.length,
                itemBuilder: (context, i) {
                  final band = bands[i];
                  if (_selectedCategory == null ||
                      band.category == _selectedCategory) {
                    return _bandTile(band);
                  }
                  return Container();
                }),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  child: MaterialButton(
                    elevation: 1,
                    onPressed: () =>
                        resetCampos(votantes, voterNameController.text.trim()),
                    child: const Icon(Icons.refresh_outlined),
                  ),
                ),
                const SizedBox(width: 10),
                MaterialButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'addband');
                  },
                  child: Text("Agregar candidato"),
                ),
                const SizedBox(width: 10),
                MaterialButton(
                  elevation: 1,
                  onPressed: resetVoters,
                  child: const Text(
                    "Restaurar votos",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final categoryController = TextEditingController();

    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Nuevo candidado'),
              content: Container(
                height: MediaQuery.of(context).size.height * 0.2,
                child: Column(
                  children: [
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(labelText: 'Nombre: '),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: categoryController,
                      decoration:
                          InputDecoration(labelText: 'Cargo a postularse:'),
                    ),
                  ],
                ),
              ),
              actions: [
                MaterialButton(
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () => addBandToList(
                        textController.text, categoryController.text),
                    child: const Text('Aceptar'))
              ],
            ));
  }

  void addBandToList(String name, String category) {
    if (name.length > 1 && category.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name, 'category': category});
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Nombre y Cargo son obligatorios"),
      ));
    }
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
    if (votantes.isEmpty) {
      enabled = true;
      setState(() {});
    }
  }

  // void resetVotes() {
  //   final socketService = Provider.of<SocketService>(context, listen: false);
  //   socketService.emit('reset-votes');
  // }

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
    String category = _selectedCategory ?? ''; // la categoría seleccionada

    Map<String, double> dataMap = {};
    for (var band in bands) {
      if (band.category == category) {
        dataMap.putIfAbsent(band.name, () => band.votes!.toDouble());
      }
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
