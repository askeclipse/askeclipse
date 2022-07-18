import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:core';

import 'package:quiver/strings.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/entities/delivery_stat.dart';
import '../../../models/entities/index.dart';
import '../../../models/entities/wcfm_notification.dart';
import '../../woocommerce/services/woo_commerce.dart';
import 'delivery_api.dart';

class DeliveryService extends WooCommerceService {
  DeliveryService({
    required String domain,
    required String consumerSecret,
    required String consumerKey,
  })  : deliveryApi = DeliveryAPI(url: domain),
        super(
          domain: domain,
          consumerSecret: consumerSecret,
          consumerKey: consumerKey,
        );

  final DeliveryAPI deliveryApi;

  /// App Authentication

  @override
  Future<Map<String, dynamic>> updateUserInfo(
      Map<String, dynamic> json, String? token) async {
    try {
      final body = convert.jsonEncode({...json, 'cookie': token});
      final response = await httpPost(
          '$domain/wp-json/api/flutter_user/update_user_profile'.toUri()!,
          body: body,
          headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        data['cookie'] = token;
        return data;
      } else {
        throw Exception('Can not update user infor');
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<User?> login({username, password}) async {
    var cookieLifeTime = 120960000000;
    try {
      final response = await httpPost(
          '$domain/wp-json/api/flutter_user/generate_auth_cookie/?insecure=cool&$isSecure'
              .toUri()!,
          body: convert.jsonEncode({
            'seconds': cookieLifeTime.toString(),
            'username': username,
            'password': password
          }));

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && isNotBlank(body['cookie'])) {
        return await getUserInfo(body['cookie']);
      }
    } catch (err) {
      printLog(err);
    }
    return null;
  }

  @override
  Future<User?> loginGoogle({String? token}) async {
    const cookieLifeTime = 120960000000;

    try {
      var endPoint =
          '$domain/wp-json/api/flutter_user/google_login/?second=$cookieLifeTime'
          '&access_token=$token';

      var response = await httpGet(endPoint.toUri()!);

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null || jsonDecode['cookie'] == null) {
        throw Exception(jsonDecode['message']);
      }

      return User.fromWooJson(jsonDecode);
    } catch (e) {
      printLog(e);
    }
    return null;
  }

  @override
  Future<User?> loginFacebook({String? token}) async {
    const cookieLifeTime = 120960000000;

    try {
      var endPoint =
          '$domain/wp-json/api/flutter_user/fb_connect/?second=$cookieLifeTime'
          '&access_token=$token';

      var response = await httpGet(endPoint.toUri()!);

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null || jsonDecode['cookie'] == null) {
        throw Exception(jsonDecode['message']);
      }

      return User.fromWooJson(jsonDecode);
    } catch (e) {
      printLog(e);
    }
    return null;
  }

  @override
  Future<User?> createUser({
    String? firstName,
    String? lastName,
    String? username,
    String? password,
    String? phoneNumber,
    bool isVendor = false,
  }) async {
    try {
      var niceName = '${firstName!} ${lastName!}';
      var role = 'wcfm_delivery_boy';
      if (serverConfig['platform'] != null) {
        if (['woo', 'dokan'].contains(serverConfig['platform'])) {
          role = 'driver';
        }
      }

      final response = await httpPost(
          '$domain/wp-json/api/flutter_user/sign_up_2/?insecure=cool&$isSecure'
              .toUri()!,
          body: convert.jsonEncode({
            'user_email': username,
            'user_login': username,
            'username': username,
            'first_name': firstName,
            'last_name': lastName,
            'user_pass': password,
            'email': username,
            'user_nicename': niceName,
            'display_name': niceName,
            'phone': phoneNumber,
            'role': role
          }));

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && body['message'] == null) {
        var cookie = body['cookie'];
        return await getUserInfo(cookie);
      }
    } catch (err) {
      printLog(err);
    }
    return null;
  }

  @override
  Future<User?> loginApple({String? token}) async {
    try {
      var endPoint = '$domain/wp-json/api/flutter_user/apple_login';

      var response = await httpPost(endPoint.toUri()!,
          body: convert.jsonEncode({'token': token}),
          headers: {'Content-Type': 'application/json'});

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null || jsonDecode['cookie'] == null) {
        throw Exception(jsonDecode['message']);
      }

      return User.fromWooJson(jsonDecode);
    } catch (e) {
      printLog(e);
    }
    return null;
  }

  @override
  Future<User?> getUserInfo(cookie) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      final response = await httpGet(
          '$domain/wp-json/api/flutter_user/get_currentuserinfo?token=$base64Str&$isSecure'
              .toUri()!);
      final body = convert.jsonDecode(response.body);
      if (body['user'] != null) {
        var user = body['user'];
        return User.fromAuthUser(user, cookie);
      } else {
        if (body['message'] != 'Invalid cookie') {
          throw Exception(body['message']);
        }
        return null;
      }
    } catch (e) {
      printLog('delivery.dart getUserInfo: $e');
      rethrow;
    }
  }

  @override
  Future<User> loginSMS({String? token}) async {
    try {
      var endPoint =
          '$domain/wp-json/api/flutter_user/firebase_sms_login_v2?phone=$token';

      var response = await httpGet(endPoint.toUri()!);

      var jsonDecode = convert.jsonDecode(response.body);

      if (jsonDecode['wp_user_id'] == null || jsonDecode['cookie'] == null) {
        throw Exception(jsonDecode['message']);
      }

      return User.fromWooJson(jsonDecode);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Order>> getDeliveryOrders(
      {required String cookie,
      int page = 1,
      int perPage = 10,
      String? status,
      String? search}) async {
    var list = <Order>[];
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint =
          '$domain/wp-json/delivery/orders?page=$page&per_page=$perPage&token=$base64Str}';
      if (status != null && status.isNotEmpty) {
        endpoint += '&status=$status';
      }
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=$search';
      }
      if (serverConfig['platform'] != null) {
        endpoint += '&platform=${serverConfig['platform']}';
      }
      final response = await httpGet(
        endpoint.toUri()!,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
        },
      );
      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);

        for (var item in result['response']) {
          list.add(Order.fromJson(item));
        }
      }
    } catch (e) {
      printLog('delivery.dart getDeliveryOrders: $e');
    }
    return list;
  }

  Future<Order?> getDeliveryOrder({
    required String cookie,
    required String orderId,
  }) async {
    try {
      var endpoint = 'orders/$orderId';
      var response = await wcApi.getAsync(endpoint);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        return Order.fromJson(response);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://docs.inspireui.com/fluxstore/woocommerce-setup/
      rethrow;
    }
  }

  Future<DeliveryStat> getDeliveryStat({
    required String cookie,
  }) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint = '$domain/wp-json/delivery/stat?token=$base64Str}';
      if (serverConfig['platform'] != null) {
        endpoint += '&platform=${serverConfig['platform']}';
      }
      final response = await httpGet(
        endpoint.toUri()!,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
        },
      );
      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        return DeliveryStat.fromJson(result['response']);
      }
    } catch (e) {
      printLog('delivery.dart getDeliveryStat: $e');
    }
    return DeliveryStat(delivered: 0, pending: 0, total: 0);
  }

  Future<List<WCFMNotification>> getNotifications(
      {required cookie, int? page, int? perPage}) async {
    var notifications = <WCFMNotification>[];
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint =
          '$domain/wp-json/delivery/notifications?page=$page&per_page=$perPage&token=$base64Str';
      if (serverConfig['platform'] != null) {
        endpoint += '&platform=${serverConfig['platform']}';
      }
      var response = await httpGet(endpoint.toUri()!);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result['response']) {
          if (['woo', 'dokan'].contains(serverConfig['platform'])) {
            notifications.add(WCFMNotification.fromWooJson(item));
            continue;
          }
          notifications.add(WCFMNotification.fromJson(item));
        }
      }
    } catch (e) {
      printLog('delivery.dart getNotifications: $e');
    }
    return notifications;
  }

  Future<int> updateInfo(cookie, {firstName, lastName, phone, avatar}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint = '$domain/wp-json/delivery/profile';
      var data = {
        'token': base64Str,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      };

      var response = await httpPut(endpoint.toUri()!, body: data);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        return result['response'];
      }
    } catch (e) {
      printLog('delivery.dart updateInfo: $e');
      return -1;
    }
    return 1;
  }

  Future<String?> updatePassword(cookie, {password, newPassword}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint = '$domain/wp-json/delivery/profile';
      var data = {
        'token': base64Str,
        'new_password': newPassword,
        'password': password,
      };

      var response = await httpPut(endpoint.toUri()!, body: data);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        return result['response'];
      }
    } catch (e) {
      printLog('delivery.dart updateInfo: $e');
    }
    return null;
  }

  Future<int> updateDeliveryOrder(cookie, orderId) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint = '$domain/wp-json/delivery/orders';
      var data = {
        'token': base64Str,
        'order_id': orderId,
      };
      if (serverConfig['platform'] != null) {
        data['platform'] = serverConfig['platform'];
      }

      var response = await httpPut(endpoint.toUri()!, body: data);
      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        return result['response'];
      }
    } catch (e) {
      printLog('delivery.dart updateDeliveryOrder: $e');
      return -1;
    }
    return 1;
  }

  Future<List<OrderNote>?> getOrderNotes(String orderId) async {
    var list = <OrderNote>[];
    try {
      final endpoint =
          '$domain/wp-json/wc/v2/orders/$orderId/notes?type=customer&per_page=100&consumer_key=${serverConfig['consumerKey']}&consumer_secret=${serverConfig['consumerSecret']}';
      var response = await httpGet(endpoint.toUri()!);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result) {
          list.add(OrderNote.fromJson(item));
        }
      }
    } catch (e) {
      printLog(e);
    }
    return list;
  }

  Future<int> setOffTime(String cookie, bool isOffline) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var data = {
        'token': base64Str,
        'is_available': isOffline.toString(),
      };
      if (serverConfig['platform'] != null) {
        data['platform'] = serverConfig['platform'];
      }
      final endpoint = '$domain/wp-json/delivery/offtime';
      var response = await httpPut(endpoint.toUri()!, body: data);
      return response.statusCode;
    } catch (e) {
      printLog(e);
    }
    return 0;
  }
}
