SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(
            100.0 * SUM(
                CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END
            ) / COUNT(*),
            2
        ) AS DECIMAL(10,2)
    ) AS porcentaje_exito
FROM db_entregas.entregas
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
