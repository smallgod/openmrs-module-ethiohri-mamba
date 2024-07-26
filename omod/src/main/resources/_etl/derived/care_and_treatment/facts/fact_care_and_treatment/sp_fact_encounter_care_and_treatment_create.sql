-- $BEGIN
CREATE TABLE IF NOT EXISTS mamba_fact_care_and_treatment
(
    id                     INT AUTO_INCREMENT PRIMARY KEY,
    client_id              INT NULL,
    weight_in_kg           DOUBLE,
    cd4_count              DOUBLE,
    current_who_hiv_stage  VARCHAR(255),
    nutritional_status     VARCHAR(255),
    tb_screening_result    VARCHAR(255),
    enrollment_date        DATE,
    hiv_confirmed_date     DATE,
    art_start_date         DATE,
    days_difference        INT,
    followup_date          DATE,
    regimen                VARCHAR(255),
    arv_dose_days          VARCHAR(255),
    pregnancy_status       VARCHAR(255),
    breast_feeding_status  VARCHAR(255),
    follow_up_status       VARCHAR(255),
    ti                     VARCHAR(255),
    treatment_end_date     DATE,
    next_visit_date        DATE,
    latest_followup_date   DATE,
    latest_followup_status VARCHAR(255),
    latest_regimen         VARCHAR(255),
    latest_arv_dose_days   VARCHAR(255),

    INDEX mamba_idx_art_start_date (art_start_date),
    INDEX mamba_idx_client_id (client_id),
    INDEX mamba_idx_cd4_count (cd4_count)
);
-- $END

