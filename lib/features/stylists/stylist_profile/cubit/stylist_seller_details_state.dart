part of 'stylist_seller_details_cubit.dart';

class StylistSellerDetailsState extends Equatable {
  StylistSellerDetailsState._(
      {required this.sellerDetails, required this.sellePortfolio});

  StylistSellerDetailsState.initial()
      : sellePortfolio = ProcessState.init(null),
        sellerDetails = ProcessState.init(null);

  final ProcessState<SellerDetails> sellerDetails;
  final ProcessState<SellerPortfolioList> sellePortfolio;

  StylistSellerDetailsState copyWith({
    ProcessState<SellerDetails>? sellerDetails,
    ProcessState<SellerPortfolioList>? sellePortfolio,
  }) {
    return StylistSellerDetailsState._(
      sellerDetails: sellerDetails ?? this.sellerDetails,
      sellePortfolio: sellePortfolio ?? this.sellePortfolio,
    );
  }

  @override
  List<Object> get props => [sellerDetails, sellePortfolio];
}
