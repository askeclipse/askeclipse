import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants.dart';
import '../../../../generated/l10n.dart';
import '../../common_widgets/order_item.dart';
import '../../common_widgets/order_loading_item.dart';
import '../../models/authentication_model.dart';
import 'search_screen_model.dart';

class DeliverySearchScreen extends StatefulWidget {
  final Function onCallBack;

  const DeliverySearchScreen({Key? key, required this.onCallBack})
      : super(key: key);
  @override
  State<DeliverySearchScreen> createState() => _DeliverySearchScreenState();
}

class _DeliverySearchScreenState extends State<DeliverySearchScreen> {
  final _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final user =
        Provider.of<DeliveryAuthenticationModel>(context, listen: false).user;
    return ChangeNotifierProvider(
      create: (_) => SearchScreenModel(user!),
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 5.0,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon:
                          Icon(isIos ? Icons.arrow_back_ios : Icons.arrow_back),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        margin: const EdgeInsets.only(
                          top: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Consumer<SearchScreenModel>(
                          builder: (_, model, __) => TextField(
                            focusNode: _focusNode,
                            autofocus: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search something...',
                            ),
                            onChanged: model.searchOrder,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Consumer<SearchScreenModel>(builder: (_, model, __) {
                      if (model.state == SearchState.loading) {
                        return ListView.builder(
                            itemBuilder: (context, index) =>
                                const OrderLoadingItem(),
                            itemCount: 5);
                      }
                      if (_focusNode.hasFocus && model.orders.isEmpty) {
                        return Center(
                          child: Text(S.of(context).dataEmpty),
                        );
                      }
                      if (!_focusNode.hasFocus && model.orders.isEmpty) {
                        return Center(
                          child: Text(S.of(context).searchForItems),
                        );
                      }
                      return ListView.builder(
                          itemBuilder: (context, index) =>
                              OrderItem(model.orders[index], widget.onCallBack),
                          itemCount: model.orders.length);
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
