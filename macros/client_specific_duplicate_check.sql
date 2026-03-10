{% test client_specific_duplicate_check(model, rules, test_name) %}
  {% set target_healthplan = var('healthplan', 'default_healthplan') %}  -- Get the healthplan variable, with a default fallback

  {% set filtered_rules = [] %}
  {% for rule in rules %}
    {% if rule.HealthPlan == target_healthplan %}
      {% set _ = filtered_rules.append(rule) %}  -- Add matching rule to filtered_rules
    {% endif %}
  {% endfor %}

  {% if filtered_rules | length == 0 %}
    -- No matching HealthPlan found, return an empty result set to avoid test failure
    SELECT 1 AS dummy_column WHERE 1 = 0
  {% else %}
    {% for rule in filtered_rules %}
      {% set health_plan = rule.HealthPlan %}
      {% set columns = rule.columns %}
      {% set threshold = rule.threshold %}
      {% set column_list = columns | join(', ') %}
      {% set column_alias = columns | map('replace', '.', '_') | join('_') %}

      {% set duplicate_sql %}
        SELECT {{ column_list }}
        FROM {{ model }}
        WHERE HealthPlan = '{{ health_plan }}'
        GROUP BY {{ column_list }}
        HAVING COUNT(*) > 1
      {% endset %}

      WITH source_data AS (
        SELECT * FROM {{ model }} WHERE HealthPlan = '{{ health_plan }}'
      ),
      error_data AS (
        {{ duplicate_sql }}
      )
      SELECT
        CASE
          WHEN total_records.total_count = 0 THEN 0
          ELSE (error_records.error_count * 100.0 / total_records.total_count)
        END AS error_percentage
      FROM
        (SELECT COUNT(*) AS total_count FROM source_data) AS total_records,
        (SELECT COUNT(*) AS error_count FROM error_data) AS error_records
      WHERE
        CASE
          WHEN total_records.total_count = 0 THEN 0
          ELSE (error_records.error_count * 100.0 / total_records.total_count)
        END > {{ threshold }}

      {% call statement('log_result_' ~ test_name ~ '_' ~ health_plan, fetch_result=False) %}
        DECLARE @total_count INT = 0, @error_count INT = 0, @error_percentage DECIMAL(5,2) = 0.0, @result_status NVARCHAR(10) = 'PASS';

        SELECT
          @total_count = (SELECT COUNT(*) FROM {{ model }} WHERE HealthPlan = '{{ health_plan }}'),
          @error_count = (SELECT COUNT(*) FROM ({{ duplicate_sql }}) AS err);

        IF @total_count > 0
          SET @error_percentage = (100.0 * @error_count) / @total_count;

        IF @error_percentage > {{ threshold }}
          SET @result_status = 'FAIL';

      --====================================
      ---- INSERT INTO SUMMARY LOG 
      --====================================
      DELETE FROM NonDelegatedClaims.dbo.DBT_NDC_Validation_SummaryLog
      WHERE 
        HealthPlan = '{{ health_plan }}'
        AND ProcessID = '{{ var("processid") }}'
        AND ModelName = '{{ model.name }}'
        AND TestName = '{{ test_name }}_{{ health_plan }}';


      INSERT INTO NonDelegatedClaims.dbo.DBT_NDC_Validation_SummaryLog
      (HealthPlan, ProcessID, ModelName, TestCategory, TestName, TotalCount, ErrorCount, ThresholdPercentage, ErrorPercentage, ResultStatus)
      VALUES
      (
        '{{ health_plan }}',
        '{{ var("processid") }}',
        '{{ model.name }}',
        'client_specific_check',
        '{{ test_name }}_{{ health_plan }}',
        @total_count,
        @error_count,
        {{ threshold }},
        @error_percentage,
        @result_status
      );
    {% endcall %}

    {% if not loop.last %} UNION ALL {% endif %}
    {% endfor %}
  {% endif %}
{% endtest %}