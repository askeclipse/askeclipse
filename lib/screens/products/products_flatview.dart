import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../modules/firebase/dynamic_link_service.dart';
import '../../services/service_config.dart';
import '../../services/services.dart';
import '../cart/cart_screen.dart';

enum MenuType { cart, wishlist, share, login }

class ProductFlatView extends StatefulWidget {
  final Widget Function(ScrollController) builder;
  final Widget Function(ScrollController) filterMenu;
  final Widget? bottomSheet;
  final Widget? titleFilter;
  final Function? onSort;
  final Function onFilter;
  final Function onSearch;

  const ProductFlatView({
    required this.builder,
    required this.filterMenu,
    required this.onSearch,
    this.bottomSheet,
    this.titleFilter,
    this.onSort,
    required this.onFilter,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductFlatView> createState() => _ProductFlatViewState();
}

class _ProductFlatViewState extends State<ProductFlatView> {
  final ScrollController controller = ScrollController();

  Color get labelColor => Colors.black;

  bool showSticky = true;

  bool get isLoggedIn =>
      Provider.of<UserModel>(context, listen: false).loggedIn;

  Widget _getStickyWidget() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          showSticky ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      secondChild: const SizedBox(width: double.maxFinite),
      firstChild: Container(
        alignment: Alignment.center,
        height: 44,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 1),
              blurRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            widget.titleFilter ?? const SizedBox(),
            const Spacer(),
            const SizedBox(width: 5),
            const VerticalDivider(width: 15, indent: 8, endIndent: 8),
            const SizedBox(width: 5),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  Text(S.of(context).filter,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_down, size: 13),
                ],
              ),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(color: Colors.transparent),
                    ),
                    DraggableScrollableSheet(
                      initialChildSize: 0.7,
                      minChildSize: 0.2,
                      maxChildSize: 0.9,
                      builder: (BuildContext context,
                          ScrollController scrollController) {
                        return Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(top: 40),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15.0),
                                  topRight: Radius.circular(15.0),
                                ),
                                color: Theme.of(context).backgroundColor,
                              ),
                              child: widget.filterMenu(scrollController),
                            ),
                            Positioned(
                              top: 0,
                              right: 10,
                              child: TextButton(
                                onPressed: () {
                                  // widget.onFilter(
                                  //   categoryId: productModel.categoryId,
                                  //   tagId: productModel.tagId.toString(),
                                  //   minPrice: productModel.minPrice,
                                  //   maxPrice: productModel.maxPrice,
                                  // );
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  S.of(context).apply,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  bool _onChangeDirection(scrollNotification) {
    /// scroll down
    if (controller.position.userScrollDirection == ScrollDirection.reverse &&
        controller.offset > 80 &&
        showSticky == true) {
      setState(() {
        showSticky = false;
      });
      return true;
    }

    /// scroll up
    if (controller.position.userScrollDirection == ScrollDirection.forward &&
        showSticky == false) {
      setState(() => showSticky = true);
    }
    return true;
  }

  PopupMenuItem<String> _buildMenuItem({
    required IconData icon,
    required String label,
    required String value,
    bool isSelect = false,
  }) {
    final menuItemStyle = TextStyle(
      fontSize: 13.0,
      color: isSelect
          ? Theme.of(context).primaryColor
          : Theme.of(context).colorScheme.secondary,
      height: 24.0 / 15.0,
    );
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Icon(icon,
                color: isSelect
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.secondary,
                size: 17),
          ),
          Text(label, style: menuItemStyle),
        ],
      ),
    );
  }

  Future<void> _onSeeMore(MenuType type) async {
    switch (type) {
      case MenuType.cart:
        await Navigator.of(context).pushNamed(
          RouteList.cart,
          arguments: CartScreenArgument(isBuyNow: true, isModal: false),
        );
        break;
      case MenuType.share:
        var currentCateId =
            Provider.of<ProductModel>(context, listen: false).categoryId;
        var cateUrl = await DynamicLinkService()
            .generateProductCategoryUrl(currentCateId);
        Services().firebase.shareDynamicLinkProduct(
              itemUrl: cateUrl,
            );
        break;
      case MenuType.wishlist:
        await Navigator.of(context).pushNamed(RouteList.wishlist);
        break;
      case MenuType.login:
        await Navigator.of(context).pushNamed(RouteList.login);
        break;
    }
  }

  Widget _buildMoreWidget(bool loggedIn) {
    final sortByData = [
      {
        'type': MenuType.cart.name,
        'title': S.of(context).myCart,
        'icon': CupertinoIcons.bag,
      },
      {
        'type': MenuType.wishlist.name,
        'title': S.of(context).myWishList,
        'icon': CupertinoIcons.heart,
      },
      if (firebaseDynamicLinkConfig['isEnabled'] &&
          Config().isWooType &&
          !Config().isListingType)
        {
          'type': MenuType.share.name,
          'title': S.of(context).share,
          'icon': CupertinoIcons.share,
        },
      if (!loggedIn)
        {
          'type': MenuType.login.name,
          'title': S.of(context).login,
          'icon': CupertinoIcons.person,
        },
    ];

    return PopupMenuButton<String>(
      onSelected: (value) => _onSeeMore(MenuType.values.byName(value)),
      itemBuilder: (BuildContext context) =>
          List<PopupMenuItem<String>>.generate(
        sortByData.length,
        (index) => _buildMenuItem(
          icon: sortByData[index]['icon'] as IconData,
          label: '${sortByData[index]['title']}',
          value: '${sortByData[index]['type']}',
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Icon(
          CupertinoIcons.ellipsis,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void onSearch(String value) {
    EasyDebounce.debounce('searchCategory', const Duration(milliseconds: 200),
        () => widget.onSearch(value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Theme.of(context).backgroundColor,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: CupertinoSearchTextField(
            onChanged: onSearch,
            onSubmitted: onSearch,
          ),
          actions: [
            Selector<UserModel, bool>(
              selector: (context, provider) => provider.loggedIn,
              builder: (context, loggedIn, child) {
                return _buildMoreWidget(loggedIn);
              },
            ),
            const SizedBox(width: 4),
          ]),
      body: Material(
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onChangeDirection,
              child: widget.builder(controller),
            ),
            _getStickyWidget(),
            Align(
              alignment: Alignment.bottomRight,
              child: widget.bottomSheet,
            )
          ],
        ),
      ),
    );
  }
}
