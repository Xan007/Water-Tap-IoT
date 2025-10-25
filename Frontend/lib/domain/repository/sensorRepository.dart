import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart'; // Usado para debugPrint/print
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';

// Importa tus modelos de datos (DTOs)
import '../models/dto/sensor_record_model.dart';
// Asumimos que SensorAlertEntity no se usa directamente en esta capa de Sensor,
// pero si fuera necesario se importaría aquí.

// -----------------------------------------------------------------------------
// Configuraciones
// -----------------------------------------------------------------------------
const String _apiBaseUrl = 'http://localhost:8080';

class SensorRepository {
  // Dio es el equivalente moderno de Dart/Flutter a la función 'fetch' de JavaScript.
  final Dio _dio = Dio();

// -----------------------------------------------------------------------------
// 1. streamSensorData (Equivalente a streamSensorData JS)
// -----------------------------------------------------------------------------

  /**
   * Abre un stream de eventos (SSE) para recibir listas de SensorRecordModel en tiempo real.
   * Retorna un Stream de List<SensorRecordModel> que el UI puede escuchar.
   */
  Stream<List<SensorRecordModel>> streamSensorData() {
    final url = '$_apiBaseUrl/sensors/stream';
    debugPrint('API Service: Abriendo conexión SSE a: $url');

    // SSEClient.subscribeToSSE devuelve un Stream<SseModel>
    return SSEClient.subscribeToSSE(
      url: url,
      method: SSERequestType.GET,
      header: const {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    )
        .where((event) => event.data != null && event.data!.isNotEmpty)
        .map((event) {
      // Equivalente a eventSource.onmessage y JSON.parse(event.data)
      try {
        debugPrint('API Service: Mensaje recibido en el stream: ${event.data}');

        final List<dynamic> jsonList = json.decode(event.data!);

        final parsedData = jsonList
            .map((jsonItem) => SensorRecordModel.fromJson(jsonItem as Map<String, dynamic>))
            .toList();

        debugPrint('API Service: Datos parseados correctamente: ${parsedData.length} registros.');
        return parsedData;

      } catch (e) {
        // Equivalente a console.error al analizar datos
        debugPrint('API Service: Error al analizar los datos del stream: $e');
        // Lanzamos una excepción para que el listener del stream maneje el error
        throw FormatException('Error al decodificar datos del stream: $e');
      }
    })
        .handleError((error) {
      // Equivalente a eventSource.onerror
      debugPrint('API Service: Stream falló o terminó: $error');
      throw error;
    })
    // Permite múltiples listeners (aunque SSEClient ya podría hacerlo, es buena práctica)
        .asBroadcastStream();
  }

// -----------------------------------------------------------------------------
// 2. getHistoryData (Equivalente a getHistoryData JS)
// -----------------------------------------------------------------------------

  /**
   * Obtiene datos históricos de sensores entre dos DateTime.
   * @param from - La fecha de inicio (DateTime, será covertida a ISO 8601).
   * @param to - La fecha de fin (DateTime, será covertida a ISO 8601).
   * @returns Una lista de SensorRecordModel.
   */
  Future<List<SensorRecordModel>> getHistoryData({
    required DateTime from,
    required DateTime to,
  }) async {
    final url = '$_apiBaseUrl/sensors/history';

    // Convertir DateTime a String ISO 8601 para el backend (similar a JS)
    final fromIso = from.toUtc().toIso8601String();
    final toIso = to.toUtc().toIso8601String();

    debugPrint('API Service: Obteniendo datos históricos desde: $url?from=$fromIso&to=$toIso');

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'from': fromIso,
          'to': toIso,
        },
      );

      // La validación response.ok en JS es response.statusCode == 2xx en Dio
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        // Equivalente a throw new Error(`Error al obtener datos históricos: ...`)
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Error al obtener datos históricos: ${response.statusMessage}',
        );
      }

      // Parsea la lista de JSON a la lista de modelos
      final List<dynamic> jsonList = response.data;

      final data = jsonList
          .map((jsonItem) => SensorRecordModel.fromJson(jsonItem as Map<String, dynamic>))
          .toList();

      debugPrint('API Service: Datos históricos recibidos: ${data.length} registros.');
      return data;

    } on DioException catch (e) {
      // Equivalente al catch(error) general en JS
      debugPrint('API Service: Error de red/HTTP al obtener datos históricos: ${e.message}');
      throw Exception('Error al obtener datos históricos: ${e.response?.statusCode} - ${e.message}');
    } catch (e) {
      debugPrint('API Service: Error inesperado: $e');
      throw Exception('Ocurrió un error inesperado al obtener historial: $e');
    }
  }

// -----------------------------------------------------------------------------
// 3. uploadSensorData (Equivalente a uploadSensorData JS)
// -----------------------------------------------------------------------------

  /**
   * Envía datos de sensores al servidor.
   * @param records - La lista de registros de sensores a subir.
   */
  Future<void> uploadSensorData(List<SensorRecordModel> records) async {
    final url = '$_apiBaseUrl/upload';
    debugPrint('API Service: Subiendo ${records.length} datos de sensores a: $url');

    try {
      // 1. Mapear la lista de modelos de Dart a una lista de JSON
      final List<Map<String, dynamic>> jsonList =
      records.map((record) => record.toJson()).toList();

      // 2. POST request. Dio establece automáticamente Content-Type: application/json
      final response = await _dio.post(
        url,
        data: jsonList, // Dio serializa automáticamente la lista a JSON (JSON.stringify)
      );

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        debugPrint('API Service: Error de respuesta HTTP al subir datos: ${response.statusCode} ${response.statusMessage}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Error al subir datos de sensores: ${response.statusMessage}',
        );
      }

      debugPrint('API Service: Subida de datos exitosa.');
    } on DioException catch (e) {
      debugPrint('API Service: Error de red al subir datos: ${e.message}');
      throw Exception('Error al subir datos de sensores: ${e.response?.statusCode} - ${e.message}');
    } catch (e) {
      debugPrint('API Service: Error inesperado: $e');
      throw Exception('Ocurrió un error inesperado al subir datos: $e');
    }
  }
}