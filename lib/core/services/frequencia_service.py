from datetime import date, datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import and_, func
from uuid import UUID
import models

class ConsolidadorFrequencia:
    
    @staticmethod
    def determinar_turno(hora: datetime) -> str:
        """Define o turno com base no horário do dispositivo."""
        hora_local = hora.hour
        if 5 <= hora_local < 12:
            return "Matutino"
        elif 12 <= hora_local < 18:
            return "Vespertino"
        else:
            return "Noturno"

    @classmethod
    async def consolidar_dia(cls, data_ref: date, rota_id: UUID, db: AsyncSession):
        """
        Varre os logs de uma rota específica em uma data e consolida a 
        presença de todos os alunos vinculados àquela rota.
        """
        # 1. Buscar todos os alunos que estão oficialmente vinculados a esta rota
        stmt_alunos = select(models.Aluno).where(models.Aluno.rota_id == rota_id)
        resultado_alunos = await db.execute(stmt_alunos)
        alunos_oficiais = resultado_alunos.scalars().all()
        
        if not alunos_oficiais:
            return {"status": "aviso", "mensagem": "Nenhum aluno vinculado a esta rota."}

        # 2. Buscar todos os logs de embarque daquela rota no dia específico
        stmt_logs = select(models.LogEmbarque).where(
            and_(
                models.LogEmbarque.rota_id == rota_id,
                func.date(models.LogEmbarque.timestamp_dispositivo) == data_ref
            )
        )
        resultado_logs = await db.execute(stmt_logs)
        logs_dia = resultado_logs.scalars().all()

        # Mapeamento auxiliar para processar por turno e por aluno
        # Estrutura: { (aluno_id, turno): {"ida": bool, "volta": bool} }
        mapa_presenca = {}

        for log in logs_dia:
            turno = cls.determinar_turno(log.timestamp_dispositivo)
            chave = (log.aluno_id, turno)
            
            if chave not in mapa_presenca:
                mapa_presenca[chave] = {"ida": False, "volta": False}
            
            # Regra de Negócio SEMEC: Identificar se o horário do log tende 
            # mais para o início ou fim do turno (ex: antes/depois das 10h para o Matutino)
            hora_log = log.timestamp_dispositivo.hour
            if turno == "Matutino":
                if hora_log < 10:
                    mapa_presenca[chave]["ida"] = True
                else:
                    mapa_presenca[chave]["volta"] = True
            elif turno == "Vespertino":
                if hora_log < 15:
                    mapa_presenca[chave]["ida"] = True
                else:
                    mapa_presenca[chave]["volta"] = True
            else: # Noturno
                if hora_log < 20:
                    mapa_presenca[chave]["ida"] = True
                else:
                    mapa_presenca[chave]["volta"] = True

        # 3. Processar cada aluno oficial e gerar/atualizar o registro de frequência
        registros_consolidados = 0
        
        for aluno in alunos_oficiais:
            # Avaliamos os turnos padrões associados (aqui simulando Matutino e Vespertino)
            for turno in ["Matutino", "Vespertino"]:
                chave = (aluno.id, turno)
                
                # Se o aluno tem logs gravados neste turno
                if chave in mapa_presenca:
                    ida = mapa_presenca[chave]["ida"]
                    volta = mapa_presenca[chave]["volta"]
                    
                    # Definição do Status de Auditoria
                    if ida and volta:
                        status_presenca = "Presente"
                    else:
                        # Alerta visual para o Painel da SEMEC: Embarcou em um trajeto mas não no outro
                        status_presenca = "Inconsistente"
                else:
                    # Se não há nenhum registro do aluno no turno, é computada Falta
                    ida = False
                    volta = False
                    status_presenca = "Falta"

                # Monta a estrutura para salvar (Upsert - se já existir atualiza, se não, insere)
                # Evita duplicidade usando a constraint única (data, aluno, turno)
                frequencia_data = {
                    "data_referencia": data_ref,
                    "aluno_id": aluno.id,
                    "rota_id": rota_id,
                    "turno": turno,
                    "embarque_ida": ida,
                    "embarque_volta": volta,
                    "status_presenca": status_presenca,
                    "atualizado_em": func.current_timestamp()
                }

                # Executa o comando de Upsert
                from sqlalchemy.dialects.postgresql import insert
                stmt_upsert = insert(models.FrequenciaConsolidada).values(frequencia_data)
                stmt_upsert = stmt_upsert.on_conflict_do_update(
                    constraint="unique_frequencia_aluno_dia",
                    set_={
                        "embarque_ida": stmt_upsert.excluded.embarque_ida,
                        "embarque_volta": stmt_upsert.excluded.embarque_volta,
                        "status_presenca": stmt_upsert.excluded.status_presenca,
                        "atualizado_em": func.current_timestamp()
                    }
                )
                
                await db.execute(stmt_upsert)
                registros_consolidados += 1

        await db.commit()
        return {
            "status": "sucesso", 
            "mensagem": f"Consolidação concluída. {registros_consolidados} registros de frequências gerados/atualizados."
        }