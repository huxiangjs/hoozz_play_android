///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:flutter/services.dart' show rootBundle;

class HoozzPlayLicensePage extends StatefulWidget {
  const HoozzPlayLicensePage({super.key});

  final String title = 'License';

  @override
  State<HoozzPlayLicensePage> createState() => _HoozzPlayLicensePageState();
}

class _HoozzPlayLicensePageState extends State<HoozzPlayLicensePage> {
  late Future<String> _license;

  @override
  void initState() {
    super.initState();
    _license = _loadLicense();
  }

  Future<String> _loadLicense() async {
    return await rootBundle.loadString('LICENSE');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          height: 1000,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1000,
              child: FutureBuilder<String>(
                future: _license,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        snapshot.data ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: subFontFamily,
                        ),
                        softWrap: false,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
