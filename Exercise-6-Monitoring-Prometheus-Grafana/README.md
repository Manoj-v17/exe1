# Exercise 6: Real-Time Operations Monitoring and Alerting (Quick-Commerce App)

## Objective

The objective of this exercise is to:

- Design and deploy an end-to-end **observability and monitoring pipeline** for a fast-paced quick-commerce delivery platform (**ZAPPTTO**).
- Instrument a Python microservice with the **Prometheus Client Library** (`prometheus_client`) using `Gauge` and `Summary` metrics.
- Configure **Prometheus** to scrape metrics dynamically and evaluate rule-based alerts (`alert_rules.yml`).
- Deploy **Grafana** to visualize operational KPIs through real-time dashboards.
- Automate stack deployment via a declarative **Jenkins Pipeline** (`Jenkinsfile`).

---

## Scenario & Monitoring Architecture

In quick-commerce (like Blinkit, Zepto, or Instamart), delivery promises require **sub-15 minute turnaround times**:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     ZAPPTTO Monitoring Stack                        │
│                                                                     │
│  ┌──────────────────┐    scrape      ┌──────────────────┐          │
│  │  delivery_metrics│ ──/metrics──►  │    Prometheus    │          │
│  │  (port 8000)     │   every 5s     │    (port 9090)   │          │
│  │                  │                │                  │          │
│  │  Gauges:         │                │  alert_rules.yml │          │
│  │  • total_del     │                │  • HighPending   │          │
│  │  • pending_del   │                │  • HighAvgTime   │          │
│  │  • onway_del     │                └────────┬─────────┘          │
│  │  Summary:        │                         │ query               │
│  │  • avg_del_time  │                         ▼                    │
│  └──────────────────┘                ┌──────────────────┐          │
│                                      │     Grafana      │          │
│  ┌──────────────────┐                │    (port 3000)   │          │
│  │     Jenkins      │ build/deploy   │  Real-time KPI   │          │
│  │   CI/CD Pipeline │──────────────► │    Dashboards    │          │
│  └──────────────────┘                └──────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

| Component              | Role                                                        | Port  |
|------------------------|-------------------------------------------------------------|-------|
| `delivery_metrics.py`  | Metrics publisher — exposes Prometheus `/metrics` endpoint  | 8000  |
| Prometheus             | Scrapes, stores time-series, fires alerts                   | 9090  |
| Grafana                | Visualizes Prometheus data in dashboards                    | 3000  |
| Jenkins                | CI/CD pipeline — builds, runs, and deploys all containers   | 8080  |

---

## Environment Setup

| Component          | Details                            |
|--------------------|------------------------------------|
| Host OS            | macOS (Apple Silicon arm64)        |
| Container Runtime  | Docker Desktop 29.7.2              |
| Metrics Framework  | Prometheus + Grafana               |
| Language Stack     | Python 3.11, prometheus_client     |
| CI/CD              | Jenkins (Declarative Pipeline)     |

---

## Project Files

| File                   | Description                                                              |
|------------------------|--------------------------------------------------------------------------|
| `delivery_metrics.py`  | Prometheus-instrumented microservice simulating delivery KPIs            |
| `Dockerfile`           | Python 3.11-slim image exposing port 8000                                |
| `prometheus.yml`       | Prometheus scrape config targeting delivery service and alert rules      |
| `alert_rules.yml`      | Alert rules for high pending deliveries and high average delivery time   |
| `Jenkinsfile`          | Declarative CI/CD pipeline automating build and deployment               |

---

## Step-by-Step Execution & Output

### Step 1: Start Delivery Simulation Microservice

```bash
docker build -t delivery_metrics .
docker run -d --name delivery_metrics -p 8000:8000 delivery_metrics
```

**Output:**
```
[INFO] Starting the HTTP server on port 8000...
[INFO] HTTP server started. Simulating deliveries...
[DEBUG] Total deliveries: 89
[DEBUG] Pending deliveries: 17
[DEBUG] On-the-way deliveries: 19
[DEBUG] Average delivery time: 31.45 seconds
```

---

### Step 2: Scrape Metrics via HTTP

```bash
curl http://localhost:8000/metrics | grep -E "deliveries" -A 2
```

**Output:**
```
# HELP total_deliveries Total number of deliveries
# TYPE total_deliveries gauge
total_deliveries 94.0

# HELP pending_deliveries Number of pending deliveries
# TYPE pending_deliveries gauge
pending_deliveries 22.0

# HELP on_the_way_deliveries Number of deliveries on the way
# TYPE on_the_way_deliveries gauge
on_the_way_deliveries 16.0
```

---

### Step 3: Run Prometheus and Grafana

```bash
docker run -d --name prometheus -p 9090:9090 --add-host=host.docker.internal:host-gateway \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $(pwd)/alert_rules.yml:/etc/prometheus/alert_rules.yml prom/prometheus

docker run -d --name grafana -p 3000:3000 grafana/grafana
```

**Verify running stack:**
```bash
docker ps --filter "name=delivery_metrics|prometheus|grafana"
```

**Output:**
```
CONTAINER ID   IMAGE              STATUS         PORTS                    NAMES
93af4ca21fc2   delivery_metrics   Up 4 minutes   0.0.0.0:8000->8000/tcp   delivery_metrics
f92c85d7462b   prom/prometheus    Up 3 minutes   0.0.0.0:9090->9090/tcp   prometheus
2ed558c5ce15   grafana/grafana    Up 2 minutes   0.0.0.0:3000->3000/tcp   grafana
```

---

### Step 4: Query Prometheus API & Verify Firing Alerts

```bash
curl -s "http://localhost:9090/api/v1/query?query=pending_deliveries"
```

**Output:**
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {"job": "delivery_service"},
        "value": [1791566093, "22"]
      }
    ]
  }
}
```

> **Observation:** Because `pending_deliveries = 22` (> 10 threshold), the alert rule `HighPendingDeliveries` in `alert_rules.yml` transitions to **FIRING** state after 15 seconds.

---

## Alert Rules Breakdown

| Alert Name                | Expression                                                      | Threshold | Severity |
|---------------------------|-----------------------------------------------------------------|-----------|----------|
| `HighPendingDeliveries`   | `pending_deliveries > 10`                                       | 15s `for` | warning  |
| `HighAverageDeliveryTime` | `(average_delivery_time_sum / average_delivery_time_count) > 30`| immediate | critical |

---

## Technical Summary & Learnings

### Prometheus Metric Types

| Type        | Behaviour                                    | Example in this Lab                    |
|-------------|----------------------------------------------|----------------------------------------|
| **Counter** | Monotonically increasing, never decreases    | Total completed orders (lifetime)      |
| **Gauge**   | Can go up or down freely                     | `pending_deliveries`, `on_the_way_deliveries` |
| **Summary** | Samples observations, calculates quantiles   | `average_delivery_time` (latency/duration) |
| **Histogram**| Buckets observations into configurable ranges| Request latency percentiles (p50, p95, p99) |

### Key Architectural Concepts

- **Pull vs. Push Model:** Prometheus uses a **pull model** — it periodically scrapes `/metrics` from configured endpoints (`scrape_configs`). This decouples the app from the monitoring system.
- **`for:` clause in alerts:** Prevents transient spikes from causing alert fatigue. The condition must persist for the specified duration before transitioning `PENDING → FIRING`.
- **`host.docker.internal`:** Special DNS name allowing containers to reach services running on the host machine (used to scrape the delivery_metrics container from Prometheus).
- **Grafana Data Source:** Grafana connects to Prometheus at `http://localhost:9090` and renders panels using PromQL queries.

---

## Lab Q&A Summary

### Q1. What is the purpose of the `Gauge` metric type in this exercise?
**A:** `Gauge` represents a metric that can **arbitrarily increase or decrease**. It's perfect for operational states like `pending_deliveries` (orders waiting dispatch) or `on_the_way_deliveries` (active orders), which fluctuate in real time as orders are created, dispatched, and delivered.

### Q2. Why use a `Summary` for `average_delivery_time` instead of a `Gauge`?
**A:** `Summary` tracks both a **count** and **sum** of observed values, enabling Prometheus to compute the actual average via `_sum / _count`. It also exposes configurable quantiles (e.g., p50, p90, p99), giving a statistical distribution of delivery times rather than just a single point-in-time value.

### Q3. How does the `for: 15s` clause in alert rules prevent alert fatigue?
**A:** The `for: 15s` clause requires the alert condition to be **continuously true** for 15 seconds before transitioning from `PENDING` to `FIRING`. This filters out brief transient spikes (e.g., a momentary burst of pending orders) that would self-resolve, ensuring only sustained threshold breaches trigger notifications.

### Q4. What is the role of `host.docker.internal` in `prometheus.yml`?
**A:** `host.docker.internal` is a special DNS name that Docker resolves to the **host machine's IP address** from within a container. Since `delivery_metrics` runs on the host (or another container) at port 8000, Prometheus uses this hostname to reach the metrics endpoint without hardcoding an IP address.

### Q5. How does Jenkins automate the monitoring stack deployment?
**A:** The `Jenkinsfile` defines a **Declarative Pipeline** with sequential stages:
1. **Pre-check Docker** — validates Docker availability.
2. **Build Docker Image** — builds the `delivery_metrics` image.
3. **Run Application** — starts the metrics publisher container.
4. **Run Prometheus & Grafana** — starts the full observability stack with config volume mounts.

This ensures every deployment is reproducible, version-controlled, and automated.
