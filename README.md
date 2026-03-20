<div align="center">
  <img src="logo.png" alt="CashUrance Logo" width="200"/>
  
  <h1>CashUrance: AI-Powered Income Protection for Delivery Partners</h1>
  <p><b>Developed by Team D.E.V (Deploy - Execute - Vanish)</b></p>
</div>

> **Guidewire DEVTrails 2026 - Phase 1 Submission** &nbsp;|&nbsp; **Theme:** Ideate & Know Your Delivery Worker

**CashUrance** is an AI-enabled, event-driven parametric insurance platform designed exclusively for India's food and Q-commerce delivery partners (e.g., Zomato, Swiggy, Zepto). It provides a robust financial safety net against uncontrollable external disruptions, ensuring that when extreme weather halts deliveries, income stability is maintained.

---

## The Problem & Target Persona

* **Target Persona:** Food & Q-Commerce Delivery Partners.
* **The Vulnerability:** The delivery ecosystem is highly sensitive to sudden environmental disruptions such as severe waterlogging or extreme heatwaves. While consumer order demand often spikes during these events, the physical inability of partners to deliver safely results in a complete loss of their daily wages.
* **Coverage Scope:** Strictly limited to **Loss of Income**. This platform explicitly excludes coverage for health, life, accidents, or vehicle repairs, adhering to the core parametric constraint.

---

## Core Strategy & Operational Workflow

Our solution transitions from traditional, manual claims processing to real-time, data-driven automation utilizing an **Event-Driven Architecture**.

1. **Onboarding & Risk Profiling (Sunday):** A delivery partner registers on the platform. The system evaluates their primary operating zone and assigns a baseline risk tier utilizing clustering algorithms.
2. **Dynamic Premium Calculation (Sunday Night):** The predictive engine evaluates the 7-day weather forecast for the specific operating zone. It calculates a dynamically adjusted **Weekly Premium** (e.g., ₹85/week) based on the calculated expected loss. The partner opts in.
3. **The Disruption (Wednesday 3:00 PM):** A severe weather event occurs. The integrated meteorological API triggers a real-time alert for conditions crossing our established parametric threshold (e.g., rainfall >65mm).
4. **Validation & Payout (Wednesday 3:05 PM):** The system verifies the partner's "propensity to work" to confirm actual income loss and executes a rapid fraud detection protocol. Validated claims result in an automated, instant payout for lost hours via UPI.

---

## Platform Architecture: Mobile-First Approach

**CashUrance** is developed as a native **Mobile Application**.

Delivery partners operate entirely via their mobile devices. A web-based platform introduces unnecessary operational friction. A mobile-first architecture enables:
* Background location validation for robust fraud detection.
* Instant push notifications for impending environmental alerts.
* Seamless UPI API integration for one-click weekly premium payments and instant claim disbursements.

---

## AI & ML System: Models and Microservices

The system architecture decouples complex machine learning tasks into specialized microservices, ensuring high scalability, low latency, and strict interpretability for auditing purposes. 

### ML Module Overview

| Module | AI/ML Model | Function & Integration |
| :--- | :--- | :--- |
| **Premium Calculation** | CatBoost + SHAP | Dynamically calculates the weekly premium based on historical weather, zone, and platform data. SHAP ensures model explainability. |
| **Active Shift Validation** | Logistic Regression | Evaluates the partner's "Propensity to Work" based on rolling 3-week login habits, ensuring payouts are only distributed for actual planned income loss. |
| **Parametric Trigger** | Rule-Based Logic | Deterministic disruption detection. Subscribes to a message broker (Redis/Kafka) to execute triggers instantly upon receiving severe API alerts. |
| **Fraud Detection** | Isolation Forest | Identifies anomalous operational behavior (GPS spoofing, impossible travel velocities) operating in parallel with a strict heuristic rule layer to prevent duplicate claims. |
| **Risk Profiling** | K-Means Clustering | Segments the delivery fleet into structured risk tiers during onboarding to optimize initial pricing and insurer capital allocation. |

---

## Adversarial Defense & Anti-Spoofing Strategy

The fraud defense layer is a direct extension of our AI architecture—treating GPS as **one signal among many**, not as the ultimate ground truth. GPS spoofing by organized syndicates is a known attack vector on parametric platforms. Because weather triggers are objective and automatic, a fraud ring can easily fake their location in an affected zone to drain the liquidity pool. 

The system distinguishes a genuinely stranded delivery partner from a bad actor by comparing **behavioral consistency** across multiple signals.

**A legitimately affected worker typically shows:**
* Recent delivery movement in the zone prior to the trigger.
* A sudden operational halt whose timing aligns exactly with the weather event.
* Realistic location transitions with no impossible velocity jumps.
* A drop in task completion rate correlated with the external disruption.

**A spoofed user typically shows:**
* Abrupt, physically impossible location changes.
* Static device presence with no corresponding delivery behavior.
* Inconsistent movement patterns relative to their own 3-week behavioral baseline.
* Near-zero accelerometer variance (indicating a stationary device at home).

### Multi-Signal Feature Vector

The Isolation Forest microservice scores the following combined feature vector. No single anomalous signal triggers a denial; instead, the model evaluates the aggregate context:

| Signal | What It Detects |
| :--- | :--- |
| **Trip trajectory continuity** | Recent movement before the halt is coherent with the claimed zone. |
| **Timestamp consistency** | Check-in intervals are human-plausible, not systematically scripted. |
| **App foreground activity** | Was the delivery app actively in use at the exact trigger time? |
| **Battery / network fluctuation** | Active outdoor navigation drains battery; spoofed apps at home do not. |
| **Order acceptance history** | Was the partner online and actively accepting Zomato/Swiggy/Zepto orders? |
| **Speed & route plausibility** | Travel velocity falls within the bounds of physical reality. |
| **Accelerometer / Gyroscope** | Stationary device = near-zero variance; weather-stranded partners show micro-jitter. |
| **Cell tower triangulation delta** | Spoofed GPS often heavily mismatches the actual serving cell tower location. |
| **Device fingerprint consistency** | Coordinated rings often reuse emulators or rooted devices with matching fingerprints. |
| **Network type** | Relying on Home Wi-Fi during an outdoor weather event is highly anomalous. |

### Coordinated Fraud Ring Detection

Individual anomaly scoring alone is insufficient against organized rings. A parallel **cluster-level analysis** runs independently to detect:
* Multiple simultaneous claims originating from highly similar or identical coordinates.
* Repeated, identical device behavior patterns across multiple claimants.
* Synchronized inactivity onset immediately after trigger activation.
* Abnormal claim density within small geographic clusters (e.g., *200+ claims / 5 min from one pin code = automatic syndicate flag*).

This prevents a coordinated ring from gaming the system by keeping individual claims just below the anomaly threshold while their aggregate pattern remains highly visible.

### Fair Handling of Flagged Claims

A flagged worker is **never automatically denied**. The tiered hold workflow protects honest workers who might be experiencing genuine network or GPS issues during severe weather:

> **GPS Drop Grace Window:** A partner who loses GPS signal mid-shift due to severe weather is not penalized. Their last valid zone location is cached with a **15-minute grace window**. If the trigger event falls within that window, the claim is treated as zone-confirmed.
> 
> **Core Principle:** False negatives (paying a fraudster) are financially recoverable. False positives (wrongly denying a genuine worker in a crisis) destroy trust and cause permanent churn. The objective is **reliable trust scoring before payout release**, not aggressive denial.

### Anti-Spoofing Decision Pipeline


![Anti-Spoofing Decision Flow](flow1.svg)

**Pipeline Breakdown:**
1. **Trigger & Harvest:** A weather threshold is crossed. The system instantly harvests the multi-signal feature vector (GPS, accelerometer, battery state, order history). *Note: The 15-minute GPS grace cache feeds into this step.*
2. **Syndicate Cluster Check:** The system checks for macro-level anomalies (e.g., 200+ claims in 5 minutes from one zone, or duplicated device fingerprints). 
   * *If flagged:* Routed immediately to Manual Review.
   * *If clean:* Proceeds to the Isolation Forest.
3. **AI Anomaly Scoring:** The Isolation Forest evaluates the combined feature vector and assigns a risk score.
4. **Resolution Routing:**
   * **Low Risk:** Automatically approved. **Instant UPI Payout** executed.
   * **Medium Risk (Soft Hold):** Payout deferred. Partner receives a 2-hour SLA notification while a 30-minute telemetry watch window opens. If signals stabilize and verify, it results in an **Auto-resolve payout**. If not, it moves to Manual Review.
   * **High Risk:** Automatically routed to Manual Review. A reason code is assigned, and the partner has a 24-hour window to submit evidence (e.g., platform screenshots). A human analyst makes the final decision.

---

## Technical Stack

* **UI/UX Interface:** Figma
* **Client Application:** React Native (Cross-platform mobile application)
* **Backend API Gateway:** Node.js / Express
* **AI/ML Microservices:** Python (FastAPI, Scikit-learn, CatBoost)
* **Event Routing:** Redis Pub/Sub (Asynchronous processing for weather triggers)
* **Database Infrastructure:** PostgreSQL (Relational user & policy data) + MongoDB (Raw API telemetry & location data)
* **External Integrations:** OpenWeather API (Mocked), Razorpay/Stripe Test Environment (Payouts)

---

## Development Roadmap (6-Week Timeline)

* **Phase 1 (Weeks 1-2): Ideation & Foundation**
  * Finalize persona constraints and exact parametric triggers.
  * Design high-fidelity UI/UX wireframes.
  * Document system architecture and ML pipelines.
* **Phase 2 (Weeks 3-4): Automation & Protection**
  * Develop the mobile client (Registration & Weekly Policy Management).
  * Train and deploy the CatBoost predictive premium service.
  * Integrate mock APIs and deploy the Rule-Based Parametric Trigger.
* **Phase 3 (Weeks 5-6): Scale & Optimize**
  * Implement the Isolation Forest Fraud Detection microservice.
  * Integrate mock UPI payment gateways for end-to-end payout simulation.
  * Develop the Insurer Analytics Dashboard for administrative oversight.

---

## Phase 1 Deliverables

* **GitHub Repository:** [Link to this Repo](#)
* **Strategy & Prototype Pitch Video (2-mins):** [Insert YouTube/Drive Link Here](#)

---

<div align="center">
  <i>Deploy - Execute - Vanish</i><br>
  <b>Team D.E.V</b>
</div>
