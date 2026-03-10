
WITH source_data AS (

    SELECT *
    FROM NDC_EDI.dbo.tbl_NDC_COMMON_CLAIM_STAGING
    WHERE 1=1
      {% if var('healthplan', none) %}
        AND HealthPlan = '{{ var("healthplan") }}'
      {% endif %}
      {% if var('processid', none) %}
        AND ProcessID = '{{ var("processid") }}'
      {% endif %}

)

SELECT *
FROM source_data
