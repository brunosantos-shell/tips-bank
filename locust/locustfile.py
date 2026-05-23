"""
Locust - Stress Test TipsBank

Fluxo:
1. Cria contas via api-contas
2. Realiza transferências via api-transacoes
3. Consulta extrato via api-contas

Objetivo:
- HPA escalar api-transacoes >5 replicas
- Error rate <1%
- Simular comportamento real

Execução:

locust --headless \
-u 300 \
-r 30 \
-t 10m
"""

import random
import uuid
from threading import Lock

from locust import HttpUser, task, between, events

CONTAS_CRIADAS = []
LOCK = Lock()


class UsuarioBanco(HttpUser):

    wait_time = between(0.5, 2)

    def on_start(self):

        documento = "".join(
            random.choices(
                "0123456789",
                k=11
            )
        )

        payload = {
            "titular": f"Aluno-{uuid.uuid4().hex[:6]}",
            "documento": documento,
            "senha": documento,
            "saldo_inicial": "10000.00"
        }

        with self.client.post(
            "http://api-contas.tipsbank-contas:8080/contas",
            json=payload,
            name="api-contas /contas",
            catch_response=True
        ) as r:

            if r.status_code == 201:

                try:

                    conta_id = r.json()["id"]

                    with LOCK:
                        CONTAS_CRIADAS.append(conta_id)

                    r.success()

                except Exception as e:

                    r.failure(
                        f"json inválido: {e}"
                    )

            else:

                r.failure(
                    f"falha criando conta: "
                    f"{r.status_code} "
                    f"{r.text}"
                )

    @task(3)
    def transferir(self):

        if len(CONTAS_CRIADAS) < 2:
            return

        try:

            origem, destino = random.sample(
                CONTAS_CRIADAS,
                2
            )

            valor = round(
                random.uniform(
                    1,
                    50
                ),
                2
            )

            payload = {
                "origem_id": origem,
                "destino_id": destino,
                "valor": str(valor)
            }

            with self.client.post(
                "/transferencias",
                json=payload,
                name="api-transacoes /transferencias",
                catch_response=True
            ) as r:

                if r.status_code in [200, 201]:

                    r.success()

                else:

                    r.failure(
                        f"erro transferencia "
                        f"{r.status_code}"
                    )

        except Exception as e:

            print(
                f"erro: {e}"
            )

    @task(1)
    def consultar_extrato(self):

        if not CONTAS_CRIADAS:
            return

        conta = random.choice(
            CONTAS_CRIADAS
        )

        with self.client.get(
            f"http://api-contas.tipsbank-contas:8080/extrato/{conta}",
            name="api-contas /extrato/:id",
            catch_response=True
        ) as r:

            if r.status_code == 200:
                r.success()
            else:
                r.failure(
                    f"erro extrato "
                    f"{r.status_code}"
                )


@events.test_stop.add_listener
def resumo(environment, **kwargs):

    print("\n")
    print("=" * 60)

    print(
        f"Contas criadas: "
        f"{len(CONTAS_CRIADAS)}"
    )

    print("=" * 60)