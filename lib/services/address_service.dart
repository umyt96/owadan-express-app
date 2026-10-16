import 'package:dio/dio.dart';

import '../models/address.dart';
import 'api_client.dart';

class AddressService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Address>> getAddresses() async {
    try {
      final response = await _dio.get('/addresses/');
      final data = response.data;
      final list = data is Map && data['results'] != null ? data['results'] : data;
      return (list as List).map((e) => Address.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<Address> createAddress(Address address) async {
    try {
      final response = await _dio.post('/addresses/', data: address.toJson());
      return Address.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<Address> updateAddress(int id, Address address) async {
    try {
      final response = await _dio.put('/addresses/$id/', data: address.toJson());
      return Address.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      await _dio.delete('/addresses/$id/');
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
