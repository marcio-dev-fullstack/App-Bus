/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:mockito/annotations.dart';

import 'package:front_end/api/directions_service.dart';
import 'package:front_end/api/places_service.dart';

// Anote as classes que você deseja simular.
@GenerateMocks([PlacesService, DirectionsService])
void main() {}
