///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/l10n/app_localizations.dart';
import 'package:hoozz_play/themes/theme.dart';

class HoozzPlaySettingsPage extends StatefulWidget {
  const HoozzPlaySettingsPage({super.key});

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
  // Built at build time so the item names follow the current locale
  // (the Language entry at the bottom opens the language selection page)
  List<_ItemInfo> _itemList(AppLocalizations l10n) {
    return [
      _ItemInfo(Icons.pan_tool_outlined, l10n.tools, '/tools'),
      _ItemInfo(Icons.share_outlined, l10n.vpn, '/vpn'),
      _ItemInfo(Icons.info_outline, l10n.about, '/about'),
      _ItemInfo(Icons.people_outline, l10n.author, '/author'),
      _ItemInfo(Icons.contact_page_outlined, l10n.license, '/license'),
      _ItemInfo(Icons.translate, l10n.language, '/language'),
    ];
  }

  Widget _generateItem(int index, List<_ItemInfo> itemList) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, itemList[index].page);
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
                child: Icon(itemList[index].icon, color: mainFillColor),
              ),
              Expanded(
                child: Text(
                  itemList[index].name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: subFontFamily,
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                  ),
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
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView.builder(
        itemCount: itemList.length,
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        itemBuilder: (context, index) {
          return _generateItem(index, itemList);
        },
      ),
    );
  }
}
