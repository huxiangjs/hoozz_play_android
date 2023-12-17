///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/themes/theme.dart';

class HoozzPlaySettingsPage extends StatefulWidget {
  const HoozzPlaySettingsPage({super.key});

  final String title = 'Hoozz Play Settings';

  @override
  State<HoozzPlaySettingsPage> createState() => _HoozzPlaySettingsPageState();
}

class _ItemInfo {
  IconData icon;
  String name;
  String page;
  _ItemInfo(this.icon, this.name, this.page);
}

class _HoozzPlaySettingsPageState extends State<HoozzPlaySettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  final List<_ItemInfo> _itemList = [
    _ItemInfo(Icons.info_outline, 'About', '/about'),
    _ItemInfo(Icons.people_outline, 'Author', '/author'),
    _ItemInfo(Icons.contact_page_outlined, 'License', '/license'),
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
                padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                child: Icon(_itemList[index].icon),
              ),
              Text(
                _itemList[index].name,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: subFontFamily,
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
          toolbarHeight: 64,
          title: Text(widget.title),
        ),
        body: ListView.builder(
          itemCount: _itemList.length,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          itemBuilder: (context, index) {
            return _generateItem(index);
          },
        ));
  }
}
