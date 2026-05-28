from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID
from typing import List

# Esquema para um único registro de embarque enviado pelo App-Bus
class LogEmbarqueItem(BaseModel):
    aluno_id: UUID = Field(..., description="ID do aluno que realizou o embarque")
    veiculo_id: UUID = Field(..., description="ID do veículo utilizado")
    rota_id: UUID = Field(..., description="ID da rota escolar")
    timestamp_dispositivo: datetime = Field(..., description="Data/Hora do registro no dispositivo móvel")
    latitude: float = Field(..., ge=-90, le=90, description="Latitude capturada no momento do bipaço")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude capturada no momento do bipaço")
    sincronizacao_offline: bool = Field(True, description="Sinaliza se o dado veio do armazenamento local offline")

    class Config:
        from_attributes = True

# Esquema para o lote (payload principal da rota de sincronização)
class LoteLogsEmbarque(BaseModel):
    logs: List[LogEmbarqueItem] = Field(..., min_items=1, description="Lista contendo os logs coletados em lote")