import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/places_service.dart';
import '../../api/directions_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final PlacesService _placesService = PlacesService();
  final DirectionsService _directionsService = DirectionsService();
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  AnimationController? _animationController;

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  List<Map<String, dynamic>> _autocompleteSuggestions = [];
  Timer? _debounce;

  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _customMarkerIcon;
  List<LatLng> _polylineCoordinates = [];
  LatLng? _origin;
  LatLng? _destination;
  List<Map<String, dynamic>> _routes = [];
  int _selectedRouteIndex = 0;
  String? _routeDistance;
  String? _routeDuration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _determinePosition();

    _originController.addListener(() {
      _onSearchChanged(_originController.text);
    });
    _destinationController.addListener(() {
      _onSearchChanged(_destinationController.text);
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _mapController?.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Serviços de localização estão desabilitados.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _isLoading = false;
    });

    _mapController = await _controller.future;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _loadCustomMarker() async {
    // Certifique-se de que o caminho corresponde ao local do seu asset
    _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/bus_marker.png', // Altere se o nome do seu arquivo for diferente
    );

    // Não adiciona mais marcadores fixos aqui.
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_origin == null || _destination == null) {
      return;
    }

    final directions = await _directionsService.getDirections(
      _origin!.latitude,
      _origin!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );

    if (directions == null || directions['routes'].isEmpty) {
      // Não foi possível obter a rota
      return;
    }

    // Adiciona o marcador do ônibus animado na origem
    _markers.add(Marker(markerId: const MarkerId('bus_1'), position: _origin!));

    _routes = List<Map<String, dynamic>>.from(directions['routes']);
    _drawAllRoutes();
    _startAnimation();
  }

  void _startAnimation() {
    if (_polylineCoordinates.isEmpty) return;

    _animationController = AnimationController(
      duration: const Duration(seconds: 15), // Duração total da animação
      vsync: this,
    );

    final Animation<double> animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController!);

    animation.addListener(() {
      if (_mapController == null) return;

      final int index = (_polylineCoordinates.length * animation.value).floor();
      final LatLng newPosition = _polylineCoordinates[index];

      // Calcula a rotação (bearing) para o próximo ponto
      double bearing = 0;
      if (index < _polylineCoordinates.length - 1) {
        final LatLng nextPosition = _polylineCoordinates[index + 1];
        bearing = Geolocator.bearingBetween(
          newPosition.latitude,
          newPosition.longitude,
          nextPosition.latitude,
          nextPosition.longitude,
        );
      }

      // Garante que o marcador 'bus_1' exista antes de tentar atualizá-lo
      if (_markers.any((m) => m.markerId.value == 'bus_1')) {
        setState(() {
          // Remove o marcador antigo e adiciona um novo com a posição atualizada
          _markers.removeWhere((m) => m.markerId.value == 'bus_1');
          _markers.add(
            Marker(
              markerId: const MarkerId('bus_1'),
              position: newPosition,
              icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(
                title: 'Ônibus 101',
                snippet: 'Em movimento...',
              ),
              rotation: bearing,
            ),
          );
        });
      }
    });

    _animationController!.forward();
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController!.repeat();
      }
    });
  }

  void _handleMapTap(LatLng tappedPoint) {
    if (_origin == null || (_origin != null && _destination != null)) {
      // Inicia uma nova seleção (ou reinicia uma seleção completa)
      _resetRoute();
      setState(() {
        _origin = tappedPoint;
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: tappedPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: 'Origem'),
          ),
        );
      });
    } else if (_destination == null) {
      // Define o destino
      setState(() {
        _destination = tappedPoint;
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: tappedPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'Destino'),
          ),
        );
      });
      // Ambos os pontos estão definidos, desenha a rota
      _getDirectionsAndDrawRoute();
    }
  }

  void _drawAllRoutes() {
    _polylines.clear();
    for (int i = 0; i < _routes.length; i++) {
      final route = _routes[i];
      final polylinePoints = PolylinePoints();
      final List<PointLatLng> decodedResult = polylinePoints.decodePolyline(
        route['overview_polyline']['points'],
      );

      final polylineCoordinates = decodedResult
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      if (i == _selectedRouteIndex) {
        _polylineCoordinates = polylineCoordinates;
        final leg = route['legs'][0];
        _routeDuration = leg['duration_in_traffic'] != null
            ? leg['duration_in_traffic']['text']
            : leg['duration']['text'];
        _routeDistance = leg['distance']['text'];
      }

      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          color: i == _selectedRouteIndex ? Colors.lightBlue : Colors.grey,
          width: i == _selectedRouteIndex ? 6 : 4,
          points: polylineCoordinates,
          consumeTapEvents: true,
          onTap: () {
            _onRouteTapped(i);
          },
        ),
      );
    }
    setState(() {});
  }

  void _onRouteTapped(int index) {
    if (_selectedRouteIndex == index) return;

    setState(() {
      _selectedRouteIndex = index;
      // Para a animação atual e a reinicia na nova rota
      _animationController?.stop();
      _animationController?.reset();

      // Redesenha as rotas com as cores atualizadas e atualiza os dados
      _drawAllRoutes();
      _startAnimation();
    });
  }

  void _resetRoute() {
    setState(() {
      _origin = null;
      _destination = null;
      _markers.clear();
      _polylines.clear();
      _polylineCoordinates.clear();
      _routes.clear();
      _selectedRouteIndex = 0;
      _routeDistance = null;
      _routeDuration = null;
      _animationController?.stop();
      _animationController?.reset();
    });

    // Limpa os campos de texto e sugestões
    _originController.clear();
    _destinationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-15.793889, -47.882778), // Brasília
                    zoom: 12, // Aumentei o zoom inicial
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (!_controller.isCompleted)
                      _controller.complete(controller);
                  },
                  onTap: _handleMapTap,
                  markers: _markers,
                  polylines: _polylines,
                  trafficEnabled: true, // Ativa a camada de trânsito
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  padding: const EdgeInsets.only(
                    top: 80.0,
                  ), // Afasta os controles do Google do nosso card
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _buildSearchCard(),
                      if (_autocompleteSuggestions.isNotEmpty)
                        _buildSuggestionsList(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _resetRoute,
        label: const Text('Limpar Rota'),
        icon: const Icon(Icons.clear),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salvar Rota'),
              onPressed: _saveFavoriteRoute,
            ),
            TextButton.icon(
              icon: const Icon(Icons.star),
              label: const Text('Carregar Favorita'),
              onPressed: _loadFavoriteRoute,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          TextField(
            controller: _originController,
            decoration: const InputDecoration(
              labelText: 'Origem',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const Divider(height: 1),
          TextField(
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'Destino',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Card(
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _autocompleteSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _autocompleteSuggestions[index];
          return ListTile(
            title: Text(suggestion['description']),
            onTap: () => _onSuggestionSelected(suggestion),
          );
        },
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        final suggestions = await _placesService.getAutocomplete(query);
        setState(() {
          _autocompleteSuggestions = suggestions;
        });
      } else {
        setState(() {
          _autocompleteSuggestions = [];
        });
      }
    });
  }

  Future<void> _onSuggestionSelected(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['place_id'];
    final placeDetails = await _placesService.getPlaceDetails(placeId);

    if (placeDetails == null) return;

    final location = placeDetails['geometry']['location'];
    final lat = location['lat'];
    final lng = location['lng'];
    final tappedPoint = LatLng(lat, lng);

    // Determina se a origem ou o destino está em foco
    if (_originController.text == suggestion['description'] ||
        (_originController.text.isNotEmpty &&
            _destinationController.text.isEmpty)) {
      _originController.text = suggestion['description'];
      _handleMapTap(tappedPoint); // Reutiliza a lógica de toque
    } else {
      _destinationController.text = suggestion['description'];
      _handleMapTap(tappedPoint); // Reutiliza a lógica de toque
    }

    setState(() {
      _autocompleteSuggestions = [];
    });
    FocusScope.of(context).unfocus(); // Esconde o teclado
  }

  Future<void> _saveFavoriteRoute() async {
    if (_origin == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma rota na tela para salvar!')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('favorite_origin_lat', _origin!.latitude);
    await prefs.setDouble('favorite_origin_lng', _origin!.longitude);
    await prefs.setDouble('favorite_dest_lat', _destination!.latitude);
    await prefs.setDouble('favorite_dest_lng', _destination!.longitude);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rota favorita salva com sucesso!')),
    );
  }

  Future<void> _loadFavoriteRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final originLat = prefs.getDouble('favorite_origin_lat');
    final originLng = prefs.getDouble('favorite_origin_lng');
    final destLat = prefs.getDouble('favorite_dest_lat');
    final destLng = prefs.getDouble('favorite_dest_lng');

    if (originLat == null ||
        originLng == null ||
        destLat == null ||
        destLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma rota favorita encontrada.')),
      );
      return;
    }

    _resetRoute();
    _handleMapTap(LatLng(originLat, originLng));
    _handleMapTap(LatLng(destLat, destLng));
  }
}
