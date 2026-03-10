{% test reference_table_check(model, source_columns, lookup_table, lookup_column, threshold, test_name) %}


WITH source_data AS (

    SELECT *
    FROM {{ model }}

),


error_data AS (
    SELECT *
    FROM {{ model }}
    WHERE
    (
        {% for col_expr in source_columns %}
            ({{ col_expr }} NOT IN (SELECT {{ lookup_column }} FROM {{ lookup_table }}))
            {% if not loop.last %}
                AND
            {% endif %}
        {% endfor %}
    )
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




	{% call statement('log_result', fetch_result=False) %}
		DECLARE @total_count INT, @error_count INT, @error_percentage DECIMAL(5,2), @result_status NVARCHAR(10);

		-- Pull total_count and error_count
		SELECT
			@total_count = total_count,
			@error_count = error_count
		FROM (
			SELECT
				(SELECT COUNT(*) FROM {{ model }}) AS total_count,
				(SELECT COUNT(*) FROM {{ model }} 
					WHERE     (
								{% for col_expr in source_columns %}
								({{ col_expr }} NOT IN (SELECT {{ lookup_column }} FROM {{ lookup_table }}))
								{% if not loop.last %}
								AND
								{% endif %}
								{% endfor %}
							  )
				) AS error_count
		) AS counts;

		-- Calculate error percentage
		IF @total_count = 0
			SET @error_percentage = 0;
		ELSE
			SET @error_percentage = (@error_count * 100.0 / @total_count);

		-- Determine pass or fail
		IF @error_percentage > {{ threshold }}
			SET @result_status = 'FAIL';
		ELSE
			SET @result_status = 'PASS';


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
			'reference_table_check',
			'{{ test_name }}',
			@total_count,
			@error_count,
			{{ threshold }},
			@error_percentage,
			@result_status
		);


	--============================================
	-- INSERT INTO ERROR LOG DETAIL WHEN Fail 
	--============================================

		IF @result_status = 'FAIL'
		BEGIN

			INSERT INTO NonDelegatedClaims.dbo.DBT_NDC_Validation_Failure_Detail
			(HealthPlan ,ProcessID, ModelName, TestCategory, TestName, [NCH_RecordID],[ClaimNumber],[ClaimLine],[MemberID],[DOSFrom],[PaidDate],[ClaimStatus] ,[LineOfBusiness] ,[ServiceCode] ,[ServicePaidAmount],[PrimaryDiagCode],[SecondaryDiagCode])
			SELECT
				'{{ var("healthplan") }}',
				'{{ var("processid") }}',
				'{{ model.name }}',
				'reference_table_check',
				'{{ test_name }}',
				[NCH_RecordID],
				[ClaimNumber],
				[ClaimLine],
				[MemberID],
				[DOSFrom],
				[PaidDate],
				[ClaimStatus] ,
				[LineOfBusiness],
				[ServiceCode],
				[ServicePaidAmount],
				[PrimaryDiagCode],
				[SecondaryDiagCode]
			from {{ model }}
			WHERE     (
								{% for col_expr in source_columns %}
								({{ col_expr }} NOT IN (SELECT {{ lookup_column }} FROM {{ lookup_table }}))
								{% if not loop.last %}
								AND
								{% endif %}
								{% endfor %}
					  );

		END

	{% endcall %}

{% endtest %}