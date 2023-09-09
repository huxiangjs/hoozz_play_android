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

class _HoozzPlayHomePageState extends State<HoozzPlayHomePage> {
  Widget _generateItem(String desc, String imgName) {
    return InkWell(
      onTap: () {
        /* Routing Jump */
        Navigator.pushNamed(
          context,
          '/mlx90640',
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
                imgName,
                fit: BoxFit.cover,
              ),
            ),
            Text(desc),
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
        toolbarHeight: 64,
        title: Text(widget.title),
      ),
      body: GridView(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150.0,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 0.85,
        ),
        children: [
          _generateItem('MLX90640', 'images/product_view_mlx90640.png'),
        ],
      ),
    );
  }
}
