import 'package:flutter/material.dart';

class MLX90640HomePage extends StatefulWidget {
  const MLX90640HomePage({super.key});

  final String title = "MLX90640";

  @override
  State<MLX90640HomePage> createState() => _MLX90640HomePageState();
}

class _MLX90640HomePageState extends State<MLX90640HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      // body:
    );
  }
}
