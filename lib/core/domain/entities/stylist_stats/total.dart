import 'package:json_annotation/json_annotation.dart';

part 'total.g.dart';

@JsonSerializable()
class Total {
  num? works;
  num? likes;
  num? appointments;
  num? earnings;

  Total({this.works, this.likes, this.appointments, this.earnings});

  factory Total.fromJson(Map<String, dynamic> json) => _$TotalFromJson(json);

  Map<String, dynamic> toJson() => _$TotalToJson(this);
}
