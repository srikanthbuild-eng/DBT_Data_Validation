{% macro log_column_profile(model, columns, test_name) %}
  {% if columns is not none %}
    {% for col in columns %}
      {% set sql %}
      DECLARE @total_count INT, @null_count INT, @null_pct FLOAT, @distinct_count INT, @min_val NVARCHAR(100), @max_val NVARCHAR(100);

      SELECT
          @total_count = COUNT(*),
          @null_count = COUNT(*) - COUNT({{ col }}),
          @null_pct = CASE WHEN COUNT(*) = 0 THEN 0 ELSE CAST(COUNT(*) - COUNT({{ col }}) AS FLOAT) / COUNT(*) * 100 END,
          @distinct_count = COUNT(DISTINCT {{ col }}),
          @min_val = CAST(MIN({{ col }}) AS NVARCHAR),
          @max_val = CAST(MAX({{ col }}) AS NVARCHAR)
      FROM {{ model }};

      DELETE FROM NonDelegatedClaims.dbo.DBT_NDC_Validation_SummaryLog
      WHERE 
          HealthPlan = '{{ var("healthplan") }}'
          AND ProcessID = '{{ var("processid") }}'
          AND ModelName = '{{ model.name }}'
          AND TestName = '{{ test_name }}_{{ col }}';

      INSERT INTO NonDelegatedClaims.dbo.DBT_NDC_Validation_SummaryLog
      (HealthPlan ,ProcessID, ModelName, TestCategory, TestName, TotalCount, NullCount, NullPercentage, DistinctCount, MinValue, MaxValue)
      VALUES
      (
        '{{ var("healthplan") }}',
        '{{ var("processid") }}',
        '{{ model.name }}',
        'column_profile',
        '{{ test_name }}_{{ col }}',
        @total_count,
        @null_count,
        @null_pct,
        @distinct_count,
        @min_val,
        @max_val
      );
      {% endset %}

      {% do run_query(sql) %}
    {% endfor %}
  {% else %}
    {{ exceptions.raise_compiler_error("The 'columns' list (var('profiling_columns')) is None or not passed.") }}
  {% endif %}
{% endmacro %}