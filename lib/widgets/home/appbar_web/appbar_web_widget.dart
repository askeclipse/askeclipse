import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';
import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools/adaptive_tools.dart';
import '../../../common/tools/navigate_tools.dart';
import '../../../common/tools/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/user_model.dart';
import '../../../modules/dynamic_layout/index.dart';
import '../../../routes/flux_navigate.dart';
import '../../common/flux_image.dart';
import '../../common/webview.dart';
import '../preview_overlay.dart';
import 'button_language.dart';

const kHeightAppBarWeb = 140.0;
const kStyleTextInAppBarWeb = TextStyle(
  fontWeight: FontWeight.normal,
  fontSize: 12,
);

class AppBarWebWidget extends StatefulWidget {
  final bool isPinAppBar;
  final Map<String, dynamic> config;
  final Function()? onRefresh;

  const AppBarWebWidget({
    Key? key,
    this.isPinAppBar = true,
    this.onRefresh,
    this.config = const {},
  }) : super(key: key);

  @override
  State<AppBarWebWidget> createState() => _AppBarWebWidgetState();
}

class _AppBarWebWidgetState extends State<AppBarWebWidget> {
  void _onTapNotify() => Navigator.of(context).pushNamed(RouteList.notify);

  void _onTapOpenWeb(String? urlWeb) {
    if (urlWeb?.isEmpty ?? true) {
      return;
    }

    if (kIsWeb || isDisplayDesktop(context)) {
      Tools.launchURL(urlWeb);
      return;
    }

    FluxNavigate.push(
      MaterialPageRoute(
        builder: (context) =>
            WebView(url: urlWeb, title: S.of(context).support),
      ),
      forceRootNavigator: true,
    );
  }

  void _onTapSupport() {
    final urlHelp = kAdvanceConfig.supportPageUrl;
    _onTapOpenWeb(urlHelp);
  }

  void _onTapSignout() =>
      Provider.of<UserModel>(context, listen: false).logout();

  void _onTapSignUp() => NavigateTools.navigateRegister(context);

  void _onTapSignIn() => Navigator.of(
        App.fluxStoreNavigatorKey.currentContext!,
      ).pushNamed(RouteList.login);

  void _onTapDownloadPage() => _onTapOpenWeb(kAdvanceConfig.downloadPageUrl);

  void _onTapSearch() => Navigator.of(App.fluxStoreNavigatorKey.currentContext!)
      .pushNamed(RouteList.homeSearch);

  void _onTapCart() => FluxNavigate.pushNamed(RouteList.cart);

  @override
  Widget build(BuildContext context) {
    final colorAppBar = Theme.of(context).appBarTheme.backgroundColor;

    return SliverAppBar(
      pinned: false,
      snap: true,
      floating: true,
      titleSpacing: 0,
      elevation: 0,
      forceElevated: true,
      toolbarHeight: kHeightAppBarWeb,
      backgroundColor: colorAppBar,
      title: PreviewOverlay(
          index: 0,
          config: widget.config,
          builder: (value) {
            return Container(
              height: kHeightAppBarWeb,
              color: colorAppBar,
              constraints: const BoxConstraints(maxWidth: kLimitWidthScreen),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (_, constrain) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 50,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _renderButton(
                                    S.of(context).downloadApp,
                                    onTap: _onTapDownloadPage,
                                  ),
                                  _renderSpace(),
                                  _renderSocialConnect(),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _renderButton(
                                    S.of(context).notifications,
                                    icon: CupertinoIcons.bell,
                                    onTap: _onTapNotify,
                                  ),
                                  _renderButton(
                                    S.of(context).support,
                                    icon: CupertinoIcons.question_circle,
                                    onTap: _onTapSupport,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: ButtonChooseLanguage(
                                      style: kStyleTextInAppBarWeb,
                                    ),
                                  ),
                                  ..._renderAuth(context),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 60,
                                    width: constrain.maxWidth * 0.2,
                                    child: InkWell(
                                      hoverColor: Colors.transparent,
                                      onTap: widget.onRefresh,
                                      child: const FluxImage(
                                        imageUrl: kLogo,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: constrain.maxWidth * 0.7,
                                    child: HeaderSearch(
                                      config: HeaderConfig(radius: 3.0),
                                      onSearch: _onTapSearch,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: InkWell(
                                      hoverColor: Colors.transparent,
                                      onTap: _onTapCart,
                                      child: const FluxImage(
                                        imageUrl:
                                            'assets/icons/tabs/icon-cart2.png',
                                        fit: BoxFit.contain,
                                        width: 30,
                                        height: 30,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
    );
  }

  Widget _renderSocialConnect() {
    final listSocialData = kAdvanceConfig.socialConnectUrls;
    if (listSocialData.isNotEmpty) {
      final listSocialWidget = <Widget>[];

      for (var social in listSocialData) {
        if ((social.name.isNotEmpty) &&
            (social.url.isNotEmpty) &&
            (social.icon.isNotEmpty)) {
          listSocialWidget.add(
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: InkWell(
                hoverColor: Colors.transparent,
                child: FluxImage(
                  imageUrl: social.icon,
                  width: 20,
                  height: 20,
                ),
                onTap: () => _onTapOpenWeb(social.url),
              ),
            ),
          );
        }
      }

      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Text(
                S.of(context).connect,
                style: kStyleTextInAppBarWeb,
              ),
            ),
            ...List.generate(
                listSocialWidget.length, (index) => listSocialWidget[index]),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  List<Widget> _renderAuth(BuildContext context) {
    final loggedIn = Provider.of<UserModel>(context).loggedIn;

    return [
      if (loggedIn)
        _renderButton(S.of(context).logout, onTap: _onTapSignout)
      else ...[
        _renderButton(S.of(context).login, onTap: _onTapSignIn),
        _renderSpace(),
        _renderButton(S.of(context).signUp, onTap: _onTapSignUp),
      ]
    ];
  }

  Widget _renderSpace() => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          '|',
          style: kStyleTextInAppBarWeb,
        ),
      );

  Widget _renderButton(String title, {Function()? onTap, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: InkWell(
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(icon, size: 20),
              ),
            Text(
              title,
              style: kStyleTextInAppBarWeb,
            ),
          ],
        ),
      ),
    );
  }
}
