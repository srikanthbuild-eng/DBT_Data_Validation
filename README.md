# NDC Data Validation & Profiling Project

This DBT project validates and profiles the `NDC_FileValidation_SourceData` materialized view. It supports two main processes:
1. **Rule-Based Data Validation**
2. **Column-Level Data Profiling**

---

## Core Features

### 1. Rule-Based Data Validation
- Centralized YAML definitions for rules (`NDC_RuleCheck.yml`)
- Custom test macros:
  - `column_null_check`
  - `conditional_value_check`
  - `cross_reference tables_check`
  - `data_integrity_check`
  - `client_specific_rules_check`  

- Test results logged to NonDelegatedClaims DB: `DBT_ndc_validation_summary_log`
- Full `dbt test` support with dynamic parameters (healthplan, process ID)


### 2. Column-Level Data Profiling
- Profiles selected columns using `vars:` in `NDC_ProfilingCheck.yml`
- Logs null %, min/max, distinct count to summary table
- No profiling table is created — macro handles logging directly
- Profiling triggered via ephemeral model `ndc_profile_summary_log.sql`

---

## 📂 Folder Structure Overview

NDC_Data_Validation/
├── dbt_project.yml              # Project configuration file
├── README.md                    # Project documentation (this file)
├── macros/                      # Custom macros and tests
│   ├── column_null_check.sql    # Macro for null value checks
│   ├── conditional_value_check.sql  # Macro for conditional value checks
│   ├── reference_table_check.sql  # Macro for reference table lookups
│   ├── log_profile_to_summary.sql  # Macro for profiling summary logging
│   └── client_specific_duplicate_check.sql  # Test for client-specific duplicate checks
├── models/                      # Models and schema definitions
│   ├── staging/                # Staging models
│   │   └── NDC_FileValidation_SourceData.sql  # Staging model for NDC data (Source Data)
│   ├── validations/            # Validation test definitions
│   │   └── NDC_RuleCheck.yml   # All validation tests (general and client-specific)
│   └── profiling/              # Profiling models
│       └── ndc_profile_summary_log.sql  # Profiling summary model
├── tests/                       # Additional test files (currently empty)
├── logs/                        # DBT logs (auto-generated)
└── target/                      # Compiled SQL and manifests (auto-generated)


---

## How It Works

### Validation
- Rules are defined in `NDC_RuleCheck.yml` under `tests:`.
- Includes null checks, conditional checks, and reference lookups, data integrity checks and client specific rules check.

### Profiling
- Columns to profile are defined under `vars:` in the same YAML.
- Metrics include: null %, min, max, distinct count.

### Summary Log
- Results go to `DBT_NDC_Validation_SummaryLog` in SQL Server under NonDelegatedClaims DB.

---

## Run Commands
```bash
.\powershell.exe -Executionpolicy Bypass -File ".\run_dbt_with_sqlinputs.ps1"  
```

## Future Enhancements

- Alerts for Process Errors
- Dashboard integration (Power BI)
- Server deployment
- Schedule through SQL Agent job

- Separate Client-Specific Rules:
- Move client-specific rules to a new client_specific.yml file with a client_specific tag for better organization and isolation.
- Define model metadata in a schema.yml file to avoid duplicate model definitions.
- Generic Macro: Implement a client_specific_check macro to handle multiple types of client-specific rules (e.g., duplicate checks, value range checks) using check_type parameters.

---


Contributing to the NDC Data Validation DBT Project

### 1. Clone the Repository

```bash
cd C:git clone https://github.com/your-org/your-repo-name.git
cd your-repo-name
```

---

### 2. Open the Project in VS Code

- Option 1: In the terminal, run `code .`
- Option 2: Open VS Code → `File > Open Folder` → select the project folder

---
---

### 3. Install Prerequisites

- **Python 3.10+**
- **DBT for SQL Server**

### 4. Set Up Your DBT Profile

Edit `C:\Users\<YourName>\.dbt\profiles.yml`:

```yaml

## Running the Project

To compile and test the project:

```bash
dbt clean
dbt deps
dbt compile
dbt run
dbt test
```

To run client-specific tests:

```bash
dbt test --select NDC_FileValidation_SourceData --vars "{healthplan: 'MolinaOH', processid: 'PRC123'}"
```
---

## Making Code Changes

- Always create a new branch:
  ```bash
  git checkout main
  git pull

  git checkout -b DBT_NDC_Validation/your_change_desc
  ```

- After changes:
  ```bash
  git add .
  git commit -m "Describe your change"
  git push origin feature/your_change_desc
  ```

Then open a **Pull Request** in GitHub.

---
**Built with**: dbt, Jinja2, SQL Server  
**Maintainer**: Srikanth Reddy