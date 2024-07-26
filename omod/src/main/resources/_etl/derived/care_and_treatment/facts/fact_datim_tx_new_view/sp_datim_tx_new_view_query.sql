DELIMITER //

DROP PROCEDURE IF EXISTS sp_dim_tx_new_datim_query;

-- e.g. CALL sp_dim_tx_new_datim_query('2020-01-01', '2020-01-01', 0, 'unknown');

CREATE PROCEDURE sp_dim_tx_new_datim_query(
    IN REPORT_START_DATE DATE,
    IN REPORT_END_DATE DATE,
    IN IS_COURSE_AGE_GROUP BOOLEAN, -- expected values: 0 for fine age group, 1 for coarse age group
    IN CD4_COUNT_GROUPAGE VARCHAR(255) -- expected values are: 'all', '>200', '<200', 'unknown'
)
BEGIN

    DECLARE cd4_count_condition VARCHAR(255);
    DECLARE age_group_cols VARCHAR(5000);
    DECLARE view_to_store_results VARCHAR(255);
    DECLARE date_condition VARCHAR(1000);

    SET session group_concat_max_len = 20000;

    IF CD4_COUNT_GROUPAGE = 'all' THEN
        SET cd4_count_condition = '1=1';
    ELSEIF CD4_COUNT_GROUPAGE = '>200' THEN
        SET cd4_count_condition = 'fact_ct.cd4_count > 200';
    ELSEIF CD4_COUNT_GROUPAGE = '<200' THEN
        SET cd4_count_condition = 'fact_ct.cd4_count < 200';
    ELSEIF CD4_COUNT_GROUPAGE = 'unknown' THEN
        SET cd4_count_condition = 'fact_ct.cd4_count IS NULL';
    ELSE
        SET cd4_count_condition = '1=1';
    END IF;

    IF IS_COURSE_AGE_GROUP THEN
        -- view to store tx_new datim coarse age group results
        SET view_to_store_results = 'mamba_view_datim_tx_new_coarse_agegroup';

        -- coarse age group columns
        SELECT GROUP_CONCAT(DISTINCT
                            CONCAT(
                                    'MAX(CASE WHEN coarse_age_group = ''',
                                    coarse_age_group,
                                    ''' THEN count ELSE 0 END) AS `',
                                    coarse_age_group, '`'
                            )
               )
        INTO age_group_cols
        FROM mamba_dim_client_care_and_treatment;
    ELSE
        -- view to store tx_new datim fine age group results
        SET view_to_store_results = 'mamba_view_datim_tx_new_fine_agegroup';

        -- fine age group columns
        SELECT GROUP_CONCAT(DISTINCT
                            CONCAT(
                                    'MAX(CASE WHEN fine_age_group = ''',
                                    fine_age_group,
                                    ''' THEN count ELSE 0 END) AS `',
                                    fine_age_group, '`'
                            )
               )
        INTO age_group_cols
        FROM mamba_dim_client_care_and_treatment;
    END IF;

    IF REPORT_START_DATE IS NULL THEN
        IF REPORT_END_DATE IS NULL THEN
            SET date_condition = '1=1';
        ELSE
            SET date_condition = 'fact_ct.art_start_date <= ?';
        END IF;
    ELSE
        IF REPORT_END_DATE IS NULL THEN
            SET date_condition = 'fact_ct.art_start_date >= ?';
        ELSE
            SET date_condition = 'fact_ct.art_start_date BETWEEN ? AND ?';
        END IF;
    END IF;

    SET @sql = CONCAT('CREATE OR REPLACE VIEW ', view_to_store_results, ' AS
        SELECT
          sex,
          ', age_group_cols, '
        FROM (
          SELECT
            sex,
            ', IF(IS_COURSE_AGE_GROUP, 'coarse_age_group', 'fine_age_group'), ',
            COUNT(*) AS count
          FROM mamba_dim_client_care_and_treatment dim_ct
                INNER JOIN analysis_db.mamba_fact_care_and_treatment fact_ct
                           ON dim_ct.client_id = fact_ct.client_id
                WHERE ', date_condition, '
                  AND ', cd4_count_condition, '
                  AND dim_ct.mrn is not null and fact_ct.follow_up_status in (''Alive'', ''Restart'')
          GROUP BY sex, ', IF(IS_COURSE_AGE_GROUP, 'coarse_age_group', 'fine_age_group'), '
        ) AS subquery
        RIGHT JOIN (SELECT ''MALE'' AS sex UNION SELECT ''FEMALE'') AS genders
        USING (sex)
        GROUP BY sex
        ');

    PREPARE stmt FROM @sql;
    IF REPORT_START_DATE IS NULL THEN
        IF REPORT_END_DATE IS NULL THEN
            EXECUTE stmt;
        ELSE
            SET @end_date = REPORT_END_DATE;
            EXECUTE stmt USING @end_date;
        END IF;
    ELSE
        IF REPORT_END_DATE IS NULL THEN
            SET @start_date = REPORT_START_DATE;
            EXECUTE stmt USING @start_date;
        ELSE
            SET @start_date = REPORT_START_DATE;
            SET @end_date = REPORT_END_DATE;
            EXECUTE stmt USING @start_date, @end_date;
        END IF;
    END IF;
    DEALLOCATE PREPARE stmt;

END //

DELIMITER ;