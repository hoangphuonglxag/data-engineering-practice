WITH mb_summary AS (
    SELECT 
        customer_id,
        COUNT(device_id) AS device_count
    FROM mb_devices
    WHERE status = 'ACTIVE'
    GROUP BY customer_id
),
ib_summary AS (
    SELECT 
        customer_id,
        COUNT(ib_user_id) AS ib_count
    FROM ib_users
    WHERE status = 'ACTIVE'
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.full_name,
    CASE 
        WHEN COALESCE(ib.ib_count, 0) > 0 THEN 'YES' 
        ELSE 'NO' 
    END AS has_ib,
    CASE 
        WHEN COALESCE(mb.device_count, 0) > 0 THEN 'YES' 
        ELSE 'NO' 
    END AS has_mb,
    COALESCE(mb.device_count, 0) AS device_count
FROM core_customers AS c
LEFT JOIN ib_summary AS ib 
    ON c.customer_id = ib.customer_id
LEFT JOIN mb_summary AS mb 
    ON c.customer_id = mb.customer_id
ORDER BY c.customer_id
LIMIT 10;