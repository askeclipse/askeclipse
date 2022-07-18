import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:geocode/geocode.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:inspireui/utils/logs.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/order/order.dart';
import '../../../models/vendor/store_model.dart';
import '../delivery_tool/delivery_tools.dart';
import '../models/delivery_order_model.dart';
import '../models/map_model.dart';
import 'order_detail_screen/widgets/info_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<Marker> markers = <Marker>{};
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final model = Provider.of<MapModel>(context, listen: false);

      Future.delayed(const Duration(seconds: 1))
          .then((value) => _moveToCurrentLocation(
                model.locationData?.latitude ?? 0.0,
                model.locationData?.longitude ?? 0.0,
              ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Consumer2<MapModel, DeliveryOrderModel>(
          builder: (_, model, model2, __) => Stack(
            children: [
              GoogleMap(
                markers: markers,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(
                    target: LatLng(
                      model.locationData?.latitude ?? 0.0,
                      model.locationData?.longitude ?? 0.0,
                    ),
                    zoom: 16.0),
                onMapCreated: _onMapCreated,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    height: 205,
                    child: _buildCardSwiper(model2.orders)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Widget _buildCardSwiper(List<Order> orders) {
    /// If the app is WooCommerce Delivery

    if (serverConfig['platform'] != null &&
        ['woo', 'dokan'].contains(serverConfig['platform'])) {
      var pendingOrders = <Order>[];
      for (var element in orders) {
        if (element.deliveryStatus == DeliveryStatus.pending) {
          pendingOrders.add(element);
        }
      }
      return Swiper(
        loop: false,
        itemBuilder: (context, index) =>
            _cardWidget(order: pendingOrders[index]),
        itemCount: pendingOrders.length,
        onIndexChanged: (index) {
          _moveToCard(order: pendingOrders[index]);
        },
        onTap: (index) => _moveToCard(order: pendingOrders[index]),
      );
    }

    /// If the app is WCFM Delivery
    var stores = [];
    for (var element in orders) {
      if (element.deliveryStatus == DeliveryStatus.pending) {
        final index =
            stores.indexWhere((store) => store.id == element.wcfmStore!.id);
        if (index == -1) {
          stores.add(element.wcfmStore);
        }
      }
    }
    return Swiper(
      loop: false,
      itemBuilder: (context, index) => _cardWidget(store: stores[index]),
      itemCount: stores.length,
      onIndexChanged: (index) {
        _moveToCard(store: stores[index]);
      },
      onTap: (index) => _moveToCard(store: stores[index]),
    );
  }

  void _moveToCard({Store? store, Order? order}) {
    if (order != null) {
      var geoCode = GeoCode();

      try {
        geoCode
            .forwardGeocoding(
                address: DeliveryTools.formatAddress(order.shipping!))
            .then((coordinates) {
          var lat = coordinates.latitude;
          var long = coordinates.longitude;
          if (lat != null && long != null) {}
          _mapController.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(lat!, long!), zoom: 16.0)));
          markers.clear();
          markers.add(Marker(
              markerId: MarkerId('${order.id}'),
              infoWindow: InfoWindow(
                  title: DeliveryTools.formatAddress(order.shipping!),
                  onTap: () {}),
              position: LatLng(lat, long)));
          setState(() {});
        });
      } catch (e) {
        printLog(e);
      }
      return;
    }
    if (store!.lat != null && store.long != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(store.lat!, store.long!), zoom: 16.0)));
      markers.clear();
      markers.add(Marker(
          markerId: MarkerId('${store.id}'),
          infoWindow: InfoWindow(title: store.name, onTap: () {}),
          position: LatLng(store.lat!, store.long!)));
      setState(() {});
    }
  }

  void _moveToCurrentLocation(latitude, longitude) {
    _mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(latitude, longitude), zoom: 16.0)));
  }

  void _launchMap(address, {latitude, longitude}) {
    if (latitude != null && longitude != null) {
      MapsLauncher.launchCoordinates(latitude!, longitude!);
      return;
    }
    MapsLauncher.launchQuery(address);
  }

  Widget _buildCustomerWidget(Order order) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.only(top: 20.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  height: 70.0,
                  child: InfoWidget(
                    title: S.of(context).address,
                    content: DeliveryTools.formatAddress(order.shipping!),
                    icon: CupertinoIcons.house_fill,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 70.0,
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoWidget(
                          title: S.of(context).phone,
                          content: order.shipping?.phoneNumber ?? '',
                          icon: CupertinoIcons.phone_fill,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(
                                  color: order.shipping?.phoneNumber == null
                                      ? null
                                      : order.shipping!.phoneNumber!
                                              .trim()
                                              .isNotEmpty
                                          ? Theme.of(context).primaryColor
                                          : null),
                          onCallBack: order.shipping?.phoneNumber == null
                              ? null
                              : order.shipping!.phoneNumber!.trim().isNotEmpty
                                  ? () async {
                                      await Tools.launchURL(
                                          'tel:${order.shipping?.phoneNumber}');
                                    }
                                  : null,
                        ),
                      ),
                      InkWell(
                        onTap: () => _launchMap(
                          DeliveryTools.formatAddress(order.shipping!),
                        ),
                        child: Text(
                          S.of(context).direction,
                          style: theme.textTheme.subtitle2!
                              .copyWith(color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 15.0,
            ),
            Container(
              padding: const EdgeInsets.all(6.0),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: DeliveryStatus.pending.displayColor(context),
                  child: const Icon(
                    Icons.pedal_bike,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreWidget(Store store) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.only(top: 10.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  height: 70.0,
                  child: InfoWidget(
                    title: S.of(context).address,
                    content: store.address ?? '',
                    icon: CupertinoIcons.house_fill,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 70.0,
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoWidget(
                          title: S.of(context).phone,
                          content: store.phone ?? '',
                          icon: CupertinoIcons.phone_fill,
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                  color: store.phone == null
                                      ? null
                                      : store.phone!.trim().isNotEmpty
                                          ? Theme.of(context).primaryColor
                                          : null),
                          onCallBack: store.phone == null
                              ? null
                              : store.phone!.trim().isNotEmpty
                                  ? () async {
                                      await Tools.launchURL(
                                          'tel:${store.phone}');
                                    }
                                  : null,
                        ),
                      ),
                      InkWell(
                        onTap: () => _launchMap(
                          store.address,
                          latitude: store.lat,
                          longitude: store.long,
                        ),
                        child: Text(
                          S.of(context).direction,
                          style: theme.textTheme.subtitle2!
                              .copyWith(color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(
              width: 15.0,
            ),
            Container(
              padding: const EdgeInsets.all(6.0),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: DeliveryStatus.pending.displayColor(context),
                  child: const Icon(
                    Icons.pedal_bike,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardWidget({Store? store, Order? order}) {
    if (order != null) {
      return _buildCustomerWidget(order);
    }
    return _buildStoreWidget(store!);
  }
}
