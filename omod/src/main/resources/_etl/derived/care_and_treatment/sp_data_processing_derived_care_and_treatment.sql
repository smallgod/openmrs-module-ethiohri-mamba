-- $BEGIN
CALL sp_dim_client_care_and_treatment();
CALL sp_fact_encounter_care_and_treatment();
CALL sp_datim_tx_new_view();
-- $END