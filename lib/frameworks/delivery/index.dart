import 'package:flutter/material.dart';

import '../woocommerce/index.dart';
import 'screen_index.dart';
export 'services/delivery_mixin.dart';

class DeliveryWidget extends WooWidget {
  @override
  Widget renderDelivery({bool isFromMV = false}) {
    return ScreenIndex(
      isFromMV: isFromMV,
    );
  }
}
