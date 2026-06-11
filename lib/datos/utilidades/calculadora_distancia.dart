import 'dart:math';

class CalculadoraDistancia {
  /// 🛰️ Aplica la Fórmula de Haversine para calcular la distancia exacta
  /// entre dos puntos del planeta Tierra en metros.
  static double calcularHaversine({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Radio medio de la Tierra en metros
    const double radioTierraMetros = 6371000;

    // Convertir grados de latitud y longitud a radianes
    final double dLat = _gradosARadianes(lat2 - lat1);
    final double dLon = _gradosARadianes(lon2 - lon1);

    // Aplicación de la fórmula trigonométrica esférica
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(lat1)) *
            cos(_gradosARadianes(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Retorna la distancia lineal exacta sobre la curvatura de la Tierra
    return radioTierraMetros * c;
  }

  static double _gradosARadianes(double grados) {
    return grados * pi / 180;
  }
}
