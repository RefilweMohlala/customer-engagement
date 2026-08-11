CREATE TABLE customers (
    customer_id         SERIAL PRIMARY KEY,
    full_name           VARCHAR(150) NOT NULL,
    phone_whatsapp       VARCHAR(20) NOT NULL UNIQUE,
    email                VARCHAR(150),
    lifecycle_stage      VARCHAR(30) NOT NULL DEFAULT 'active'
                            CHECK (lifecycle_stage IN ('onboarding','active','at_risk','churned','reactivated')),
    whatsapp_opt_in      BOOLEAN NOT NULL DEFAULT FALSE,
    opt_in_date          TIMESTAMPTZ,
    opt_out_date         TIMESTAMPTZ,
    consent_source       VARCHAR(50),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_customers_lifecycle_stage ON customers(lifecycle_stage);
CREATE INDEX idx_customers_opt_in ON customers(whatsapp_opt_in);

CREATE TABLE interaction_history (
    interaction_id       SERIAL PRIMARY KEY,
    customer_id           INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    interaction_type      VARCHAR(30) NOT NULL
                            CHECK (interaction_type IN ('support_ticket','whatsapp_reply','call_note','email','manual_note')),
    summary                TEXT NOT NULL,
    sentiment_score        NUMERIC(4,3) CHECK (sentiment_score BETWEEN -1 AND 1),
    sentiment_source       VARCHAR(20) DEFAULT 'ollama_local'
                            CHECK (sentiment_source IN ('ollama_local','manual','system')),
    occurred_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_interaction_customer ON interaction_history(customer_id);
CREATE INDEX idx_interaction_occurred_at ON interaction_history(occurred_at DESC);

CREATE TABLE engagement_scores (
    customer_id            INTEGER PRIMARY KEY REFERENCES customers(customer_id) ON DELETE CASCADE,
    recency_score            NUMERIC(5,2) NOT NULL DEFAULT 0,
    sentiment_trend_score    NUMERIC(5,2) NOT NULL DEFAULT 0,
    outreach_gap_score       NUMERIC(5,2) NOT NULL DEFAULT 0,
    composite_score           NUMERIC(5,2) NOT NULL DEFAULT 0,
    risk_tier                  VARCHAR(20) NOT NULL DEFAULT 'healthy'
                                CHECK (risk_tier IN ('healthy','at_risk','critical')),
    last_scored_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_engagement_risk_tier ON engagement_scores(risk_tier);

CREATE TABLE engagement_score_history (
    history_id            SERIAL PRIMARY KEY,
    customer_id             INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    composite_score          NUMERIC(5,2) NOT NULL,
    risk_tier                 VARCHAR(20) NOT NULL,
    scored_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_score_history_customer ON engagement_score_history(customer_id, scored_at DESC);

CREATE TABLE message_log (
    message_id             SERIAL PRIMARY KEY,
    customer_id              INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    message_body               TEXT NOT NULL,
    tone                        VARCHAR(30),
    trigger_risk_tier            VARCHAR(20),
    approval_status               VARCHAR(20) NOT NULL DEFAULT 'auto_approved'
                                    CHECK (approval_status IN ('auto_approved','pending_human_review','human_approved','human_rejected')),
    reviewed_by                     VARCHAR(100),
    whatsapp_message_id              VARCHAR(100),
    delivery_status                   VARCHAR(20) DEFAULT 'pending'
                                        CHECK (delivery_status IN ('pending','sent','delivered','read','failed','skipped_no_consent','skipped_rate_limited')),
    customer_responded                 BOOLEAN DEFAULT FALSE,
    sent_at                              TIMESTAMPTZ,
    created_at                             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_message_log_customer ON message_log(customer_id);
CREATE INDEX idx_message_log_status ON message_log(delivery_status);
CREATE INDEX idx_message_log_created_at ON message_log(created_at DESC);
CREATE INDEX idx_message_log_customer_sent_at ON message_log(customer_id, sent_at DESC);