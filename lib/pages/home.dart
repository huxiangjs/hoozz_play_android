import 'package:flutter/material.dart';

class HoozzPlayHomePage extends StatefulWidget {
  const HoozzPlayHomePage({super.key});

  final String title = 'Hoozz Play Home Page';

  @override
  State<HoozzPlayHomePage> createState() => _HoozzPlayHomePageState();
}

class _HoozzPlayHomePageState extends State<HoozzPlayHomePage> {
  Widget _generate_item(String desc, String img_name) {
    return InkWell(
        onTap: () {
          const snackBar = SnackBar(content: Text('Tap'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          /* Routing Jump */
          Navigator.pushNamed(
            context,
            '/mlx90640',
            // arguments: {'name': xxx, 'id': xxx},
          );
        },
        child: Container(
          padding: const EdgeInsets.all(5),
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
          child: Column(children: <Widget>[
            Image.asset(
              img_name,
              fit: BoxFit.cover,
            ),
            Text(desc),
          ]),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(widget.title),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        childAspectRatio: 0.8,
        children: [
          _generate_item('MLX90640', 'images/product_view_mlx90640.png'),
        ],
      ),
    );
  }
}
