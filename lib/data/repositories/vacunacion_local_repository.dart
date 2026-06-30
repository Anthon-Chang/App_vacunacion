import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../local/vacunacion_local.dart';

class VacunacionLocalRepository {
  static const String _key = 'vacunaciones_offline';

  Future<List<VacunacionLocal>> _obtenerTodas() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((j) => VacunacionLocal.fromMap(jsonDecode(j)))
        .toList();
  }

  Future<void> _guardarTodas(List<VacunacionLocal> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = lista.map((v) => jsonEncode(v.toMap())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<String> guardar(VacunacionLocal v) async {
    final lista = await _obtenerTodas();
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    v.id = key;
    lista.add(v);
    await _guardarTodas(lista);
    return key;
  }

  Future<List<VacunacionLocal>> obtenerPendientes() async {
    final lista = await _obtenerTodas();
    return lista.where((v) => !v.sincronizado).toList();
  }

  Future<List<VacunacionLocal>> obtenerTodas() async {
    return await _obtenerTodas();
  }

  Future<void> marcarSincronizada(String id) async {
    final lista = await _obtenerTodas();
    final idx = lista.indexWhere((v) => v.id == id);
    if (idx != -1) {
      lista[idx].sincronizado = true;
      await _guardarTodas(lista);
    }
  }

  Future<void> eliminar(String id) async {
    final lista = await _obtenerTodas();
    lista.removeWhere((v) => v.id == id);
    await _guardarTodas(lista);
  }

  Future<int> cantidadPendientes() async {
    final pendientes = await obtenerPendientes();
    return pendientes.length;
  }
}