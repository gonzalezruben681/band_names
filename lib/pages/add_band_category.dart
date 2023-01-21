import 'package:band_names/models/category.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddBandPage extends StatefulWidget {
  @override
  _AddBandPageState createState() => _AddBandPageState();
}

class _AddBandPageState extends State<AddBandPage> {
  String? _bandName;
  String? _category;
  bool _isMounted = false;
  List<Category> _categories = [];
  final myController = TextEditingController();
  final myController2 = TextEditingController();

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    _isMounted = true;
    socketService.socket.on("categories", _handleCategories);
    socketService.emit("get-categories");
    super.initState();
  }

  _handleCategories(dynamic payload) {
    if (_isMounted) {
      setState(() {
        _categories = (payload as List)
            .map((category) => Category.fromJson(category))
            .toList();
      });
      _category = _categories.first.id;
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar banda"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: myController,
              onChanged: (value) {
                _bandName = value;
                setState(() {});
              },
              decoration:
                  const InputDecoration(labelText: "Nombre del canditato"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton(
              value: _category,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                _category = value;
                setState(() {});
              },
              hint: const Text("Selecciona una categoría"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MaterialButton(
              onPressed: () {
                if (_bandName!.length > 1 && _category!.length > 1) {
                  //Emite evento al servidor con el nombre de la banda y la categoría seleccionada
                  socketService.emit(
                      'add-band', {'name': _bandName, 'category': _category});
                  myController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Ingresa un nombre y categoria")));
                }
              },
              child: const Text("Agregar"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: myController2,
              onChanged: (value) => _category = value,
              decoration:
                  const InputDecoration(labelText: "Nombre de la categoría"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: MaterialButton(
              onPressed: () {
                if (_category != null) {
                  //Emite evento al servidor con el nombre de la categoría
                  socketService.emit("add-category", {
                    "name": _category,
                  });
                  myController2.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Ingresa un nombre de categoria")));
                }
              },
              child: const Text("Agregar categoría"),
            ),
          ),
        ],
      ),
    );
  }

  // @override
  // void dispose() {
  //   final socketService = Provider.of<SocketService>(context, listen: false);
  //   socketService.socket.on("categories", _handleCategories);
  //   socketService.emit("get-categories");
  //   super.dispose();
  // }

  void editCategory(String id, String newName) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit("edit-category", {
      "id": id,
      "newName": newName,
    });
  }

  void deleteCategory(String id) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit("delete-category", {
      "id": id,
    });
  }
}
