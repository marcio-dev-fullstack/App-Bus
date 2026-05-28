from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert
# Assumindo que você tenha o arquivo de configuração do banco (database.py e models.py)
from database import get_db 
import models
import schemas

router = APIRouter(prefix="/v1/logs", tags=["Auditoria de Logs"])

@router.post("/sincronizar-lote", status_code=status.HTTP_201_CREATED)
async def sincronizar_logs_em_lote(
    payload: schemas.LoteLogsEmbarque, 
    db: AsyncSession = Depends(get_db)
):
    """
    Endpoint utilizado pelo App-Bus para descarregar os logs de embarque 
    armazenados localmente no dispositivo (Sincronização Offline / Em Lote).
    """
    if not payload.logs:
        raise HTTPException(
            status_code=400, 
            detail="O lote enviado não contém registros para processamento."
        )

    try:
        # Prepara a lista de dicionários para inserção em massa eficiente
        dados_insercao = [
            {
                "aluno_id": log.aluno_id,
                "veiculo_id": log.veiculo_id,
                "rota_id": log.rota_id,
                "timestamp_dispositivo": log.timestamp_dispositivo,
                "latitude": log.latitude,
                "longitude": log.longitude,
                "sincronizacao_offline": log.sincronizacao_offline
                # 'timestamp_servidor' será preenchido automaticamente pelo banco
            }
            for log in payload.logs
        ]

        # Executa o Bulk Insert usando a tabela mapeada pelo SQLAlchemy Core/ORM
        stmt = insert(models.LogEmbarque).values(dados_insercao)
        await db.execute(stmt)
        await db.commit()

        return {
            "status": "sucesso",
            "mensagem": f"Lote processado com sucesso. {len(dados_insercao)} logs integrados para auditoria da SEMEC."
        }

    except Exception as e:
        await db.rollback()
        # Tratamento genérico para capturar violações de FK ou erros de conexão
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Falha ao persistir lote de auditoria: {str(e)}"
        )