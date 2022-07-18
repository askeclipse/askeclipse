import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../common/config.dart';
import '../../../../common/constants.dart';
import '../../../../generated/l10n.dart';
import '../../../../models/app_model.dart';
import '../../../../modules/store_open_option/store_open_option.dart';
import '../../../../screens/settings/language_screen.dart';
import '../../../../widgets/common/common_setting_item.dart';
import '../../models/authentication_model.dart';
import '../store_settings_screen/store_settings_screen.dart';

class VendorAdminSettingScreen extends StatelessWidget {
  final isFromMV;

  const VendorAdminSettingScreen({Key? key, this.isFromMV = false})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authModel =
        Provider.of<VendorAdminAuthenticationModel>(context, listen: false);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: Text(
          S.of(context).settings,
          style: Theme.of(context).primaryTextTheme.headline5,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).backgroundColor,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SizedBox(
          width: size.width,
          height: size.height,
          child: Selector<AppModel, bool>(
            selector: (_, model) => model.darkTheme,
            builder: (context, darkTheme, _) => SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        NetworkImage(authModel.user!.picture ?? kDefaultImage),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${authModel.user!.firstName} ${authModel.user!.lastName}',
                    style: Theme.of(context).primaryTextTheme.headline6,
                  ),
                  const SizedBox(height: 30),

                  /// It will support other platforms in future commits.
                  /// For now, only support WCFM.
                  if (authModel.state ==
                              VendorAdminAuthenticationModelState.loggedIn &&
                          serverConfig['platform'] == null ||
                      serverConfig['platform'] == 'wcfm') ...[
                    CommonSettingItem(
                      leadingIcon: CupertinoIcons.person_crop_rectangle,
                      title: S.of(context).visitStore,
                      actionIcon: Icons.arrow_forward_ios_outlined,
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => StoreSettingScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CommonSettingItem(
                      leadingIcon: CupertinoIcons.house,
                      title: S.of(context).storeVacation,
                      actionIcon: Icons.arrow_forward_ios_outlined,
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => StoreOpenOptionIndex(
                                userId: authModel.user!.id!,
                                cookie: authModel.user!.cookie!)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (!isFromMV) ...[
                    CommonSettingItem(
                      leadingIcon: CupertinoIcons.globe,
                      title: S.of(context).language,
                      actionIcon: Icons.arrow_forward_ios_outlined,
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => LanguageScreen()),
                      ),
                    ),
                    CommonSettingItem(
                      leadingIcon: darkTheme
                          ? CupertinoIcons.moon_stars
                          : CupertinoIcons.sun_min,
                      title: S.of(context).darkTheme,
                      isSwitchedOn: darkTheme,
                      onTap: () => Provider.of<AppModel>(context, listen: false)
                          .updateTheme(!darkTheme),
                    ),
                    CommonSettingItem(
                        leadingIcon: Icons.person,
                        title: S.of(context).logout,
                        onTap: authModel.logout),
                  ],
                ],
              ),
            ),
          )),
    );
  }
}
