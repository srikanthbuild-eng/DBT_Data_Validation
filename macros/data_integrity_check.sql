{% test data_integrity_check(model, sql, threshold, test_name) %}
  {% set rendered_sql = sql | replace("{{ model }}", model) %}

  WITH source_data AS (
    SELECT * FROM {{ model }}
  ),
  error_data AS (
    {{ rendered_sql }}
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


  {% call statement('log_result_' ~ test_name, fetch_result=False) %}
    DECLARE @total_count INT = 0, @error_count INT = 0, @error_percentage DECIMAL(5,2) = 0.0, @result_status NVARCHAR(10) = 'PASS';

    SELECT
      @total_count = (SELECT COUNT(*) FROM {{ model }}),
      @error_count = (SELECT COUNT(*) FROM ({{ rendered_sql }}) AS err);

    IF @total_count > 0
      SET @error_percentage = (100.0 * @error_count) / @total_count;

    IF @error_percentage > {{ threshold }}
      SET @result_status = 'FAIL';

 
	--====================================
	---- INSERT INTO SUMAMRY LOG 
	--====================================
		
		DELETE FROM NonDelegatedClaims.dbo.DBT_NDC_Validation_SummaryLog
		WHERE 
			HealthPlan = '{{ var("healthplan") }}'
			AND ProcessID = '{{ var("processid") }}'
			AND ModelName = '{{ model.name }}'
			AND TestName = '{{ test_name }}'

		DELETE FROM NonDelegatedClaims.dbo.DBT_NDC_Validation_Failure_Detail
		WHERE 
				HealthPlan = '{{ var("healthplan") }}'
				AND ProcessID = '{{ var("processid") }}'
				AND ModelName = '{{ model.name }}'
				AND TestName = '{{ test_name }}'


		INSERT INTO NonDelegatedClaims.dbo.DBT_NDC_Validation_SummaryLog
		(HealthPlan ,ProcessID, ModelName, TestCategory, TestName, TotalCount, ErrorCount, ThresholdPercentage, ErrorPercentage, ResultStatus)
		VALUES
		(
			'{{ var("healthplan") }}',
			'{{ var("processid") }}',
			'{{ model.name }}',
			'data_integrity_check',
			'{{ test_name }}',
			@total_count,
			@error_count,
			{{ threshold }},
			@error_percentage,
			@result_status
		);
		
  {% endcall %}
{% endtest %}