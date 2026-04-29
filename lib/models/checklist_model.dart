class ChecklistModel {
  bool pneusOk = false;
  bool freiosOk = false;
  bool cintosOk = false;
  bool luzesOk = false;
  bool extintorOk = false;
  bool limpezaOk = false;

  bool get isTudoOk => pneusOk && freiosOk && cintosOk && luzesOk && extintorOk && limpezaOk;

  Map<String, dynamic> toMap(int rotaId) {
    return {
      'rota_id': rotaId,
      'data_hora': DateTime.now().toIso8601String(),
      'itens': 'Pneus:$pneusOk, Freios:$freiosOk, Cintos:$cintosOk, Luzes:$luzesOk, Extintor:$extintorOk, Limpeza:$limpezaOk',
    };
  }
}