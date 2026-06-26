/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';

import 'package:front_end/features/map/presentation/controllers/map_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // A tela agora é dona de sua própria instância do controller.
  late final MapController mapController;

  @override
  void initState() {
    super.initState();
    // Cria a instância do controller, injetando este State como o TickerProvider.
    // As dependências de serviço ainda são obtidas do locator dentro do controller.
    mapController = MapController(vsync: this);
    // Adiciona um listener para reconstruir a UI quando o controller notificar mudanças.
    mapController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // Chama setState para que o método build seja executado novamente com o novo estado.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          if (mapController.isLoading ||
              mapController.currentPosition == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              CustomInfoWindow(
                controller: mapController.customInfoWindowController,
                height: 100,
                width: 250,
                offset: 50,
              ),
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    mapController.currentPosition!.latitude,
                    mapController.currentPosition!.longitude,
                  ),
                  zoom: 16,
                ),
                onMapCreated: (GoogleMapController controller) {
                  mapController.customInfoWindowController.googleMapController =
                      controller;
                  if (!mapController.mapCompleter.isCompleted) {
                    mapController.mapCompleter.complete(controller);
                  }
                },
                onTap: (position) {
                  mapController.customInfoWindowController.hideInfoWindow!();
                  mapController.handleMapTap(position);
                },
                onCameraMove: (position) {
                  // Agora chama nosso método personalizado que também lida com o desaparecimento.
                  mapController.onCameraMove();
                },
                markers: mapController.markers,
                polylines: mapController.polylines,
                circles: mapController.circles,
                trafficEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled:
                    false, // Desabilitado para não sobrepor
                zoomControlsEnabled: false, // Desabilitado para não sobrepor
                padding: const EdgeInsets.only(top: 150.0, bottom: 40),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    _buildSearchCard(mapController),
                    if (mapController.autocompleteSuggestions.isNotEmpty)
                      _buildSuggestionsList(context, mapController),
                  ],
                ),
              ),
              Positioned(
                bottom: 80, // Posição acima do botão flutuante
                left: 0,
                right: 0,
                child: _buildRouteInfoCard(mapController),
              ),
              Positioned(
                bottom:
                    150, // Posição acima do FAB central e dos botões de rodapé
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: mapController.centerOnUserLocation,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mapController.resetRoute,
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
              onPressed: () => mapController.saveFavoriteRoute(context),
            ),
            TextButton.icon(
              icon: const Icon(Icons.star),
              label: const Text('Carregar Favorita'),
              onPressed: () => mapController.loadFavoriteRoute(context),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Remove o listener e descarta o controller para liberar recursos.
    mapController.removeListener(_onControllerUpdate);
    mapController.dispose();
    super.dispose();
  }

  Widget _buildSearchCard(MapController controller) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          TextField(
            controller: controller.originController,
            decoration: const InputDecoration(
              labelText: 'Origem',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const Divider(height: 1),
          TextField(
            controller: controller.destinationController,
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

  Widget _buildSuggestionsList(BuildContext context, MapController controller) {
    return Card(
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.autocompleteSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = controller.autocompleteSuggestions[index];
          return ListTile(
            title: Text(suggestion['description']),
            onTap: () => controller.onSuggestionSelected(suggestion, context),
          );
        },
      ),
    );
  }

  Widget _buildRouteInfoCard(MapController controller) {
    // Só mostra o card se houver informações de rota
    if (controller.routeDistance == null || controller.routeDuration == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Center(
      child: Card(
        elevation: 6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    controller.routeDistance!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.timer, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    controller.routeDuration!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (controller.numberOfRoutes > 1)
              Container(
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: controller.selectPreviousRoute,
                    ),
                    Text(
                      'Rota ${controller.selectedRouteIndex + 1} de ${controller.numberOfRoutes}',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: controller.selectNextRoute,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
