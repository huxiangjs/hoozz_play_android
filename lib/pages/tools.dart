///
/// Created on 2024/4/21
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/themes/theme.dart';

class HoozzPlayToolsPage extends StatefulWidget {
  const HoozzPlayToolsPage({super.key});

  final String title = 'Hoozz Play Tools';

  @override
  State<HoozzPlayToolsPage> createState() => _HoozzPlayToolsPageState();
}

class _ItemInfo {
  String icon;
  String name;
  String describe;
  String page;
  _ItemInfo(this.icon, this.name, this.describe, this.page);
}

class _HoozzPlayToolsPageState extends State<HoozzPlayToolsPage> {
  @override
  void initState() {
    super.initState();
  }

  final List<_ItemInfo> _itemList = [
    _ItemInfo(
      'images/logo_espressif.png',
      'ESP Touch',
      'Smart configuration network',
      '/tools_esptouch',
    ),
    _ItemInfo(
      'images/search_icon.png',
      'Discover',
      'Discover configured devices',
      '/tools_discover',
    ),
  ];

  Widget _generateItem(int index) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          _itemList[index].page,
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                child: Image.asset(
                  _itemList[index].icon,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _itemList[index].name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: subFontFamily,
                        fontWeight: FontWeight.bold,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _itemList[index].describe,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: subFontFamily,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ListView.builder(
          itemCount: _itemList.length,
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
          itemBuilder: (context, index) {
            return _generateItem(index);
          },
        ));
  }
}
