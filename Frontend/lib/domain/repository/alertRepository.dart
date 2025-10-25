import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
// CLAVE: Importar el enum desde su ubicación correcta
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';

// Importa tu DTO
import '../models/dto/sensor_alert_model.dart';

// -----------------------------------------------------------------------------
// Configuraciones
// -----------------------------------------------------------------------------
const String _apiBaseUrl = 'http://localhost:8080/alerts';

class AlertService {
  final Dio _dio = Dio();

// -----------------------------------------------------------------------------
// 1. streamAlerts (Server-Sent Events - Corregido)
// -----------------------------------------------------------------------------

  /**
   * Abre un stream de eventos (SSE) para recibir alertas en tiempo real.
   * Retorna un Stream de SensorAlertModel que el UI puede escuchar.
   */
  Stream<SensorAlertModel> streamAlerts() {

    // El método subscribeToSSE AHORA devuelve el Stream.
    // Usamos .map() en el Stream devuelto para transformar el SseModel a SensorAlertModel.
    return SSEClient.subscribeToSSE(
      url: '$_apiBaseUrl/stream',

      // El ejemplo confirma el uso del enum SSERequestType.GET
      method: SSERequestType.GET,

      header: const {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },

      // Los campos 'onConnected', 'onDisconnected', etc., NO son parte del método principal,
      // sino que se manejan en los listeners del Stream si fuera necesario.

    )
        .where((event) => event.data != null && event.data!.isNotEmpty)
        .map((event) {
      // Parseamos el JSON del campo 'data' del evento SSE
      final Map<String, dynamic> jsonMap = json.decode(event.data!);
      return SensorAlertModel.fromJson(jsonMap);
    })
        .handleError((error) {
      print('Error en el stream de alertas (SSE): $error');
      throw error;
    })
        .asBroadcastStream();
  }

// -----------------------------------------------------------------------------
// 2. createAlert (POST)
// -----------------------------------------------------------------------------

  Future<SensorAlertModel> createAlert(SensorAlertModel alert) async {
    try {
      final response = await _dio.post(
        _apiBaseUrl,
        data: alert.toJson(),
      );
      return SensorAlertModel.fromJson(response.data);

    } on DioException catch (e) {
      throw Exception('Error al crear alerta: ${e.response?.statusCode} - ${e.message}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al crear la alerta: $e');
    }
  }

// -----------------------------------------------------------------------------
// 3. deactivateAlert (POST)
// -----------------------------------------------------------------------------

  Future<void> deactivateAlert(int id) async {
    final url = '$_apiBaseUrl/$id/deactivate';
    try {
      await _dio.post(url);
    } on DioException catch (e) {
      throw Exception('Error al desactivar alerta: ${e.response?.statusCode} - ${e.message}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al desactivar la alerta: $e');
    }
  }
}