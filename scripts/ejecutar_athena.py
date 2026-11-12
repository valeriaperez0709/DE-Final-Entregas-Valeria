import sys
import csv
import json
import subprocess
import time
from pathlib import Path

REGION = "us-east-1"
WORKGROUP = "wg_entregas"
DATABASE = "db_entregas"
ETAPA = sys.argv[1] if len(sys.argv) > 1 else "inicial"

CONSULTAS = [
    "intentos_por_fecha_estado",
    "porcentaje_exito_por_fecha_ciudad",
    "duracion_promedio_2026-10-02",
]

if ETAPA == "final":
    CONSULTAS = [
        "verificacion_tercer_dia",
        "intentos_por_fecha_estado",
        "porcentaje_exito_por_fecha_ciudad",
    ]

def aws(*args):
    resultado = subprocess.run(
        ["aws", *args, "--region", REGION, "--output", "json"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(resultado.stdout)

def ejecutar(nombre):
    archivo_sql = Path("consultas") / f"{nombre}.sql"
    archivo_resultado = Path("resultados") / ETAPA / f"{nombre}.csv"

    sql = archivo_sql.read_text(encoding="utf-8")

    respuesta = aws(
        "athena", "start-query-execution",
        "--query-string", sql,
        "--query-execution-context", f"Database={DATABASE}",
        "--work-group", WORKGROUP,
    )

    query_id = respuesta["QueryExecutionId"]
    print(f"\nEjecutando: {nombre}")
    print(f"ID: {query_id}")

    while True:
        ejecucion = aws(
            "athena", "get-query-execution",
            "--query-execution-id", query_id,
        )

        estado = ejecucion["QueryExecution"]["Status"]
        valor = estado["State"]

        if valor == "SUCCEEDED":
            break

        if valor in ("FAILED", "CANCELLED"):
            raise RuntimeError(
                f"Consulta {nombre}: {valor}: "
                f"{estado.get('StateChangeReason', '')}"
            )

        time.sleep(2)

    filas = []
    token = None

    while True:
        argumentos = [
            "athena", "get-query-results",
            "--query-execution-id", query_id,
        ]

        if token:
            argumentos += ["--next-token", token]

        datos = aws(*argumentos)

        for fila in datos["ResultSet"]["Rows"]:
            filas.append([
                celda.get("VarCharValue", "")
                for celda in fila["Data"]
            ])

        token = datos.get("NextToken")
        if not token:
            break

    archivo_resultado.parent.mkdir(parents=True, exist_ok=True)

    with archivo_resultado.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f, lineterminator="\n").writerows(filas)

    evidencia = Path("evidencias/ejecuciones_athena.csv")
    nuevo = not evidencia.exists() or evidencia.stat().st_size == 0

    with evidencia.open("a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, lineterminator="\n")

        if nuevo:
            writer.writerow([
                "etapa", "archivo_sql",
                "id_ejecucion", "archivo_resultado"
            ])

        writer.writerow([
            ETAPA,
            str(archivo_sql),
            query_id,
            str(archivo_resultado),
        ])

    print(f"Estado: SUCCEEDED")
    print(f"Resultado: {archivo_resultado}")
    print(f"Filas de datos: {max(0, len(filas) - 1)}")

for consulta in CONSULTAS:
    ejecutar(consulta)

print("\nConsultas iniciales completadas.")
