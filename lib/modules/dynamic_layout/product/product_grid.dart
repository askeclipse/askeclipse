import 'package:flutter/material.dart';

import '../../../services/index.dart';
import '../config/product_config.dart';
import '../helper/custom_physic.dart';
import '../helper/helper.dart';

class ProductGrid extends StatelessWidget {
  final products;
  final maxWidth;
  final ProductConfig config;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.maxWidth,
    required this.config,
  }) : super(key: key);

  double getGridRatio() {
    switch (config.layout) {
      case Layout.twoColumn:
        return 1.5;
      case Layout.threeColumn:
      default:
        return 1.7;
    }
  }

  double getHeightRatio() {
    switch (config.layout) {
      case Layout.twoColumn:
        return 1.7;
      case Layout.threeColumn:
      default:
        return 1.3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (products == null) {
      return const SizedBox();
    }
    var ratioProductImage = config.imageRatio;
    const padding = 12.0;
    var width = maxWidth - padding;
    var rows = config.rows;
    var productHeight = Layout.buildProductHeight(
      layout: config.layout,
      defaultHeight: maxWidth,
    );

    return Container(
      padding: const EdgeInsets.only(left: padding, top: padding),
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.circular(2),
      ),
      height: rows * productHeight * getHeightRatio(),
      child: GridView.count(
        childAspectRatio: ratioProductImage * getGridRatio(),
        scrollDirection: Axis.horizontal,
        physics: config.isSnapping ?? false
            ? CustomScrollPhysic(
                width: Layout.buildProductWidth(
                    screenWidth: width / ratioProductImage,
                    layout: config.layout))
            : const ScrollPhysics(),
        crossAxisCount: rows,
        children: List.generate(products.length, (i) {
          return Services().widget.renderProductCardView(
                item: products[i],
                width: Layout.buildProductWidth(
                    screenWidth: width, layout: config.layout),
                maxWidth: Layout.buildProductMaxWidth(layout: config.layout),
                height: productHeight,
                ratioProductImage: ratioProductImage,
                config: config,
              );
        }),
      ),
    );
  }
}
