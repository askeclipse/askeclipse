import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools/image_tools.dart';
import '../../../common/tools/tools.dart';
import '../../../models/index.dart';

class StoreInfo extends StatelessWidget {
  final Store store;

  const StoreInfo({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget _buildContact(IconData icon, String data,
        {VoidCallback? onCallBack}) {
      return GestureDetector(
        onTap: onCallBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 20.0),
              Icon(
                icon,
                color: onCallBack != null ? Colors.blue : null,
                size: 22,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: Text(
                  data,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: onCallBack != null ? Colors.blue : null,
                      ),
                ),
              ),
              const SizedBox(width: 20.0),
            ],
          ),
        ),
      );
    }

    Widget _buildMap() {
      if (isDesktop || kIsWeb) {
        return const SizedBox();
      }
      if (store.lat == null || store.long == null) {
        return const SizedBox();
      }

      var googleMapsApiKey;
      if (isIos) {
        googleMapsApiKey = kGoogleApiKey.ios;
      } else if (isAndroid) {
        googleMapsApiKey = kGoogleApiKey.android;
      } else {
        googleMapsApiKey = kGoogleApiKey.web;
      }

      var mapURL = Uri(
        scheme: 'https',
        host: 'maps.googleapis.com',
        port: 443,
        path: '/maps/api/staticmap',
        queryParameters: {
          'size': '800x600',
          'center': '${store.lat},${store.long}',
          'zoom': '13',
          'maptype': 'roadmap',
          'markers': 'color:red|label:C|${store.lat},${store.long}',
          'key': '$googleMapsApiKey'
        },
      );

      return ImageTools.image(
        url: mapURL.toString(),
        width: MediaQuery.of(context).size.width,
        height: 300,
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20.0),
        if (store.address != null && store.address!.isNotEmpty)
          _buildContact(CupertinoIcons.placemark_fill, store.address!),
        if (store.email != null && store.email!.isNotEmpty)
          _buildContact(CupertinoIcons.mail_solid, store.email!,
              onCallBack: () {
            Tools.launchURL('mailto:${store.email!}');
          }),
        if (store.phone != null && store.phone!.isNotEmpty)
          _buildContact(CupertinoIcons.phone_fill, store.phone!,
              onCallBack: () {
            Tools.launchURL('tel:${store.phone!}');
          }),
        Flexible(child: _buildMap()),
      ],
    );
  }
}
