/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'dart:async';

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../api/directions_service.dart';
import '../../../../api/places_service.dart';
import '../../../../locator.dart';

class MapController with ChangeNotifier {
  // Services
  final PlacesService _placesService;
  final DirectionsService _directionsService;
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  // Map State
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;

  // Route State
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  BitmapDescriptor? _originIcon;
  BitmapDescriptor? _destinationIcon;
  BitmapDescriptor? _customMarkerIcon;
  List<LatLng> _polylineCoordinates = [];
  LatLng? _origin;
  LatLng? _destination;
  List<Map<String, dynamic>> _routes = [];
  int _selectedRouteIndex = 0;
  String? _routeDistance;
  String? _routeDuration;

  // Animation
  AnimationController? _animationController;
  AnimationController? _pulseAnimationController;

  // Search State
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  List<Map<String, dynamic>> _autocompleteSuggestions = [];
  Timer? _debounce;
  bool _isOriginFocused = true;
  LatLng? _infoWindowLatLng;

  // Getters
  bool get isLoading => _isLoading;
  Position? get currentPosition => _currentPosition;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  Set<Circle> get circles => _circles;
  TextEditingController get originController => _originController;
  TextEditingController get destinationController => _destinationController;
  List<Map<String, dynamic>> get autocompleteSuggestions =>
      _autocompleteSuggestions;
  Completer<GoogleMapController> get mapCompleter => _mapCompleter;
  String? get routeDistance => _routeDistance;
  String? get routeDuration => _routeDuration;
  int get numberOfRoutes => _routes.length;
  int get selectedRouteIndex => _selectedRouteIndex;
  CustomInfoWindowController get customInfoWindowController =>
      _customInfoWindowController;

  MapController({required TickerProvider vsync})
      : _placesService = locator<PlacesService>(),
        _directionsService = locator<DirectionsService>() {
    // Os controllers de animação agora usam o TickerProvider que foi injetado.
    _animationController = AnimationController(vsync: vsync);
    _pulseAnimationController = AnimationController(vsync: vsync);
    _loadCustomMarker();
    determinePosition();

    _originController.addListener(() {
      _isOriginFocused = true;
      onSearchChanged(_originController.text);
    });
    _destinationController.addListener(() {
      _isOriginFocused = false;
      onSearchChanged(_destinationController.text);
    });
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    _animationController?.dispose();
    _pulseAnimationController?.dispose();
    _mapController?.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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
    _currentPosition = position;
    _isLoading = false;
    notifyListeners();

    _mapController = await _mapCompleter.future;
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
    _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/bus_marker.png',
    );
    _originIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/origin_marker.png', // Certifique-se que este arquivo existe
    ).catchError((_) => null); // Fallback para não quebrar se o ícone não for encontrado

    _destinationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/destination_marker.png', // Certifique-se que este arquivo existe
    ).catchError((_) => null); // Fallback
  }

  Future<void> handleMapTap(LatLng tappedPoint,
      {Map<String, dynamic>? placeDetails}) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      _stopPulseAnimation();
      _customInfoWindowController.hideInfoWindow!();
      resetRoute();
      _origin = tappedPoint;

      // Se não tivermos detalhes do local, buscamos o endereço via geocodificação reversa.
      final address = placeDetails?['formatted_address'] ??
          await _placesService.getAddressFromCoordinates(tappedPoint);

      // Define o título e o snippet para a InfoWindow
      String title = placeDetails?['name'] ?? 'Origem';
      String snippet = address ??
          '${tappedPoint.latitude.toStringAsFixed(5)}, ${tappedPoint.longitude.toStringAsFixed(5)}';

      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: tappedPoint,
          icon: _originIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              _buildInfoWidget(title, snippet),
              tappedPoint,
            );
            _infoWindowLatLng = tappedPoint;
          },
        ),
      );
    } else if (_destination == null) {
      _customInfoWindowController.hideInfoWindow!();
      _destination = tappedPoint;

      // Se não tivermos detalhes do local, buscamos o endereço via geocodificação reversa.
      final address = placeDetails?['formatted_address'] ??
          await _placesService.getAddressFromCoordinates(tappedPoint);

      // Define o título e o snippet para a InfoWindow
      String title = placeDetails?['name'] ?? 'Destino';
      String snippet = address ??
          '${tappedPoint.latitude.toStringAsFixed(5)}, ${tappedPoint.longitude.toStringAsFixed(5)}';

      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: tappedPoint,
          icon: _destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              _buildInfoWidget(title, snippet),
              tappedPoint,
            );
            _infoWindowLatLng = tappedPoint;
          },
        ),
      );
      _startPulseAnimation(tappedPoint);
      _getDirectionsAndDrawRoute();
    }
    notifyListeners();
  }

  Widget _buildInfoWidget(String title, String snippet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(snippet, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _startPulseAnimation(LatLng position) {
    _pulseAnimationController?.dispose();
    _pulseAnimationController = AnimationController(
      vsync: _pulseAnimationController!.vsync, // Reutiliza o vsync anterior
      duration: const Duration(seconds: 2),
    );

    final radiusAnimation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _pulseAnimationController!, curve: Curves.easeOut),
    );

    final colorAnimation = ColorTween(
      begin: Colors.blue.withOpacity(0.5),
      end: Colors.blue.withOpacity(0),
    ).animate(
      CurvedAnimation(parent: _pulseAnimationController!, curve: Curves.easeOut),
    );

    _pulseAnimationController!.addListener(() {
      _circles.clear();
      _circles.add(
        Circle(
          circleId: const CircleId('destination_pulse'),
          center: position,
          radius: radiusAnimation.value,
          fillColor: colorAnimation.value ?? Colors.transparent,
          strokeWidth: 0,
        ),
      );
      notifyListeners();
    });

    _pulseAnimationController!.repeat();
  }

  void _stopPulseAnimation() {
    _pulseAnimationController?.stop();
    _circles.clear();
  }

  Future<void> _getDirectionsAndDrawRoute() async {
    if (_origin == null || _destination == null) return;

    final directions = await _directionsService.getDirections(
      _origin!.latitude,
      _origin!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );

    if (directions == null || directions['routes'].isEmpty) return;

    // Centraliza o mapa para mostrar a rota inteira
    if (directions['routes'].isNotEmpty) {
      final Map<String, dynamic> bounds = directions['routes'][0]['bounds'];
      final LatLng southwest =
          LatLng(bounds['southwest']['lat'], bounds['southwest']['lng']);
      final LatLng northeast =
          LatLng(bounds['northeast']['lat'], bounds['northeast']['lng']);
      final LatLngBounds latLngBounds =
          LatLngBounds(southwest: southwest, northeast: northeast);

      _mapController
          ?.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 50.0));
    }

    _markers.add(Marker(markerId: const MarkerId('bus_1'), position: _origin!));
    _routes = List<Map<String, dynamic>>.from(directions['routes']);
    _drawAllRoutes();
    _startAnimation();
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
          onTap: () => onRouteTapped(i),
        ),
      );
    }
    notifyListeners();
  }

  void onRouteTapped(int index) {
    if (_selectedRouteIndex == index) return;

    _selectedRouteIndex = index;
    _animationController?.stop();
    _animationController?.reset();

    _drawAllRoutes();
    _startAnimation();
    notifyListeners();
  }

  void _startAnimation() {
    if (_polylineCoordinates.isEmpty) return;

    _animationController?.dispose();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: _animationController!.vsync, // Reutiliza o vsync anterior
    );

    final Animation<double> animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController!);

    animation.addListener(() {
      if (_mapController == null) return;

      final int index = (_polylineCoordinates.length * animation.value).floor();
      final LatLng newPosition = _polylineCoordinates[index];

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

      if (_markers.any((m) => m.markerId.value == 'bus_1')) {
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
        notifyListeners();
      }
    });

    _animationController!.forward();
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController!.repeat();
      }
    });
  }

  void resetRoute() {
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
    _stopPulseAnimation();
    _animationController?.reset();

    _originController.clear();
    _destinationController.clear();
    _autocompleteSuggestions.clear();
    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        _autocompleteSuggestions = await _placesService.getAutocomplete(query);
      } else {
        _autocompleteSuggestions = [];
      }
      notifyListeners();
    });
  }

  Future<void> onSuggestionSelected(
    Map<String, dynamic> suggestion,
    BuildContext context,
  ) async {
    final placeId = suggestion['place_id'];
    final placeDetails = await _placesService.getPlaceDetails(placeId);

    if (placeDetails == null) return;

    final location = placeDetails['geometry']['location'];
    final lat = location['lat'];
    final lng = location['lng'];
    final tappedPoint = LatLng(lat, lng);

    final description = suggestion['description'];

    if (_isOriginFocused) {
      _originController.text = description;
      handleMapTap(tappedPoint, placeDetails: placeDetails);
    } else {
      _destinationController.text = description;
      handleMapTap(tappedPoint, placeDetails: placeDetails);
    }

    _autocompleteSuggestions = [];
    notifyListeners();
    FocusScope.of(context).unfocus();
  }

  Future<void> saveFavoriteRoute(BuildContext context) async {
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

  Future<void> loadFavoriteRoute(BuildContext context) async {
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

    resetRoute();
    handleMapTap(LatLng(originLat, originLng));
    handleMapTap(LatLng(destLat, destLng));
  }
}

  void selectNextRoute() {
    if (_routes.isEmpty || _selectedRouteIndex >= _routes.length - 1) return;
    onRouteTapped(_selectedRouteIndex + 1);
  }

  void selectPreviousRoute() {
    if (_routes.isEmpty || _selectedRouteIndex <= 0) return;
    onRouteTapped(_selectedRouteIndex - 1);
  }

  /// Anima a câmera do mapa para a posição atual do usuário.
  void centerOnUserLocation() {
    if (_currentPosition == null || _mapController == null) {
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  /// Gerencia o movimento da câmera, atualizando a posição da InfoWindow
  /// e a escondendo se o marcador sair da tela.
  Future<void> onCameraMove() async {
    // Permite que o pacote reposicione a janela.
    _customInfoWindowController.onCameraMove!();

    // Se não houver uma janela de informações ativa ou o mapa não estiver pronto, não faz nada.
    if (_infoWindowLatLng == null || _mapController == null) {
      return;
    }

    // Obtém os limites visíveis do mapa.
    final LatLngBounds visibleRegion = await _mapController!.getVisibleRegion();

    // Se a posição do marcador da janela não estiver contida na região visível, esconde a janela.
    if (!visibleRegion.contains(_infoWindowLatLng!)) {
      _customInfoWindowController.hideInfoWindow!();
      _infoWindowLatLng = null;
    }
  }
}
