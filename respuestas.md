# Respuestas del examen

## 1. ¿Por qué Athena reconoce el tercer día sin registrar una partición?

Porque la tabla de AWS Glue utiliza partition projection.

La propiedad `projection.enabled=true` permite que Athena
calcule las particiones a partir de la configuración del catálogo,
sin necesidad de registrarlas manualmente.

La partición `fecha` está configurada como tipo `date`, con
formato `yyyy-MM-dd` y rango entre 2026-10-01 y 2026-10-03.

Además, `storage.location.template` permite construir
automáticamente la ruta de cada partición en Amazon S3.

Por eso, al subir el archivo correspondiente al 3 de octubre,
Athena puede consultarlo sin ejecutar MSCK REPAIR TABLE,
ALTER TABLE ADD PARTITION ni modificar Terraform.

## 2. ¿Qué ocurre si se agrega el día 2026-10-04?

Con la configuración actual, Athena no proyecta la partición
2026-10-04 porque está fuera del rango definido:

`projection.fecha.range = 2026-10-01,2026-10-03`

Para incluir ese día sería necesario ampliar el rango hasta
2026-10-04 mediante Terraform.

Después de aplicar ese cambio, Athena podría consultar los
archivos de la nueva fecha utilizando la misma estructura
de carpetas en S3, sin registrar particiones manualmente.
