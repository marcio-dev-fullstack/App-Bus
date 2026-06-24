import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsService {
  // ATENÇÃO: Substitua pela sua chave de API do Google Maps.
  // É altamente recomendável não deixar a chave diretamente no código em produção.
  // Considere usar variáveis de ambiente (ex: flutter_dotenv).
  final String _apiKey = 'SUA_CHAVE_DE_API_AQUI';

  Future<Map<String, dynamic>?> getDirections(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&departure_time=now&alternatives=true&key=$_apiKey';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['routes'] != null && jsonResponse['routes'].isNotEmpty) {
        return jsonResponse;
      }
    } else {
      print('Failed to fetch directions: ${response.statusCode}');
    }
    return null;
  }
}
