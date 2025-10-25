import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensor_record_model.freezed.dart';
part 'sensor_record_model.g.dart';

@freezed
abstract class SensorRecordModel with _$SensorRecordModel {
  const factory SensorRecordModel({
    required DateTime timestamp,
    required int sensorId,
    required double? ph,
    required double? turbidity,
    required double? conductivity,
    required double? flowRate,
  }) = _SensorRecordModel;

  factory SensorRecordModel.fromJson(Map<String, dynamic> json) =>
      _SensorRecordModel.fromJson(json);
}
@freezed
abstract class SensorRawRecordModel with _$SensorRawRecordModel {
  const factory SensorRawRecordModel({
    required DateTime timestamp,
    required int sensorId,
    required Map<String, double> metrics,
  }) = _SensorRawRecordModel;

  factory SensorRawRecordModel.fromJson(Map<String, dynamic> json) =>
      _SensorRawRecordModel.fromJson(json);
}

extension SensorRawRecordModelMapper on SensorRawRecordModel {
  SensorRecordModel toSensorRecordModel() {
    return SensorRecordModel(
      timestamp: this.timestamp,      sensorId: this.sensorId,
      ph: this.metrics['ph'],
      turbidity: this.metrics['turbidity'],
      conductivity: this.metrics['conductivity'],
      flowRate: this.metrics['flowRate'],
    );
  }
}