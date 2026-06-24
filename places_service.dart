import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PlacesService {
  // ATENÇÃO: Substitua pela sua chave de API do Google Maps.
  final String _apiKey = 'SUA_CHAVE_DE_API_AQUI';
  final String _sessionToken = const Uuid().v4();

  Future<List<Map<String, dynamic>>> getAutocomplete(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&sessiontoken=$_sessionToken&components=country:br'; // Limitando ao Brasil

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['predictions']);
    } else {
      print('Failed to fetch autocomplete suggestions: ${response.statusCode}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey&sessiontoken=$_sessionToken';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body)['result'];
    }
    return null;
  }
}
