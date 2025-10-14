import 'package:snip_fair/core/domain/entities/availability_schedule/timeslot.dart';
import 'package:snip_fair/core/utils/utils.dart';

class ScheduleParams {
  ScheduleParams({this.day, this.available, this.timeSlots});
  String? day;
  bool? available;
  List<TimeSlot>? timeSlots;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['day'] = day?.capitalizeFirstLetter();
    data['available'] = available;
    if (timeSlots != null) {
      data['timeSlots'] = timeSlots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
