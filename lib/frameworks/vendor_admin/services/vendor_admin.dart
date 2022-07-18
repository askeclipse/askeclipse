import 'dart:convert' as convert;
import 'dart:core';

import 'package:quiver/strings.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/error_codes/error_codes.dart';
import '../../../common/tools.dart';
import '../../../models/entities/delivery_user.dart';
import '../../../models/entities/vacation_settings.dart';
import '../../../models/index.dart'
    show
        Category,
        OrderNote,
        Product,
        ProductAttribute,
        Review,
        SaleStats,
        User,
        VendorAdminVariation,
        WCFMNotification;
import '../../woocommerce/services/woo_commerce.dart';
import '../entities/store_settings.dart';
import 'vendor_admin_api.dart';

class VendorAdminService extends WooCommerceService {
  VendorAdminService({
    required String domain,
    String? blogDomain,
    required String consumerKey,
    required String consumerSecret,
  })  : vendorAdminApi = VendorAdminAPI(url: domain),
        super(
          domain: domain,
          blogDomain: blogDomain,
          consumerSecret: consumerSecret,
          consumerKey: consumerKey,
        );

  final VendorAdminAPI vendorAdminApi;

  Future<SaleStats?> getSaleStats({required cookie}) async {
    try {
      var endpoint = '';
      var token = EncodeUtils.encodeCookie(cookie);
      endpoint =
          '${serverConfig['url']}/wp-json/vendor-admin/sale-stats?token=$token&platform=${serverConfig['platform']}';
      printLog(endpoint);
      var response = await httpGet(endpoint.toUri()!);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        return SaleStats.fromMap(result['response']);
      }
      return null;
    } catch (e) {
      printLog(e);
      rethrow;
    }
  }

  Future<List<Review>> getVendorReviews(
      {required String cookie, String? status, int? page, int? perPage}) async {
    var list = <Review>[];
    try {
      var token = EncodeUtils.encodeCookie(cookie);
      var response = await httpGet(
          '${serverConfig['url']}/wp-json/vendor-admin/reviews?page=$page&per_page=$perPage&status_type=$status&token=$token&platform=${serverConfig['platform']}'
              .toUri()!);
      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result['response']) {
          if (serverConfig['platform'] == 'dokan') {
            list.add(Review.fromDokanJson(item));
            continue;
          }
          list.add(Review.fromWCFMJson(item));
        }
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getVendorProducts(String cookie,
      {int? page, int? perPage, String? searchName}) async {
    var list = <Product>[];
    try {
      var token = EncodeUtils.encodeCookie(cookie);
      var endpoint =
          '${serverConfig['url']}/wp-json/vendor-admin/products?page=$page&per_page=$perPage&token=$token&platform=${serverConfig['platform']}';
      if (searchName != null && searchName.isNotEmpty) {
        endpoint += '&search=$searchName';
      }
      printLog(endpoint);
      var response = await httpGet(endpoint.toUri()!);
      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result['response']) {
          if (['variable', 'simple'].contains(item['type'])) {
            list.add(Product.fromJson(item));
          }
        }
      }
    } catch (e) {
      printLog('vendor_admin.dart getVendorProducts: $e');
    }
    return list;
  }

  Future<List<OrderNote>> getVendorAdminOrderNotes(
      {int page = 1, int perPage = 10, String? orderId}) async {
    var list = <OrderNote>[];
    try {
      var endpoint =
          '${serverConfig['url']}/wp-json/wc/v3/orders/$orderId/notes?page=$page&per_page=$perPage&consumer_key=${serverConfig['consumerKey']}&consumer_secret=${serverConfig['consumerSecret']}';
      final response = await httpGet(endpoint.toUri()!);
      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result) {
          list.add(OrderNote.fromJson(item));
        }
      }
    } catch (e) {
      printLog('vendor_admin.dart getVendorAdminOrderNotes: $e');
    }
    return list;
  }

  Future<void> updateReviewStatus(
      {required String cookie, int? reviewId, required bool isApproved}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      await httpPut(
          "${serverConfig['url']}/wp-json/vendor-admin/reviews/$reviewId"
              .toUri()!,
          body: {
            'token': base64Str,
            'status': isApproved ? '1' : '0',
            'platform': serverConfig['platform'] ?? '',
          });
    } catch (e) {
      printLog('vendor_admin.dart updateReviewStatus: $e');
    }
  }

  Future<List<String?>> getImagesByVendor(
      {String? vendorId, int? page, int? perPage}) async {
    var list = <String?>[];
    try {
      var endpoint =
          '${serverConfig['url']}/wp-json/wp/v2/media?author=$vendorId&page=$page&per_page=$perPage';
      if (serverConfig['platform'] != null &&
          serverConfig['platform'] == 'woo') {
        endpoint =
            '${serverConfig['url']}/wp-json/wp/v2/media?page=$page&per_page=$perPage';
      }
      final response = await httpGet(endpoint.toUri()!);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result) {
          if (item['media_type'] == 'image') {
            list.add(item['guid']['rendered']);
          }
        }
      }
    } catch (e) {
      printLog('vendor_admin.dart getImagesByVendor: $e');
    }
    return list;
  }

  Future<Product> updateProduct(
      {required String cookie,
      required Product product,
      required List<dynamic> images,
      dynamic featuredImage,
      String status = '',
      String tags = '',
      Map<dynamic, dynamic>? productAttributes,
      List<VendorAdminVariation>? variations}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);

      /// Notice: Don't try to modify these because they will be handled on the server
      var categoryIds = '';
      for (var id in product.categoryIds) {
        categoryIds += '$id,';
      }
      var preparedImages =
          await ImageTools.compressAndConvertImagesForUploading(images);

      var preparedFeaturedImage = await ImageTools.compressImage(featuredImage);

      /// End Notice
      final response = await httpPut(
          "${serverConfig['url']}/wp-json/vendor-admin/products".toUri()!,
          body: {
            'token': base64Str,
            'id': product.id,
            'sku': product.sku,
            'name': product.name,
            'featured': product.isFeatured! ? 'true' : 'false',
            'in_stock': product.stockQuantity! > 0 ? 'true' : 'false',
            'regular_price': product.regularPrice,
            'sale_price': product.salePrice,
            'description': product.description,
            'short_description': product.shortDescription,
            'manage_stock': product.manageStock ? 'true' : 'false',
            'stock_quantity': product.stockQuantity.toString(),
            'categories': categoryIds,
            'images': preparedImages,
            'featuredImage': preparedFeaturedImage,
            'status': product.status,
            'type': product.type,
            'tags': tags,
            'productAttributes': convert.jsonEncode(productAttributes),
            'variations': convert.jsonEncode(variations),
            'platform': serverConfig['platform'] ?? '',
          });
      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        if (['variable', 'simple'].contains(result['response']['type'])) {
          return Product.fromJson(result['response']);
        }
      }
    } catch (e) {
      printLog('vendor_admin.dart updateProduct: $e');
    }
    return product;
  }

  Future<Product> createVendorAdminProduct(
      {required String cookie,
      required Product product,
      required List<dynamic> images,
      dynamic featuredImage,
      String status = '',
      String tags = '',
      Map<dynamic, dynamic>? productAttributes,
      List<VendorAdminVariation>? variations}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);

      var preparedImages =
          await ImageTools.compressAndConvertImagesForUploading(images);

      var data = {
        'token': base64Str,
        'platform': serverConfig['platform'] ?? '',
        ...product.toManagerJson(),
        'images': preparedImages,
      };

      /// if image is empty, the image will be removed on the server
      var preparedFeaturedImage = '';
      if (featuredImage != null) {
        preparedFeaturedImage = await ImageTools.compressImage(featuredImage);
      }
      data['featuredImage'] = preparedFeaturedImage;
      final response = product.id != null
          ? await httpPut(
              "${serverConfig['url']}/wp-json/vendor-admin/products".toUri()!,
              body: data)
          : await httpPost(
              "${serverConfig['url']}/wp-json/vendor-admin/products".toUri()!,
              body: data);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        if (['variable', 'simple'].contains(result['response']['type'])) {
          return Product.fromJson(result['response']);
        }
      }
    } catch (e) {
      printLog('vendor_admin.dart createVendorAdminProduct: $e');
    }
    return product;
  }

  Future<List<Category>> getVendorAdminCategoriesByPage(
      {String? parent, int? page, int? perPage, int? offset}) async {
    try {
      var categories = <Category>[];
      var url =
          "${serverConfig['url']}/wp-json/wc/v3/products/categories?per_page=$perPage&consumer_key=${serverConfig['consumerKey']}&consumer_secret=${serverConfig['consumerSecret']}";
      if (page != null && offset == null) {
        url += '&page=$page';
      }
      if (page == null && offset != null) {
        url += '&offset=$offset';
      }
      if (parent != null) {
        url += '&parent=$parent';
      }
      var response = await httpGet(url.toUri()!);
      var result = convert.jsonDecode(response.body);
      if (result is Map &&
          result['message'] != null &&
          result['message'].isNotEmpty) {
        throw Exception(result['message']);
      } else {
        for (var item in result) {
          categories.add(Category.fromJson(item));
        }
        return categories;
      }
    } catch (e) {
      printLog('vendor_admin.dart getVendorAdminCategoriesByPage: $e');
      rethrow;
    }
  }

  Future<List<Category>> getSubCategory({page, categoryId}) async {
    try {
      var categories = <Category>[];
      var url =
          "${serverConfig['url']}/wp-json/wc/v3/products/categories?parent=$categoryId&per_page=100&page=$page&consumer_key=${serverConfig['consumerKey']}&consumer_secret=${serverConfig['consumerSecret']}";
      var response = await httpGet(url.toUri()!);
      var result = convert.jsonDecode(response.body);
      if (result is Map &&
          result['message'] != null &&
          result['message'].isNotEmpty) {
        throw Exception(result['message']);
      } else {
        for (var item in result) {
          if (item['slug'] != 'uncategorized') {
            categories.add(Category.fromJson(item));
          }
        }
        return categories;
      }
    } catch (e) {
      printLog('vendor_admin.dart getSubCategory: $e');
      rethrow;
    }
  }

  Future<List<WCFMNotification>> getNotifications(
      {required cookie, int? page, int? perPage}) async {
    var notifications = <WCFMNotification>[];
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint =
          "${serverConfig['url']}/wp-json/vendor-admin/notifications?page=$page&per_page=$perPage&token=$base64Str";
      var response = await httpGet(endpoint.toUri()!);

      if (response.statusCode == 200) {
        var result = convert.jsonDecode(response.body);
        for (var item in result['response']) {
          notifications.add(WCFMNotification.fromJson(item));
        }
      }
    } catch (e) {
      printLog('vendor_admin.dart getNotifications: $e');
    }
    return notifications;
  }

  Future<void> removeProduct({required cookie, String? productId}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint =
          "${serverConfig['url']}/wp-json/vendor-admin/products?token=$base64Str&id=$productId";
      await httpDelete(endpoint.toUri()!);
    } catch (e) {
      printLog('vendor_admin.dart removeProduct: $e');
    }
  }

  Future<List<ProductAttribute>> getDefaultProductAttributes(
      {required cookie}) async {
    var attributes = <ProductAttribute>[];

    try {
      var base64Str = EncodeUtils.encodeCookie(cookie);
      var endpoint =
          "${serverConfig['url']}/wp-json/vendor-admin/products/attributes?token=$base64Str";
      printLog(endpoint);
      var response = await httpGet(endpoint.toUri()!);
      for (var item in convert.jsonDecode(response.body)) {
        attributes.add(ProductAttribute.fromJson(item));
      }
    } catch (e) {
      printLog('vendor_admin.dart getDefaultProductAttributes: $e');
    }
    return attributes;
  }

  Future<StoreSettings?> getVendorStoreSetting(token) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(token);
      var endpoint =
          '${serverConfig['url']}/wp-json/vendor-admin/profile?token=$base64Str';
      printLog(endpoint);
      final response = await httpGet(endpoint.toUri()!);

      return StoreSettings.fromJson(
          convert.jsonDecode(response.body)['response']);
    } catch (e) {
      printLog('vendor_admin.dart getVendorStoreSetting: $e');
      return null;
    }
  }

  Future<ErrorType> updateVendorStoreSetting(token, data) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(token);
      var endpoint = '${serverConfig['url']}/wp-json/vendor-admin/profile';
      final response = await httpPut(endpoint.toUri()!, body: {
        'token': base64Str,
        'data': convert.jsonEncode(
          data,
        )
      });

      if (convert.jsonDecode(response.body)['response'] == 1) {
        return ErrorType.updateSuccess;
      }
      printLog('vendor_admin.dart updateVendorStoreSetting: ${response.body}');
      return ErrorType.updateFailed;
    } catch (e) {
      printLog('vendor_admin.dart updateVendorStoreSetting: $e');
      return ErrorType.updateFailed;
    }
  }

  @override
  Future updateOrder(orderId, {status, customerNote, token}) async {
    try {
      var base64Str = EncodeUtils.encodeCookie(token);
      var endpoint =
          '${serverConfig['url']}/wp-json/vendor-admin/vendor-orders';
      if (status == 'onhold') {
        status = 'on-hold';
      }
      await httpPut(endpoint.toUri()!, body: {
        'order_id': orderId.toString(),
        'order_status': status,
        'customer_note': customerNote ?? '',
        'token': base64Str,
        'platform': serverConfig['platform'] ?? '',
      });
    } catch (e) {
      printLog('vendor_admin.dart updateOrder: $e');
      rethrow;
    }
  }

  /// App Authentication

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
      var data = <String, dynamic>{
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
      };
      var role = 'seller';

      if (serverConfig['platform'] == null ||
          serverConfig['platform'] == 'wcfm') {
        role = 'wcfm_vendor';
        if (!(kVendorConfig['EnableAutoApplicationApproval'] ?? false)) {
          role = 'subscriber';
          data['wcfm_membership_application_status'] = 'pending';
        }
      } else {
        if (!(kVendorConfig['EnableAutoApplicationApproval'] ?? false)) {
          data['dokan_enable_selling'] = 'false';
        }
      }

      data['role'] = role;
      final response = await httpPost(
          '$domain/wp-json/api/flutter_user/sign_up_2/?insecure=cool&$isSecure'
              .toUri()!,
          body: convert.jsonEncode(data));

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
  Future<User?> login({username, password}) async {
    var cookieLifeTime = 120960000000;
    try {
      final response = await httpPost(
          '$domain/wp-json/api/flutter_user/generate_auth_cookie'.toUri()!,
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
          "${serverConfig['url']}/wp-json/api/flutter_user/google_login/?second=$cookieLifeTime"
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
          "${serverConfig['url']}/wp-json/api/flutter_user/fb_connect/?second=$cookieLifeTime"
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
  Future<User?> loginApple({String? token}) async {
    try {
      var endPoint =
          '${serverConfig['url']}/wp-json/api/flutter_user/apple_login';

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
          "${serverConfig['url']}/wp-json/api/flutter_user/get_currentuserinfo?token=$base64Str&$isSecure"
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
      printLog('vendor_admin.dart getUserInfo: $e');
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

  Future<String> getAddressFromLocation(double? lat, double? long) async {
    final isIOS = isIos;
    var response = await httpGet(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=${isIOS ? kGoogleApiKey.ios : kGoogleApiKey.android}'
            .toUri()!);
    return convert
        .jsonDecode(response.body)['results']
        .first['formatted_address'];
  }

  Future<List<DeliveryUser>> getDeliveryUsers(
      String cookie, String name) async {
    var base64Str = EncodeUtils.encodeCookie(cookie);
    var list = <DeliveryUser>[];
    try {
      final response = await httpGet(
          "${serverConfig['url']}/wp-json/vendor-admin/delivery/get-users?name=$name&token=$base64Str"
              .toUri()!);
      var result = convert.jsonDecode(response.body);

      for (var item in result['response']) {
        list.add(DeliveryUser.fromJson(item));
      }
    } catch (e) {
      printLog('getDeliveryUsers $e');
    }
    return list;
  }

  Future<bool> assignDeliveryUser(String cookie, data) async {
    var base64Str = EncodeUtils.encodeCookie(cookie);
    try {
      final response = await httpPost(
          "${serverConfig['url']}/wp-json/vendor-admin/delivery".toUri()!,
          body: {
            'token': base64Str,
            ...data,
          });

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      printLog('assignDeliveryUser $e');
    }
    return false;
  }

  @override
  Future<VacationSettings?> getVacationSettings(String storeId) async {
    try {
      final response = await httpGet(
          '$domain/wp-json/wc/v2/flutter/vendor/vacation?store_id=$storeId'
              .toUri()!);

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return VacationSettings.fromJson(body);
      }
    } catch (e) {
      printLog(e);
    }
    return null;
  }

  @override
  Future<bool?> setVacationSettings(
      String cookie, VacationSettings vacationSettings) async {
    try {
      var data = vacationSettings.toJson();
      data['cookie'] = cookie;
      final response = await httpPost(
          '$domain/wp-json/wc/v2/flutter/vendor/vacation'.toUri()!,
          body: data);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      printLog(e);
    }
    return false;
  }
}
