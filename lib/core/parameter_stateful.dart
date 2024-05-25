///
/// Created on 2023/5/25
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/widgets.dart';

abstract class ParameterStatefulState extends State<StatefulWidget> {
  List<Object> parameter = [];
}

class ParameterStatefulWidget extends StatefulWidget {
  final ParameterStatefulState _page;

  const ParameterStatefulWidget(this._page, {super.key});

  @override
  State<StatefulWidget> createState() => _page;
}
