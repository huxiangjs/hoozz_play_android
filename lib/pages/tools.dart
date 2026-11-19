///
/// Created on 2024/4/21
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/l10n/app_localizations.dart';
import 'package:hoozz_play/themes/theme.dart';

class HoozzPlayToolsPage extends StatefulWidget {
  const HoozzPlayToolsPage({super.key});

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

  // Built at build time so the item descriptions follow the current
  // locale (the item names are the English product names, kept as is)
  List<_ItemInfo> _itemList(AppLocalizations l10n) {
    return [
      _ItemInfo(
        'images/logo_espressif.png',
        'ESP Touch',
        l10n.toolsEspTouchDesc,
        '/tools_esptouch',
      ),
      _ItemInfo(
        'images/search_icon.png',
        'Discover',
        l10n.toolsDiscoverDesc,
        '/tools_discover',
      ),
    ];
  }

  Widget _generateItem(int index, List<_ItemInfo> itemList) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          itemList[index].page,
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
                  itemList[index].icon,
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
                      itemList[index].name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: subFontFamily,
                        fontWeight: FontWeight.bold,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      itemList[index].describe,
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    List<_ItemInfo> itemList = _itemList(l10n);

    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.toolsTitle),
        ),
        body: ListView.builder(
          itemCount: itemList.length,
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
          itemBuilder: (context, index) {
            return _generateItem(index, itemList);
          },
        ));
  }
}
