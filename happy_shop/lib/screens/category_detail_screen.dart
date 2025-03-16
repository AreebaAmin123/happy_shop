import 'package:flutter/material.dart';
import 'package:happy_shop/widgets/YSL_heel_widget.dart';
import 'package:happy_shop/widgets/clothes_widget.dart';
import 'package:happy_shop/widgets/handbags_widget.dart';
import 'package:happy_shop/widgets/jackets_widget.dart';
import 'package:happy_shop/widgets/joggar_widget.dart';
import 'package:happy_shop/widgets/t_shirts_widget.dart';
import 'package:happy_shop/widgets/watches_widget.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;

  CategoryDetailScreen({required this.categoryName, required categoryImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: _getCategoryContent(categoryName),
    );
  }

  Widget _getCategoryContent(String categoryName) {

    switch (categoryName) {
      case "Clothes":
        return ClothesWidget(categoryName: '',);
      case "T_Shirts":
        return TshirtsWidget(categoryName: '',);
      case "Joggars":
        return JoggersWidget(categoryName: '',);
      case "Jackets":
        return JacketsWidget(categoryName: '',);
      case "Handbags":
        return HandbagsWidget(categoryName: '',);
      case "Watches":
        return WatchesWidget(categoryName: '',);
      case "YSL_Heels":
        return YSLHeelWidget(categoryName: '',);
      default:
        return Center(child: Text('No details available.', style: TextStyle(fontSize: 20)));
    }
  }
}