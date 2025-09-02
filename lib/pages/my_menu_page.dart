import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/database_service.dart';
import '../main.dart';

class MyMenuPage
    extends
        StatefulWidget {
  const MyMenuPage({
    Key? key,
  }) : super(
         key:
             key,
       );

  @override
  State<
    MyMenuPage
  >
  createState() =>
      _MyMenuPageState();
}

class _MyMenuPageState
    extends
        State<
          MyMenuPage
        > {
  List<
    MenuItem
  >
  _menu =
      [];
  bool _isLoading =
      true;
  final _db =
      DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<
    void
  >
  _fetchMenu() async {
    setState(
      () =>
          _isLoading =
              true,
    );
    final menu = await _db.getMenuItems(
      currentUser!.username,
    );
    setState(
      () {
        _menu =
            menu;
        _isLoading =
            false;
      },
    );
  }

  void _showMenuDialog({
    MenuItem? item,
  }) {
    final nameController = TextEditingController(
      text:
          item?.name ??
          '',
    );
    final descController = TextEditingController(
      text:
          item?.description ??
          '',
    );
    final priceController = TextEditingController(
      text:
          item?.price.toString() ??
          '',
    );
    final imageUrlController = TextEditingController(
      text:
          item?.imageUrl ??
          '',
    );
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: Text(
              item ==
                      null
                  ? 'Add Menu Item'
                  : 'Edit Menu Item',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        nameController,
                    decoration: const InputDecoration(
                      labelText:
                          'Name',
                    ),
                  ),
                  TextField(
                    controller:
                        descController,
                    decoration: const InputDecoration(
                      labelText:
                          'Description',
                    ),
                  ),
                  TextField(
                    controller:
                        priceController,
                    decoration: const InputDecoration(
                      labelText:
                          'Price',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal:
                          true,
                    ),
                  ),
                  TextField(
                    controller:
                        imageUrlController,
                    decoration: const InputDecoration(
                      labelText:
                          'Image URL (optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                    ),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final name =
                      nameController.text.trim();
                  final desc =
                      descController.text.trim();
                  final price =
                      double.tryParse(
                        priceController.text.trim(),
                      ) ??
                      0.0;
                  final imageUrl =
                      imageUrlController.text.trim().isEmpty
                          ? null
                          : imageUrlController.text.trim();
                  if (name.isEmpty ||
                      desc.isEmpty)
                    return;
                  if (item ==
                      null) {
                    await _db.addMenuItem(
                      currentUser!.username,
                      MenuItem(
                        id:
                            '',
                        name:
                            name,
                        description:
                            desc,
                        price:
                            price,
                        imageUrl:
                            imageUrl,
                      ),
                    );
                  } else {
                    await _db.updateMenuItem(
                      currentUser!.username,
                      MenuItem(
                        id:
                            item.id,
                        name:
                            name,
                        description:
                            desc,
                        price:
                            price,
                        imageUrl:
                            imageUrl,
                      ),
                    );
                  }
                  if (mounted) {
                    Navigator.pop(
                      context,
                    );
                    _fetchMenu();
                  }
                },
                child: Text(
                  item ==
                          null
                      ? 'Add'
                      : 'Save',
                ),
              ),
            ],
          ),
    );
  }

  Future<
    void
  >
  _deleteMenuItem(
    MenuItem item,
  ) async {
    await _db.deleteMenuItem(
      currentUser!.username,
      item.id,
    );
    _fetchMenu();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
            ),
            onPressed:
                () =>
                    _showMenuDialog(),
            tooltip:
                'Add Menu Item',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child:
                    CircularProgressIndicator(),
              )
              : _menu.isEmpty
              ? const Center(
                child: Text(
                  'No menu items yet.',
                ),
              )
              : ListView.builder(
                itemCount:
                    _menu.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  final item =
                      _menu[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal:
                          16,
                      vertical:
                          8,
                    ),
                    child: ListTile(
                      leading:
                          item.imageUrl !=
                                      null &&
                                  item.imageUrl!.isNotEmpty
                              ? Image.network(
                                item.imageUrl!,
                                width:
                                    50,
                                height:
                                    50,
                                fit:
                                    BoxFit.cover,
                              )
                              : const Icon(
                                Icons.fastfood,
                                size:
                                    40,
                              ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        item.description,
                      ),
                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Text(
                            'RM${item.price.toStringAsFixed(2)}',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                            ),
                            onPressed:
                                () => _showMenuDialog(
                                  item:
                                      item,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color:
                                  Colors.red,
                            ),
                            onPressed:
                                () => _deleteMenuItem(
                                  item,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
