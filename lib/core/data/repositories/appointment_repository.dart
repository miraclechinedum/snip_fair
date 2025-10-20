import 'package:injectable/injectable.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment_list.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment.dart';
import 'package:snip_fair/core/domain/entities/customer_appointment_list/customer_appointment_list.dart';
import 'package:snip_fair/core/domain/entities/like_response/like_response.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio_list.dart';
import 'package:snip_fair/core/domain/entities/stylist_list/stylist_list.dart';
import 'package:snip_fair/core/domain/entities/work_category/work_category.dart';
import 'package:snip_fair/core/network/api_result.dart';

abstract class AppointmentRepository {
  Future<ApiResult<StylistAppointmentList>> getStylistAppointments({
    String? query,
    String? categoryId,
    String? page,
    int? perPage,
    String? customerId,
    String? portfolioId,
    String? status,
    String? sort,
  });

  Future<ApiResult<StylistAppointment>> getStylistAppointmentById(String id);

  Future<ApiResult<SimpleResponse>> updateStylistAppointment(
    String id, {
    required String verdict,
    String? code,
  });

  Future<ApiResult<StylistList>> customerFetchStylists({
    String? query,
    String? categoryId,
    String? page,
    String? perPage,
    String? sort,
    bool? favourite,
  });

  Future<ApiResult<SellerDetails>> customerFetchStylistById(String id);

  Future<ApiResult<SellerPortfolioList>> customerFetchPortfolioList({
    String? query,
    String? categoryId,
    String? stylistId,
    String? page,
    String? perPage,
    String? sort,
    bool? favourite,
  });

  Future<ApiResult<SellerPortfolio>> customerFetchPortfolioById({
    String? id,
  });

  Future<ApiResult<LikeResponse>> toggleLike({
    required String type,
    required String typeId,
  });

  Future<ApiResult<List<WorkCategory>>> fetchWorkCategories();

  Future<ApiResult<CustomerAppointment>> createAppointment({
    required String portfolioId,
    required String date,
    required String time,
    String? note,
    String? address,
  });

  Future<ApiResult<SimpleResponse>> updateCustomerAppointment(
    String id, {
    required String verdict,
  });

  Future<ApiResult<SimpleResponse>> disputeCustomerAppointment(
    String id, {
    required String comment,
    required List<String> images,
  });

  Future<ApiResult<SimpleResponse>> reviewCustomerAppointment(
    String id, {
    required int rating,
    String? comment,
  });

  Future<ApiResult<CustomerAppointment>> getCustomerAppointmentById(
    String appointmentId,
  );

  Future<ApiResult<CustomerAppointmentList>> getCustomerAppointments({
    String? page,
    String? perPage,
  });
}

@Injectable(as: AppointmentRepository)
class AppointmentRepoImpl implements AppointmentRepository {
  AppointmentRepoImpl(this._remoteSource);

  final SnipFairBackendRemoteSource _remoteSource;
  @override
  Future<ApiResult<StylistAppointment>> getStylistAppointmentById(String id) =>
      _remoteSource.getStylistAppointmentById(id);

  @override
  Future<ApiResult<StylistAppointmentList>> getStylistAppointments({
    String? query,
    String? categoryId,
    String? page,
    int? perPage,
    String? customerId,
    String? portfolioId,
    String? status,
    String? sort,
  }) =>
      _remoteSource.getStylistAppointments(
        query: query,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
        customerId: customerId,
        portfolioId: portfolioId,
        status: status,
        sort: sort,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateStylistAppointment(
    String id, {
    required String verdict,
    String? code,
  }) =>
      _remoteSource.updateStylistAppointment(id, verdict: verdict, code: code);

  @override
  Future<ApiResult<SellerDetails>> customerFetchStylistById(String id) =>
      _remoteSource.customerFetchStylistById(id);

  @override
  Future<ApiResult<StylistList>> customerFetchStylists({
    String? query,
    String? categoryId,
    String? page,
    String? perPage,
    String? sort,
    bool? favourite,
  }) =>
      _remoteSource.customerFetchStylists(
        query: query,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
        sort: sort,
        favourite: favourite,
      );

  @override
  Future<ApiResult<SellerPortfolioList>> customerFetchPortfolioList({
    String? query,
    String? categoryId,
    String? stylistId,
    String? page,
    String? perPage,
    String? sort,
    bool? favourite,
  }) =>
      _remoteSource.customerFetchPortfolioList(
        query: query,
        categoryId: categoryId,
        stylistId: stylistId,
        page: page,
        perPage: perPage,
        sort: sort,
        favourite: favourite,
      );

  @override
  Future<ApiResult<LikeResponse>> toggleLike({
    required String type,
    required String typeId,
  }) =>
      _remoteSource.toggleLike(type: type, typeId: typeId);

  @override
  Future<ApiResult<List<WorkCategory>>> fetchWorkCategories() =>
      _remoteSource.fetchWorkCategories();

  @override
  Future<ApiResult<SellerPortfolio>> customerFetchPortfolioById({String? id}) =>
      _remoteSource.customerFetchPortfolioById(id: id);

  @override
  Future<ApiResult<CustomerAppointment>> createAppointment({
    required String portfolioId,
    required String date,
    required String time,
    String? note,
    String? address,
  }) =>
      _remoteSource.createAppointment(
        portfolioId: portfolioId,
        date: date,
        time: time,
        note: note,
        address: address,
      );

  @override
  Future<ApiResult<CustomerAppointment>> getCustomerAppointmentById(
    String appointmentId,
  ) =>
      _remoteSource.getCustomerAppointmentById(appointmentId);

  @override
  Future<ApiResult<CustomerAppointmentList>> getCustomerAppointments({
    String? page,
    String? perPage,
  }) =>
      _remoteSource.getCustomerAppointments(
        page: page,
        perPage: perPage,
      );

  @override
  Future<ApiResult<SimpleResponse>> disputeCustomerAppointment(
    String id, {
    required String comment,
    required List<String> images,
  }) =>
      _remoteSource.disputeCustomerAppointment(
        id,
        comment: comment,
        images: images,
      );

  @override
  Future<ApiResult<SimpleResponse>> reviewCustomerAppointment(
    String id, {
    required int rating,
    String? comment,
  }) =>
      _remoteSource.reviewCustomerAppointment(
        id,
        rating: rating,
        comment: comment,
      );

  @override
  Future<ApiResult<SimpleResponse>> updateCustomerAppointment(
    String id, {
    required String verdict,
  }) =>
      _remoteSource.updateCustomerAppointment(id, verdict: verdict);
}
