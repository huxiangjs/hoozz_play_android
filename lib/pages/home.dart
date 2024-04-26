///
/// Created on 2023/09/03
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';

class HoozzPlayHomePage extends StatefulWidget {
  const HoozzPlayHomePage({super.key});

  final String title = 'Hoozz Play Home';

  @override
  State<HoozzPlayHomePage> createState() => _HoozzPlayHomePageState();
}

class _ItemInfo {
  String icon;
  String name;
  String page;
  _ItemInfo(this.icon, this.name, this.page);
}

class _HoozzPlayHomePageState extends State<HoozzPlayHomePage> {
  final List<_ItemInfo> _itemList = [
    _ItemInfo('images/product_view_mlx90640.png', 'MLX90640', '/mlx90640'),
    _ItemInfo(
      'images/product_view_remote_switch.png',
      'REMOTE SW',
      '/remote_sw',
    ),
  ];

  Widget _generateItem(int index) {
    return InkWell(
      onTap: () {
        /* Routing Jump */
        Navigator.pushNamed(
          context,
          _itemList[index].page,
          // arguments: {'name': xxx, 'id': xxx},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              offset: const Offset(0, 0),
              blurRadius: 3,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.asset(
                _itemList[index].icon,
                fit: BoxFit.cover,
              ),
            ),
            Text(_itemList[index].name),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.app_settings_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: GridView.builder(
        itemCount: _itemList.length,
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150.0,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) => _generateItem(index),
      ),
    );
  }
}
