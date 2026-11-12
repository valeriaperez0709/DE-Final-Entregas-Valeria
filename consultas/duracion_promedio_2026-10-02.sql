SELECT
    fecha,
    CAST(
        ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2)
        AS DECIMAL(10,2)
    ) AS duracion_promedio_minutos
FROM db_entregas.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
