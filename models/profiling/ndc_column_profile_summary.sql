{{ config(
    materialized='ephemeral',
    tags=['profiling']
) }}

{% set profile_columns = var('profiling_columns') %}

{{ log_column_profile(
    ref('NDC_FileValidation_SourceData'),
    profile_columns,
    'ColumnProfile'
) }}