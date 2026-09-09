import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io_client;

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  static const String defaultBaseUrl = 'http://localhost:3001';

  io_client.Socket? _socket;
  bool _isConnected = false;
  String _baseUrl = defaultBaseUrl;

  final StreamController<Map<String, dynamic>> _kitchenStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get kitchenStream => _kitchenStreamController.stream;
  bool get isConnected => _isConnected;
  String get baseUrl => _baseUrl;

  int currentRestauranteId = 1;

  Map<String, dynamic>? _lastPayload;
  Map<String, dynamic>? get lastPayload => _lastPayload;

  void init({String? baseUrl}) {
    if (baseUrl != null) _baseUrl = baseUrl;
    _connectSocket();
  }

  void _connectSocket() {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = io_client.io(_baseUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 2000,
        'timeout': 5000,
      });

      _socket?.onConnect((_) {
        _isConnected = true;
        if (kDebugMode) {
          print('[BackendService] Conectado ao servidor Node.js/Socket.io em $_baseUrl');
        }
      });

      _socket?.on('cozinha_stream', (data) {
        if (data is Map<String, dynamic>) {
          _lastPayload = data;
          _kitchenStreamController.add(data);
        } else if (data is String) {
          try {
            final parsed = jsonDecode(data);
            if (parsed is Map<String, dynamic>) {
              _lastPayload = parsed;
              _kitchenStreamController.add(parsed);
            }
          } catch (_) {}
        }
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        if (kDebugMode) {
          print('[BackendService] Desconectado do servidor Node.js');
        }
      });

      _socket?.onError((err) {
        _isConnected = false;
      });
    } catch (e) {
      _isConnected = false;
    }
  }

  // ==========================================
  // AUTENTICAÇÃO E EMPRESAS
  // ==========================================
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': password}),
          )
          .timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['restaurante'] != null && body['restaurante']['id'] != null) {
          currentRestauranteId = (body['restaurante']['id'] as num).toInt();
        }
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return body;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String name,
    required String establishmentName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/auth/register');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'senha': password,
              'nome': name,
              'restaurante_nome': establishmentName,
            }),
          )
          .timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['restaurante'] != null && body['restaurante']['id'] != null) {
          currentRestauranteId = (body['restaurante']['id'] as num).toInt();
        }
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return body;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> fetchRestaurantes() async {
    try {
      final url = Uri.parse('$_baseUrl/api/restaurantes');
      final response = await http.get(url).timeout(const Duration(milliseconds: 3000));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
      }
    } catch (_) {}
    return [];
  }

  Future<bool> updateConfig({
    int? restauranteId,
    String? openingTime,
    String? closingTime,
    String? peakStartTime,
    String? peakEndTime,
    int? maxCapacity,
    List<String>? openDays,
    List<String>? manualHolidays,
  }) async {
    final restId = restauranteId ?? currentRestauranteId;
    try {
      final url = Uri.parse('$_baseUrl/api/restaurante/$restId/config');
      final payload = <String, dynamic>{};
      if (openingTime != null) payload['horario_abertura'] = openingTime;
      if (closingTime != null) payload['horario_fechamento'] = closingTime;
      if (peakStartTime != null) payload['horario_pico_inicio'] = peakStartTime;
      if (peakEndTime != null) payload['horario_pico_fim'] = peakEndTime;
      if (maxCapacity != null) payload['capacidade_maxima'] = maxCapacity;
      if (openDays != null) payload['dias_funcionamento'] = openDays;
      if (manualHolidays != null) payload['feriados_manuais'] = manualHolidays;

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 3000));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ==========================================
  // STATUS & COZINHA STREAM
  // ==========================================
  Future<Map<String, dynamic>?> fetchStatus({int? restauranteId}) async {
    final restId = restauranteId ?? currentRestauranteId;
    try {
      final url = Uri.parse('$_baseUrl/api/status/$restId');
      final response = await http.get(url).timeout(const Duration(milliseconds: 3000));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          _lastPayload = body;
          _kitchenStreamController.add(body);
          return body;
        }
      }
    } catch (_) {}
    return null;
  }

  // ==========================================
  // FLUXO DE CLIENTES (ENTRADA / SAÍDA)
  // ==========================================
  Future<bool> recordFluxo({int? restauranteId, required int quantidade}) async {
    final restId = restauranteId ?? currentRestauranteId;
    try {
      final url = Uri.parse('$_baseUrl/api/fluxo');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'restaurante_id': restId,
              'quantidade': quantidade,
            }),
          )
          .timeout(const Duration(milliseconds: 3000));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateClosingTime({
    int? restauranteId,
    String? closingTime,
    int? simulatedMinutes,
  }) async {
    final restId = restauranteId ?? currentRestauranteId;
    try {
      final url = Uri.parse('$_baseUrl/api/restaurante/$restId/horario');
      final payload = <String, dynamic>{};
      if (closingTime != null) payload['horario_fechamento'] = closingTime;
      if (simulatedMinutes != null) payload['minutos_simulados'] = simulatedMinutes;

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 3000));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // ALIMENTOS (CRUD)
  // ==========================================
  Future<List<dynamic>> fetchAlimentos({int? restauranteId}) async {
    final restId = restauranteId ?? currentRestauranteId;
    try {
      final url = Uri.parse('$_baseUrl/api/alimentos/$restId');
      final response = await http.get(url).timeout(const Duration(milliseconds: 3000));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addAlimento({
    int? restauranteId,
    required String name,
    required String category,
    required double currentStock,
    required double consumptionPerPerson,
    required double standardBatch,
    required double reducedBatch,
    String unit = 'kg',
  }) async {
    final restId = restauranteId ?? currentRestauranteId;
    try {
      final url = Uri.parse('$_baseUrl/api/alimentos');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'restaurante_id': restId,
              'nome': name,
              'categoria': category,
              'estoque_atual': currentStock,
              'consumo_por_pessoa': consumptionPerPerson,
              'tamanho_lote_padrao': standardBatch,
              'tamanho_lote_reduzido': reducedBatch,
              'unidade': unit,
            }),
          )
          .timeout(const Duration(milliseconds: 3000));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateAlimento(int id, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$_baseUrl/api/alimentos/$id');
      final payload = Map<String, dynamic>.from(data);
      payload['restaurante_id'] = currentRestauranteId;

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 3000));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteAlimento(int id) async {
    try {
      final url = Uri.parse('$_baseUrl/api/alimentos/$id?restaurante_id=$currentRestauranteId');
      final response = await http.delete(url).timeout(const Duration(milliseconds: 3000));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status_cozinha'] is Map<String, dynamic>) {
          _lastPayload = body['status_cozinha'];
          _kitchenStreamController.add(body['status_cozinha']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _kitchenStreamController.close();
  }
}
