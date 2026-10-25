# Taxi Forecasting

Python application for two NYC taxi prediction tasks:

- **Demand:** pickup count for one pickup zone and hour.
- **Fare:** `fare_amount` for one trip, not the full passenger bill.

The repository includes data processing, XGBoost/LightGBM training, MLflow
tracking, FastAPI serving, recursive batch forecasts, SHAP explanations,
subgroup evaluation, drift detection, a Streamlit dashboard, and optional AWS
infrastructure templates. It contains no datasets or trained model bundles.

## Golden Path (clean start to working system)

Prerequisites: Python 3.11 and Git. Optional for the cloud part: AWS CLI, Terraform and Docker.

```powershell
# 1. Environment and checks
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m ruff check .
.\.venv\Scripts\python.exe -m pytest

# 2. Data pipeline (January 2024 yellow taxi data)
.\.venv\Scripts\python.exe -m scripts.run_pipeline --year 2024 --month 1

# 3. Train, tune (25 Optuna trials) and register both models
.\.venv\Scripts\python.exe -m scripts.train_models --n-trials 25

# 4. Serve the API, then check http://127.0.0.1:8000/health
.\.venv\Scripts\python.exe -m uvicorn src.serving.api:app --host 127.0.0.1 --port 8000

# 5. Batch forecast, responsible AI analysis, drift report
.\.venv\Scripts\python.exe -m scripts.batch_forecast --horizon 3
.\.venv\Scripts\python.exe -m scripts.responsible.run_analysis
.\.venv\Scripts\python.exe -m scripts.monitoring.demo_drift_report --problem all --mode drift

# 6. Dashboard
.\.venv\Scripts\python.exe -m pip install -r requirements-dashboard.txt
$env:API_BASE_URL = "http://127.0.0.1:8000"
.\.venv\Scripts\python.exe -m streamlit run dashboard/app.py
```

### One-command run and evidence check

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\golden_path.ps1 -SkipTests
```

Add `-Train` to retrain both models, or `-Verify` to only check the generated evidence. Addto include a live health check.

### AWS deployment (optional)

Terraform in `infra/terraform` creates ECR, ECS Fargate and an ALB. Build the image from `d to ECR as `latest`, then force a new ECS deployment. The drift demo is synthetic, and themanaged monitoring stack is not deployed.

## Start Locally

For the preinstalled Windows course image, follow the
[AWS account and image-access guide](docs/STUDENT_AWS_IMAGE_ACCESS.md) instead of
recreating the environment with the local-install commands below.

Use Python 3.11. From the repository root on Windows PowerShell:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pytest
```

Tests use synthetic data and do not require downloads, models or AWS access.
Follow [setup](docs/SETUP.md) to download data, train registered models, and
start the API and dashboard. Do not expect working predictions immediately
after cloning: serving requires both registered models and saved demand history.

## Documentation

- [Request and launch the Windows course image](docs/STUDENT_AWS_IMAGE_ACCESS.md)
- [Deploy the API to AWS with CodeBuild](docs/STUDENT_AWS_DEPLOYMENT_WALKTHROUGH.md)
- [Local setup and commands](docs/SETUP.md)
- [API request examples](docs/API_EXAMPLES.md)
- [System architecture](docs/ARCHITECTURE.md)
- [Data scope and model limitations](docs/DATA_STATEMENT.md)
- [Optional AWS infrastructure](infra/terraform/README.md)
- [Recording companion and learner activity map](docs/RECORDING_COMPANION.md)
- [Recorded architecture walkthrough](docs/PROJECT_ARCHITECTURE.md)
- [Historical business report](docs/BUSINESS_REPORT.md)
- [Cloud cost boundaries](docs/COST_OPTIMIZATION.md)

The companion links all L2-L12 learner labs; L1 uses setup and tests. Videos are
provided separately. Lab files, reviewed diagrams, and the exploration notebook
retain the paths shown in the recordings. The notebook has no saved outputs.
Datasets, trained models, and evidence reports must be generated locally; AWS
activities require your own authorized configuration or the stated local fallback.

## Layout

| Path | Responsibility |
| --- | --- |
| `src/data/`, `src/features/` | Download, clean, aggregate, engineer features, and split by time |
| `src/models/` | Tune, train, evaluate, explain, and register models |
| `src/serving/`, `clients/python/` | API contracts, inference, batch forecasting, and HTTP client |
| `src/monitoring/`, `src/responsible/` | Drift, performance comparisons, SHAP, and subgroup metrics |
| `scripts/` | Technical command entrypoints |
| `dashboard/` | Streamlit views calling the API and reading local reports |
| `tests/` | Offline unit and integration checks |
| `notebooks/`, `docs/` | Data exploration, learner activities, and technical references |
| `docker/`, `infra/terraform/`, `retraining/` | Optional packaging and cloud operation |

## Operational Boundaries

Docker, Terraform and AWS are optional for local operation. The cloud templates
are not connected to any account, remote repository or existing deployment.
They can create billable resources if you explicitly deploy them with credentials.
No GitHub Actions workflows or automatic release hooks are configured here.

Historical evaluation does not establish current production quality. The default
forecast follows the latest stored history, not the current clock. Model errors,
duration estimation, drift and subgroup disparities require review before using
predictions to make operational or financial decisions.