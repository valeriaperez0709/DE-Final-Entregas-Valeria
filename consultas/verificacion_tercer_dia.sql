SELECT
    fecha,
    COUNT(*) AS total_registros
FROM db_entregas.entregas
GROUP BY fecha
ORDER BY fecha ASC;
