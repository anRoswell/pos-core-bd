-- =============================================================================
-- Migration 03: Change logo_url from VARCHAR(500) to TEXT in core.businesses
-- Permite almacenar de forma persistente y blindada logotipos en Base64 Data URI
-- =============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'core'
          AND table_name = 'businesses'
          AND column_name = 'logo_url'
          AND data_type = 'character varying'
    ) THEN
        ALTER TABLE core.businesses ALTER COLUMN logo_url TYPE text;
    END IF;
END $$;
