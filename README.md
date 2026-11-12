---

# Implementación realizada — Examen Final de Ingeniería de Datos

## 1. Descripción de la solución

Se implementó un pipeline de ingeniería de datos en AWS para almacenar y analizar registros de entregas correspondientes al 1, 2 y 3 de octubre de 2026.

La infraestructura fue creada mediante Terraform y está compuesta por Amazon S3, AWS Glue Data Catalog y Amazon Athena.

El objetivo principal fue demostrar cómo incorporar datos de nuevas fechas utilizando **partition projection**, sin ejecutar crawlers ni registrar particiones manualmente.

### Arquitectura implementada

```text
Archivos CSV
    |
    v
Amazon S3
(entregas/fecha=YYYY-MM-DD/)
    |
    v
AWS Glue Data Catalog
(Base de datos: db_entregas)
(Tabla externa: entregas)
(Partition Projection)
    |
    v
Amazon Athena
(Workgroup: wg_entregas)
    |
    v
Amazon S3
(resultados-athena/)
```

Los datos originales permanecen almacenados en S3. Glue define el esquema y las propiedades de partición, mientras que Athena ejecuta las consultas SQL.

## 2. Herramientas y prerrequisitos

Se utilizaron las siguientes herramientas:

- Terraform para definir la infraestructura como código.
- AWS CLI para interactuar con los servicios de AWS.
- Amazon S3 para almacenar los datos y los resultados de Athena.
- AWS Glue Data Catalog para definir la tabla externa.
- Amazon Athena para consultar los datos.
- Python para automatizar la ejecución y descarga de resultados.
- Git y GitHub para controlar versiones y entregar el proyecto.

Para reproducir el ejercicio se requiere tener instalados Terraform, AWS CLI y Python 3, además de contar con credenciales AWS configuradas y permisos suficientes sobre S3, Glue y Athena.

**Región utilizada:** `us-east-1`

### Recursos de AWS

| Recurso | Nombre |
|---|---|
| Bucket S3 | `de-final-entregas-234329974394-2026` |
| Base de datos Glue | `db_entregas` |
| Tabla externa Glue | `entregas` |
| Workgroup Athena | `wg_entregas` |
| Prefijo de entrada | `entregas/` |
| Prefijo de resultados | `resultados-athena/` |

El nombre del bucket debe ser único a nivel global. Para reproducir el ejercicio en otra cuenta AWS, debe utilizarse un nombre disponible.

## 3. Despliegue de infraestructura con Terraform

La infraestructura se definió en la carpeta `infraestructura/`, utilizando los siguientes archivos:

- `principal.tf`: proveedor AWS y recursos S3, Glue y Athena.
- `variables.tf`: región AWS y nombre del bucket.
- `salidas.tf`: outputs de los recursos creados.

Desde la raíz del repositorio se ejecutan:

```bash
terraform -chdir=infraestructura init
terraform -chdir=infraestructura fmt
terraform -chdir=infraestructura validate
```

Para crear la infraestructura:

```bash
terraform -chdir=infraestructura plan \
  -var="bucket_name=de-final-entregas-234329974394-2026"

terraform -chdir=infraestructura apply \
  -var="bucket_name=de-final-entregas-234329974394-2026"
```

Para consultar los recursos creados:

```bash
terraform -chdir=infraestructura output
```

Los outputs se guardaron en:

`evidencias/outputs.json`

La evidencia de aplicación se encuentra en:

`evidencias/aplicacion_terraform.txt`

## 4. Configuración de Partition Projection

La tabla externa `db_entregas.entregas` utiliza partition projection para reconocer las fechas sin registrar particiones individuales.

Las principales propiedades configuradas fueron:

| Propiedad | Valor |
|---|---|
| `projection.enabled` | `true` |
| `projection.fecha.type` | `date` |
| `projection.fecha.format` | `yyyy-MM-dd` |
| `projection.fecha.range` | `2026-10-01,2026-10-03` |
| `projection.fecha.interval` | `1` |
| `projection.fecha.interval.unit` | `DAYS` |

La ubicación de los datos se construye a partir de la fecha:

```text
s3://<bucket>/entregas/fecha=${fecha}/
```

La columna `fecha` no está incluida dentro de los archivos CSV, sino que se obtiene de la estructura de carpetas de S3.

Con esta configuración, Athena puede consultar las fechas comprendidas en el rango definido siempre que existan archivos en las rutas correspondientes.

## 5. Primera etapa: carga de los días 1 y 2

Inicialmente se cargaron únicamente los archivos del 1 y 2 de octubre de 2026.

### Carga de archivos a S3

```bash
aws s3 cp \
  data/entregas/fecha=2026-10-01/entregas.csv \
  s3://de-final-entregas-234329974394-2026/entregas/fecha=2026-10-01/entregas.csv

aws s3 cp \
  data/entregas/fecha=2026-10-02/entregas.csv \
  s3://de-final-entregas-234329974394-2026/entregas/fecha=2026-10-02/entregas.csv
```

Cada archivo contiene seis registros, por lo que en esta etapa se consultaron **12 registros en total**.

### Consultas iniciales

Se desarrollaron tres consultas:

1. `consultas/intentos_por_fecha_estado.sql`: cantidad de intentos agrupados por fecha y estado.
2. `consultas/porcentaje_exito_por_fecha_ciudad.sql`: porcentaje de entregas exitosas agrupadas por fecha y ciudad.
3. `consultas/duracion_promedio_2026-10-02.sql`: duración promedio de las entregas exitosas del 2 de octubre.

Para ejecutar las consultas mediante el script de automatización:

```bash
python3 scripts/ejecutar_athena.py inicial
```

Los resultados de esta etapa se almacenaron en:

```text
resultados/inicial/
├── intentos_por_fecha_estado.csv
├── porcentaje_exito_por_fecha_ciudad.csv
└── duracion_promedio_2026-10-02.csv
```

Los resultados iniciales contienen únicamente las fechas `2026-10-01` y `2026-10-02`.

## 6. Segunda etapa: incorporación del tercer día

Posteriormente se incorporó el archivo del 3 de octubre de 2026, sin modificar la infraestructura.

### Carga del archivo

```bash
aws s3 cp \
  data/entregas/fecha=2026-10-03/entregas.csv \
  s3://de-final-entregas-234329974394-2026/entregas/fecha=2026-10-03/entregas.csv
```

Gracias a partition projection, Athena reconoció la nueva fecha sin ejecutar:

- Crawlers de AWS Glue.
- `MSCK REPAIR TABLE`.
- `ALTER TABLE ADD PARTITION`.
- Cambios en la configuración de Terraform.

### Ejecución de consultas finales

```bash
python3 scripts/ejecutar_athena.py final
```

Se ejecutaron nuevamente las consultas de intentos y porcentaje de éxito, además de la consulta de verificación del tercer día.

Los resultados se almacenaron en:

```text
resultados/final/
├── intentos_por_fecha_estado.csv
├── porcentaje_exito_por_fecha_ciudad.csv
└── verificacion_tercer_dia.csv
```

### Verificación de registros

La consulta `consultas/verificacion_tercer_dia.sql` permitió comprobar:

| Fecha | Registros |
|---|---:|
| 2026-10-01 | 6 |
| 2026-10-02 | 6 |
| 2026-10-03 | 6 |
| **Total** | **18** |

La consulta de intentos por fecha y estado también permite comprobar los conteos correspondientes al tercer día.

## 7. Validación de resultados

Los resultados generados por Athena se comparan con los archivos suministrados por el profesor en `resultados_esperados/`.

Desde la raíz del proyecto se ejecutan:

```bash
diff -u resultados_esperados/intentos_por_fecha_estado_inicial.csv resultados/inicial/intentos_por_fecha_estado.csv

diff -u resultados_esperados/porcentaje_exito_por_fecha_ciudad_inicial.csv resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv

diff -u resultados_esperados/duracion_promedio_2026-10-02.csv resultados/inicial/duracion_promedio_2026-10-02.csv

diff -u resultados_esperados/intentos_por_fecha_estado_final.csv resultados/final/intentos_por_fecha_estado.csv

diff -u resultados_esperados/porcentaje_exito_por_fecha_ciudad_final.csv resultados/final/porcentaje_exito_por_fecha_ciudad.csv
```

Cuando `diff` no muestra diferencias, significa que el archivo obtenido coincide exactamente con el archivo de referencia.

Los identificadores de ejecución de Athena se registraron en:

`evidencias/ejecuciones_athena.csv`

Este archivo relaciona cada ejecución con su etapa, consulta SQL, identificador de Athena y archivo de resultados.

## 8. Evidencias de la implementación

La carpeta `evidencias/` contiene los archivos necesarios para comprobar la ejecución del ejercicio.

| Archivo | Descripción |
|---|---|
| `aplicacion_terraform.txt` | Registro de la creación de infraestructura, incluidos los intentos y el despliegue exitoso |
| `outputs.json` | Identificadores de los recursos creados |
| `ejecuciones_athena.csv` | Consultas ejecutadas, etapas e identificadores de ejecución |
| `eliminacion_terraform.txt` | Registro de eliminación de los recursos AWS al finalizar |

Las consultas SQL se encuentran en `consultas/` y sus resultados en `resultados/inicial/` y `resultados/final/`.

Las respuestas a las preguntas conceptuales están documentadas en `respuestas.md`.

## 9. Limpieza de recursos AWS

Al finalizar el ejercicio, y después de guardar todas las evidencias, se debe verificar que el bucket contiene únicamente los archivos de este proyecto.

Para revisar su contenido:

```bash
aws s3 ls s3://de-final-entregas-234329974394-2026/ --recursive
```

Una vez confirmado que se puede eliminar su contenido, se vacía el bucket:

```bash
aws s3 rm s3://de-final-entregas-234329974394-2026/ --recursive
```

Posteriormente se destruye la infraestructura administrada por Terraform:

```bash
terraform -chdir=infraestructura destroy \
  -var="bucket_name=de-final-entregas-234329974394-2026"
```

Para guardar la evidencia de eliminación, se puede ejecutar el comando anterior con salida a un archivo:

```bash
set -o pipefail

terraform -chdir=infraestructura destroy \
  -var="bucket_name=de-final-entregas-234329974394-2026" \
  -auto-approve -no-color 2>&1 | tee evidencias/eliminacion_terraform.txt
```

La eliminación se considera completa cuando Terraform informa `Destroy complete!` y se comprueba que no quedan recursos del ejercicio en su estado.

## 10. Conclusión

Se implementó un pipeline de ingeniería de datos utilizando infraestructura como código y servicios administrados de AWS.

La primera etapa permitió consultar 12 registros correspondientes a dos fechas. Posteriormente, al incorporar un tercer archivo CSV, Athena reconoció los seis registros adicionales y permitió consultar un total de 18.

La implementación demuestra que **partition projection permite consultar nuevas particiones dentro de un rango configurado sin registrarlas individualmente**, simplificando la incorporación de datos y manteniendo la infraestructura reproducible mediante Terraform.
