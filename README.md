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

## AI & ML System: Models, Fraud Defense & Anti-Spoofing Strategy

The system architecture decouples complex machine learning tasks into specialized microservices, ensuring high scalability, low latency, and strict interpretability for auditing purposes. The fraud defense layer is a direct extension of this architecture — treating GPS as **one signal among many**, not as the ultimate ground truth.

### ML Module Overview

| Module | AI/ML Model | Function & Integration |
| :--- | :--- | :--- |
| **Premium Calculation** | CatBoost + SHAP | Dynamically calculates the weekly premium based on historical weather, zone, and platform data. SHAP ensures model explainability. |
| **Active Shift Validation** | Logistic Regression | Evaluates the partner's "Propensity to Work" based on rolling 3-week login habits, ensuring payouts are only distributed for actual planned income loss. |
| **Parametric Trigger** | Rule-Based Logic | Deterministic disruption detection. Subscribes to a message broker (Redis/Kafka) to execute triggers instantly upon receiving severe API alerts. |
| **Fraud Detection** | Isolation Forest | Identifies anomalous operational behavior (GPS spoofing, impossible travel velocities) operating in parallel with a strict heuristic rule layer to prevent duplicate claims. |
| **Risk Profiling** | K-Means Clustering | Segments the delivery fleet into structured risk tiers during onboarding to optimize initial pricing and insurer capital allocation. |

### Adversarial Defense: Differentiating Genuine Workers from Spoofers

GPS spoofing by organized syndicates is a known attack vector on parametric platforms. Because weather triggers are objective and automatic, a fraud ring can easily fake their location in an affected zone to drain the liquidity pool. 

The system distinguishes a genuinely stranded delivery partner from a bad actor by comparing **behavioral consistency** across multiple signals, rather than relying on location alone.

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

| Risk Tier | System Action |
| :--- | :--- |
| **Low Risk** | Claim proceeds normally; payout executes immediately. |
| **Medium Risk** | Payout deferred; 30-minute telemetry watch window opens; auto-resolves if signals stabilize. |
| **High Risk** | Enters secondary review with a reason code; partner is notified with a 24-hour window to submit platform activity evidence. |

> **GPS Drop Grace Window:** A partner who loses GPS signal mid-shift due to severe weather is not penalized. Their last valid zone location is cached with a **15-minute grace window**. If the trigger event falls within that window, the claim is treated as zone-confirmed.
> 
> **Core Principle:** False negatives (paying a fraudster) are financially recoverable. False positives (wrongly denying a genuine worker in a crisis) destroy trust and cause permanent churn. The objective is **reliable trust scoring before payout release**, not aggressive denial.

### Anti-Spoofing Decision Flow

```mermaid
graph LR
    %% Theme and Class Definitions
    classDef triggerNode fill:#2d333b,stroke:#8b949e,stroke-width:1px,color:#c9d1d9,rx:15px,ry:15px;
    classDef darkBox fill:#22272e,stroke:#444c56,stroke-width:1px,color:#adbac7;
    classDef decisionBox fill:#22272e,shape:diamond,stroke:#444c56,stroke-width:1px,color:#adbac7;
    classDef successNode fill:#238636,stroke:#none,color:#ffffff,rx:15px,ry:15px;
    classDef graceNode fill:#22272e,stroke:#8b949e,stroke-dasharray: 5 5,color:#adbac7,rx:15px,ry:15px;
    classDef humanNode fill:#1f6feb,stroke:#none,color:#ffffff,rx:15px,ry:15px;

    %% Independent Triggers
    WEATHER([Weather trigger<br/>Threshold crossed]):::triggerNode
    GRACE([GPS drop grace<br/>Last zone cached · 15 min]):::graceNode

    %% Subgraph: Signal Harvest
    subgraph HARVEST [Signal Harvest]
        B[GPS + trajectory<br/>continuity]:::darkBox
        C[Accelerometer<br/>& cell tower]:::darkBox
        D[App foreground<br/>& battery state]:::darkBox
        E[Platform order<br/>acceptance history]:::darkBox
    end

    %% Subgraph: Cluster Check
    subgraph CLUSTER [Cluster Check]
        H[Zone velocity<br/>200+ claims / 5 min]:::darkBox
        I[Device fingerprint<br/>duplication]:::darkBox
        J{Syndicate<br/>flag?}:::decisionBox
    end

    %% Subgraph: Isolation Forest
    subgraph MODEL [Isolation Forest]
        F[Combined<br/>feature vector]:::darkBox
        G{Anomaly<br/>score?}:::decisionBox
    end

    %% Subgraph: Soft Hold
    subgraph HOLD_BLOCK [Soft Hold]
        HOLD[Notify partner<br/>2-hr SLA]:::darkBox
        WATCH{30-min telemetry<br/>consistent?}:::decisionBox
    end

    %% Subgraph: Manual Review
    subgraph REVIEW_BLOCK [Manual Review]
        REV[Reason code assigned]:::darkBox
        EVID[Partner submits<br/>24-hr evidence window]:::darkBox
        ANALYST([Human analyst decision]):::humanNode
    end

    %% Payout Nodes
    PAY1([✓ Instant UPI payout]):::successNode
    PAY2([✓ Auto-resolve payout]):::successNode

    %% Logic Connections
    WEATHER --> B & C & D & E
    H & I --> J
    
    J -- No --> F
    J -- Yes --> REV

    B & C & D & E --> F
    GRACE -. feeds .-> F

    F --> G

    G -- Low --> PAY1
    G -- Medium --> HOLD
    G -- High --> REV

    HOLD --> WATCH
    WATCH -- Yes --> PAY2
    WATCH -- No --> REV

    REV --> EVID --> ANALYST

    %% Subgraph Styling for Pastel Backgrounds
    style HARVEST fill:#e6f4ea,stroke:#1e8e3e,stroke-width:2px,color:#0b5323
    style CLUSTER fill:#fef7e0,stroke:#f9ab00,stroke-width:2px,color:#5c3e00
    style MODEL fill:#f3f0ff,stroke:#7f77dd,stroke-width:2px,color:#26215c
    style HOLD_BLOCK fill:#fef7e0,stroke:#f9ab00,stroke-width:2px,color:#5c3e00
    style REVIEW_BLOCK fill:#fce8e6,stroke:#d93025,stroke-width:2px,color:#7a1a10
