#!/bin/bash

# ====================================================
# Docker 환경 설정 & 실행 스크립트
# ====================================================
# 이 스크립트는 현재 디렉토리(mlops-mlops_2) 내에 독립적인 모니터링 환경
# (Grafana, Prometheus, StatsD)을 설정합니다.

echo "--- [1] 디렉토리 구조 생성 ---"
mkdir -p docker-data/prometheus/config
mkdir -p docker-data/prometheus/data
mkdir -p docker-data/grafana/data
mkdir -p docker-data/grafana/provisioning/datasources
mkdir -p docker-data/grafana/provisioning/dashboards
mkdir -p docker-data/grafana/dashboards
mkdir -p docker-data/statsd

echo "--- [2] 설정 파일 생성 ---"

# 2.0 Grafana 프로비저닝
echo "Grafana 프로비저닝 설정 생성 중..."

# Datasource
cat << 'EOF' > docker-data/grafana/provisioning/datasources/datasource.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    isDefault: true
EOF

# Dashboard Provider
cat << 'EOF' > docker-data/grafana/provisioning/dashboards/dashboard.yml
apiVersion: 1

providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
EOF

# 대시보드 JSON (임베디드)
echo "대시보드 JSON 생성 중..."
cat << 'EOF' > docker-data/grafana/dashboards/model_monitor_dashboard.json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 7,
  "links": [],
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": 0
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "model_monitor_mse",
          "legendFormat": "MSE",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "model_monitor_mae",
          "legendFormat": "MAE",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "Model Error (MSE & MAE)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": 0
              },
              {
                "color": "green",
                "value": 0.8
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 2,
      "options": {
        "minVizHeight": 75,
        "minVizWidth": 75,
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true,
        "sizing": "auto"
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "model_monitor_r2",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "R2 Score",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": 0
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 8
      },
      "id": 3,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "model_drift_ks",
          "legendFormat": "KS Statistic - {{feature}}",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "model_drift_wasserstein",
          "legendFormat": "Wasserstein Dist - {{feature}}",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "Data Drift (KS & Wasserstein)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "Seconds",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": 0
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 8
      },
      "id": 4,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "model_monitor_load_time",
          "legendFormat": "Load Time",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "model_monitor_inference_time",
          "legendFormat": "Inference Time",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "System Latency",
      "type": "timeseries"
    }
  ],
  "preload": false,
  "refresh": "",
  "schemaVersion": 42,
  "tags": [],
  "templating": {
    "list": [
      {
        "current": {
          "text": "prometheus",
          "value": "ff8fnbmpaf0u8d"
        },
        "includeAll": false,
        "label": "Datasource",
        "name": "DS_PROMETHEUS",
        "options": [],
        "query": "prometheus",
        "refresh": 1,
        "regex": "",
        "type": "datasource"
      }
    ]
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Model Monitor Dashboard",
  "uid": "edv923kjs923",
  "version": 1
}
EOF

# 2.1 Prometheus 설정
echo "docker-data/prometheus/config/prometheus.yml 생성 중..."
cat << 'EOF' > docker-data/prometheus/config/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9102']
  - job_name: 'airflow-statsd-exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['airflow-statsd-exporter:9102']
EOF

# 2.2 StatsD 설정
echo "docker-data/statsd/statsd.conf 생성 중..."
cat << 'EOF' > docker-data/statsd/statsd.conf
mappings:
  # Airflow StatsD metrics mappings (https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/metrics.html)
  # === Counters ===
  - match: "(.+)\\.(.+)_start$"
    match_metric_type: counter
    name: "af_agg_job_start"
    match_type: regex
    labels:
      airflow_id: "$1"
      job_name: "$2"
  - match: "(.+)\\.(.+)_end$"
    match_metric_type: counter
    name: "af_agg_job_end"
    match_type: regex
    labels:
      airflow_id: "$1"
      job_name: "$2"
  - match: "(.+)\\.operator_failures_(.+)$"
    match_metric_type: counter
    name: "af_agg_operator_failures"
    match_type: regex
    labels:
      airflow_id: "$1"
      operator_name: "$2"
  - match: "(.+)\\.operator_successes_(.+)$"
    match_metric_type: counter
    name: "af_agg_operator_successes"
    match_type: regex
    labels:
      airflow_id: "$1"
      operator_name: "$2"
  - match: "*.ti_failures"
    match_metric_type: counter
    name: "af_agg_ti_failures"
    labels:
      airflow_id: "$1"
  - match: "*.ti_successes"
    match_metric_type: counter
    name: "af_agg_ti_successes"
    labels:
      airflow_id: "$1"
  - match: "*.zombies_killed"
    match_metric_type: counter
    name: "af_agg_zombies_killed"
    labels:
      airflow_id: "$1"
  - match: "*.scheduler_heartbeat"
    match_metric_type: counter
    name: "af_agg_scheduler_heartbeat"
    labels:
      airflow_id: "$1"
  - match: "*.dag_processing.processes"
    match_metric_type: counter
    name: "af_agg_dag_processing_processes"
    labels:
      airflow_id: "$1"
  - match: "*.scheduler.tasks.killed_externally"
    match_metric_type: counter
    name: "af_agg_scheduler_tasks_killed_externally"
    labels:
      airflow_id: "$1"
  - match: "*.scheduler.tasks.running"
    match_metric_type: counter
    name: "af_agg_scheduler_tasks_running"
    labels:
      airflow_id: "$1"
  - match: "*.scheduler.tasks.starving"
    match_metric_type: counter
    name: "af_agg_scheduler_tasks_starving"
    labels:
      airflow_id: "$1"
  - match: "*.scheduler.orphaned_tasks.cleared"
    match_metric_type: counter
    name: "af_agg_scheduler_orphaned_tasks_cleared"
    labels:
      airflow_id: "$1"
  - match: "*.scheduler.orphaned_tasks.adopted"
    match_metric_type: counter
    name: "af_agg_scheduler_orphaned_tasks_adopted"
    labels:
      airflow_id: "$1"
  - match: "*.scheduler.critical_section_busy"
    match_metric_type: counter
    name: "af_agg_scheduler_critical_section_busy"
    labels:
      airflow_id: "$1"
  - match: "*.sla_email_notification_failure"
    match_metric_type: counter
    name: "af_agg_sla_email_notification_failure"
    labels:
      airflow_id: "$1"
  - match: "*.ti.start.*.*"
    match_metric_type: counter
    name: "af_agg_ti_start"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
      task_id: "$3"
  - match: "*.ti.finish.*.*.*"
    match_metric_type: counter
    name: "af_agg_ti_finish"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
      task_id: "$3"
      state: "$4"
  - match: "*.dag.callback_exceptions"
    match_metric_type: counter
    name: "af_agg_dag_callback_exceptions"
    labels:
      airflow_id: "$1"
  - match: "*.celery.task_timeout_error"
    match_metric_type: counter
    name: "af_agg_celery_task_timeout_error"
    labels:
      airflow_id: "$1"

  # === Gauges ===
  - match: "*.dagbag_size"
    match_metric_type: gauge
    name: "af_agg_dagbag_size"
    labels:
      airflow_id: "$1"
  - match: "*.dag_processing.import_errors"
    match_metric_type: gauge
    name: "af_agg_dag_processing_import_errors"
    labels:
      airflow_id: "$1"
  - match: "*.dag_processing.total_parse_time"
    match_metric_type: gauge
    name: "af_agg_dag_processing_total_parse_time"
    labels:
      airflow_id: "$1"
  - match: "*.dag_processing.last_runtime.*"
    match_metric_type: gauge
    name: "af_agg_dag_processing_last_runtime"
    labels:
      airflow_id: "$1"
      dag_file: "$2"
  - match: "*.dag_processing.last_run.seconds_ago.*"
    match_metric_type: gauge
    name: "af_agg_dag_processing_last_run_seconds"
    labels:
      airflow_id: "$1"
      dag_file: "$2"
  - match: "*.dag_processing.processor_timeouts"
    match_metric_type: gauge
    name: "af_agg_dag_processing_processor_timeouts"
    labels:
      airflow_id: "$1"
  - match: "*.executor.open_slots"
    match_metric_type: gauge
    name: "af_agg_executor_open_slots"
    labels:
      airflow_id: "$1"
  - match: "*.executor.queued_tasks"
    match_metric_type: gauge
    name: "af_agg_executor_queued_tasks"
    labels:
      airflow_id: "$1"
  - match: "*.executor.running_tasks"
    match_metric_type: gauge
    name: "af_agg_executor_running_tasks"
    labels:
      airflow_id: "$1"
  - match: "*.pool.open_slots.*"
    match_metric_type: gauge
    name: "af_agg_pool_open_slots"
    labels:
      airflow_id: "$1"
      pool_name: "$2"
  - match: "*.pool.queued_slots.*"
    match_metric_type: gauge
    name: "af_agg_pool_queued_slots"
    labels:
      airflow_id: "$1"
      pool_name: "$2"
  - match: "*.pool.running_slots.*"
    match_metric_type: gauge
    name: "af_agg_pool_running_slots"
    labels:
      airflow_id: "$1"
      pool_name: "$2"
  - match: "*.pool.starving_tasks.*"
    match_metric_type: gauge
    name: "af_agg_pool_starving_tasks"
    labels:
      airflow_id: "$1"
      pool_name: "$2"
  - match: "*.smart_sensor_operator.poked_tasks"
    match_metric_type: gauge
    name: "af_agg_smart_sensor_operator_poked_tasks"
    labels:
      airflow_id: "$1"
  - match: "*.smart_sensor_operator.poked_success"
    match_metric_type: gauge
    name: "af_agg_smart_sensor_operator_poked_success"
    labels:
      airflow_id: "$1"
  - match: "*.smart_sensor_operator.poked_exception"
    match_metric_type: gauge
    name: "af_agg_smart_sensor_operator_poked_exception"
    labels:
      airflow_id: "$1"
  - match: "*.smart_sensor_operator.exception_failures"
    match_metric_type: gauge
    name: "af_agg_smart_sensor_operator_exception_failures"
    labels:
      airflow_id: "$1"
  - match: "*.smart_sensor_operator.infra_failures"
    match_metric_type: gauge
    name: "af_agg_smart_sensor_operator_infra_failures"
    labels:
      airflow_id: "$1"

  # === Timers ===
  - match: "*.dagrun.dependency-check.*"
    match_metric_type: observer
    name: "af_agg_dagrun_dependency_check"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
  - match: "*.dag.*.*.duration"
    match_metric_type: observer
    name: "af_agg_dag_task_duration"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
      task_id: "$3"
  - match: "*.dag_processing.last_duration.*"
    match_metric_type: observer
    name: "af_agg_dag_processing_duration"
    labels:
      airflow_id: "$1"
      dag_file: "$2"
  - match: "*.dagrun.duration.success.*"
    match_metric_type: observer
    name: "af_agg_dagrun_duration_success"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
  - match: "*.dagrun.duration.failed.*"
    match_metric_type: observer
    name: "af_agg_dagrun_duration_failed"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
  - match: "*.dagrun.schedule_delay.*"
    match_metric_type: observer
    name: "af_agg_dagrun_schedule_delay"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
  - match: "*.scheduler.critical_section_duration"
    match_metric_type: observer
    name: "af_agg_scheduler_critical_section_duration"
    labels:
      airflow_id: "$1"
  - match: "*.dagrun.*.first_task_scheduling_delay"
    match_metric_type: observer
    name: "af_agg_dagrun_first_task_scheduling_delay"
    labels:
      airflow_id: "$1"
      dag_id: "$2"
  # === Model Monitoring ===
  - match: "model.monitor.mse"
    match_metric_type: gauge
    name: "model_monitor_mse"
  - match: "model.monitor.mae"
    match_metric_type: gauge
    name: "model_monitor_mae"
  - match: "model.monitor.r2"
    match_metric_type: gauge
    name: "model_monitor_r2"
  - match: "model.monitor.inference_time"
    match_metric_type: observer
    name: "model_monitor_inference_time"
  - match: "model.monitor.load_time"
    match_metric_type: observer
    name: "model_monitor_load_time"

  # === Drift ===
  - match: "model\\.drift\\.ks\\.(.+)"
    match_metric_type: gauge
    name: "model_drift_ks"
    match_type: regex
    labels:
      feature: "$1"
  - match: "model\\.drift\\.wasserstein\\.(.+)"
    match_metric_type: gauge
    name: "model_drift_wasserstein"
    match_type: regex
    labels:
      feature: "$1"
EOF

echo "--- [3] docker-compose.yml 생성 ---"
cat << 'EOF' > docker-compose.yml
version: '3.8'

x-environment: &airflow_common_env
  AIRFLOW__METRICS__STATSD__ON: "True"
  AIRFLOW__METRICS__STATSD__HOST: airflow-statsd-exporter
  AIRFLOW__METRICS__STATSD__PORT: "8125"
  AIRFLOW__CORE__EXECUTOR: "CeleryExecutor"
  AIRFLOW__METRICS__STATSD__PREFIX: "airflow"

services:
  grafana:
    image: grafana/grafana
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:3000" ]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    ports:
      - "3000:3000"
    volumes:
      - './docker-data/grafana/data:/var/lib/grafana'
      - './docker-data/grafana/provisioning:/etc/grafana/provisioning'
      - './docker-data/grafana/dashboards:/var/lib/grafana/dashboards'
    restart: always
  prometheus:
    image: prom/prometheus:latest
    command:
      - '--web.enable-lifecycle'
      - '--config.file=/etc/prometheus/prometheus.yml'
    healthcheck:
      test: [ "CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9090/-/healthy" ]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 5s
    ports:
      - "9090:9090"
    volumes:
      - ./docker-data/prometheus/config:/etc/prometheus
      - ./docker-data/prometheus/data:/prometheus
    restart: always
  airflow-statsd-exporter:
    image: prom/statsd-exporter
    command: "--statsd.listen-udp=:8125 --web.listen-address=:9102 --statsd.mapping-config=/etc/statsd/statsd.conf"
    ports:
      - "8125:8125/udp"
      - "9102:9102"
    volumes:
      - ./docker-data/statsd/statsd.conf:/etc/statsd/statsd.conf
    restart: always

  mlops-pipeline:
    build: .
    image: tmdb-pipeline:latest
    container_name: mlops-pipeline
    env_file:
      - .env
    environment:
      <<: *airflow_common_env
      PYTHONUNBUFFERED: 1
    volumes:
      - ./:/app
    depends_on:
      - airflow-statsd-exporter
      - prometheus

volumes:
  grafana_data:
EOF


echo "--- [4] Docker 컨테이너 시작 ---"
docker-compose up -d

echo "--- 설정 완료! ---"
echo "Grafana: http://localhost:3000"
echo "Prometheus: http://localhost:9090"
echo "StatsD Exporter metrics: http://localhost:9102/metrics"
