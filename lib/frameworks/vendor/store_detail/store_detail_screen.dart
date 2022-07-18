import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart' show AppModel, Store, UserModel;
import '../../../screens/chat/vendor_chat.dart';
import '../../../services/service_config.dart';
import '../../../services/services.dart';
import '../../../widgets/common/flux_image.dart';
import '../../../widgets/common/start_rating.dart';
import 'shop_model/export.dart';
import 'shop_screen/export.dart';
import 'store_info.dart';

class StoreDetailScreen extends StatefulWidget {
  final Store? store;

  const StoreDetailScreen({this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailState();
}

class _StoreDetailState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _titles = [
    'shop',
    'search',
    'categories',
    'info',
  ];

  final _pageController = PageController();
  TabController? _tabController;

  void _onPageChange(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.linear);
  }

  List<Widget> _buildTabs() {
    return List.generate(_titles.length, (index) {
      switch (_titles[index]) {
        case 'shop':
          {
            return Tab(text: S.of(context).shop);
          }
        case 'search':
          {
            return Tab(text: S.of(context).search);
          }
        case 'categories':
          {
            return Tab(text: S.of(context).categories);
          }
        case 'info':
          {
            return Tab(text: S.of(context).contact);
          }
        default:
          return Container();
      }
    });
  }

  List<Widget> _buildPages() {
    return List.generate(_titles.length, (index) {
      switch (_titles[index]) {
        case 'shop':
          {
            return Shop();
          }
        case 'search':
          {
            return ShopSearchScreen();
          }
        case 'categories':
          {
            return const ShopCategoryScreen();
          }
        case 'info':
          {
            return StoreInfo(
              store: widget.store!,
            );
          }
        default:
          return Container();
      }
    });
  }

  List<Widget> _buildStoreHour() {
    return [
      const SizedBox(
        height: 5.0,
      ),
      Row(
        children: [
          Icon(
            Icons.schedule,
            color:
                widget.store!.storeHour!.isOpen() ? Colors.green : Colors.red,
            size: 12.0,
          ),
          const SizedBox(
            width: 2.0,
          ),
          Text(
            widget.store!.storeHour!.isOpen()
                ? S.of(context).openNow
                : S.of(context).closeNow,
            style: Theme.of(context).textTheme.caption!.copyWith(
                color: widget.store!.storeHour!.isOpen()
                    ? Colors.green
                    : Colors.red,
                fontSize: 12.0),
          ),
        ],
      ),
    ];
  }

  @override
  void initState() {
    _tabController = TabController(length: _titles.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl = widget.store!.banner ?? kDefaultStoreImage;
    final user = Provider.of<UserModel>(context, listen: false).user;
    final appModel = Provider.of<AppModel>(context, listen: false);
    final theme = Theme.of(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShopOnSaleModel>(
          create: (_) =>
              ShopOnSaleModel(widget.store!.id!, lang: appModel.langCode),
          lazy: false,
        ),
        ChangeNotifierProvider<ShopPopularModel>(
          create: (_) =>
              ShopPopularModel(widget.store!.id!, lang: appModel.langCode),
          lazy: false,
        ),
        ChangeNotifierProvider<ShopNewModel>(
          create: (_) =>
              ShopNewModel(widget.store!.id!, lang: appModel.langCode),
          lazy: false,
        ),
        ChangeNotifierProvider<ShopSearchModel>(
          create: (_) => ShopSearchModel(widget.store!.id!),
          lazy: false,
        ),
        ChangeNotifierProvider<ShopCategoryModel>(
          create: (_) =>
              ShopCategoryModel(widget.store!.id!, lang: appModel.langCode),
          lazy: false,
        ),
        ChangeNotifierProvider<ShopReviewModel>(
          create: (_) => ShopReviewModel(widget.store!.id!),
          lazy: false,
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: VendorChat(
          user: user,
          store: widget.store,
        ),
        body: DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: 200.0,
                  leading: IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.5),
                      child: const Icon(Icons.arrow_back),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  actions: [
                    if (firebaseDynamicLinkConfig['isEnabled'] &&
                        Config().isWooType)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: IconButton(
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              Services().firebase.shareDynamicLinkProduct(
                                    itemUrl: widget.store!.link,
                                  );
                            }),
                      ),
                  ],
                  pinned: true,
                  flexibleSpace: LayoutBuilder(builder:
                      (BuildContext context, BoxConstraints constraints) {
                    var top = constraints.biggest.height;
                    final vacationSettings = widget.store!.vacationSettings;
                    return FlexibleSpaceBar(
                        title: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: top < 110 ? 1.0 : 0.0,
                          child: Text(
                            widget.store!.name!,
                            style: Theme.of(context)
                                .textTheme
                                .headline6!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        centerTitle: true,
                        background: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            FluxImage(imageUrl: bannerUrl),
                            Container(
                              color: Colors.black12.withOpacity(0.5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const SizedBox(
                                        width: 40.0,
                                      ),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.store!.name!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5!
                                                  .copyWith(
                                                      color: Colors.white),
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            SmoothStarRating(
                                              rating: widget.store!.rating,
                                              size: 20.0,
                                            ),

                                            /// Dokan condition
                                            if (widget.store!.storeHour !=
                                                    null &&
                                                vacationSettings == null)
                                              ..._buildStoreHour(),

                                            /// WCFM condition
                                            if (widget.store!.storeHour !=
                                                    null &&
                                                vacationSettings != null)
                                              if (vacationSettings
                                                      .vacationMode &&
                                                  vacationSettings.isOpen())
                                                ..._buildStoreHour(),
                                            if (vacationSettings != null &&
                                                (vacationSettings
                                                        .vacationMode &&
                                                    vacationSettings
                                                        .isOpen())) ...[
                                              const SizedBox(
                                                height: 5.0,
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.schedule,
                                                    color: Colors.red,
                                                    size: 12.0,
                                                  ),
                                                  const SizedBox(
                                                    width: 2.0,
                                                  ),
                                                  Text(
                                                    S.of(context).onVacation,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption!
                                                        .copyWith(
                                                            color: Colors.red,
                                                            fontSize: 12.0),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 20.0,
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: InkWell(
                                      onTap: () {
                                        final model =
                                            Provider.of<ShopReviewModel>(
                                                context,
                                                listen: false);
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    ChangeNotifierProvider<
                                                        ShopReviewModel>.value(
                                                      value: model,
                                                      child:
                                                          const ShopReviewScreen(),
                                                    )));
                                      },
                                      borderRadius: BorderRadius.circular(5.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 5.0),
                                        margin:
                                            const EdgeInsets.only(right: 10.0),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            color:
                                                Colors.white.withOpacity(0.5)),
                                        child: Text(
                                          S.of(context).seeReviews,
                                          style: theme.textTheme.caption,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20.0,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ));
                  }),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.secondary,
                      unselectedLabelColor: theme.primaryColor,
                      onTap: _onPageChange,
                      tabs: _buildTabs(),
                      labelStyle: theme.primaryTextTheme.bodyText1,
                      unselectedLabelStyle: theme.primaryTextTheme.bodyText1,
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController!.animateTo(index);
              },
              children: _buildPages(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
