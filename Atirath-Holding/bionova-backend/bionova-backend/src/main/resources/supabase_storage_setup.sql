-- ============================================================
-- BIONOVA Supabase Storage Setup
-- Run these in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. ALTER attachments_master to add new ref columns
--    (Hibernate ddl-auto=update does this automatically,
--     but you can run manually for safety)
-- ────────────────────────────────────────────────────────────
ALTER TABLE attachments_master
    ADD COLUMN IF NOT EXISTS ref_id   BIGINT,
    ADD COLUMN IF NOT EXISTS ref_type VARCHAR(20);

-- Make old columns nullable for backward compat
ALTER TABLE attachments_master
    ALTER COLUMN t_id  DROP NOT NULL,
    ALTER COLUMN is_live DROP NOT NULL;

-- ────────────────────────────────────────────────────────────
-- 2. Add indexes for efficient lookup
-- ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_attachments_ref ON attachments_master(ref_id, ref_type);

-- ────────────────────────────────────────────────────────────
-- 3. Storage Bucket Policies
--    (Already created via Supabase Dashboard, but as reference:)
--    - "images"    bucket = PUBLIC
--    - "documents" bucket = PRIVATE (authenticated only)
-- ────────────────────────────────────────────────────────────

-- ── Folder structure inside "images" bucket ──────────────────
-- logos/company/           → Company logos      (company_master.logo)
-- logos/plantmaster/       → Plant logos        (plant_master.logo)
-- logos/landmaster/        → Land images        (land_master.logo)
-- photos/employees/        → Employee photos    (employee_master.photo_url)
-- photos/external-employees/ → Ext emp photos   (external_employee_master.photo_path)
-- projects/                → Project logos      (project_live_master.logo)

-- ── Folder structure inside "documents" bucket ───────────────
-- attachments/milestones/  → Milestone attachments
-- attachments/tasks/       → Task attachments (draft & live)
-- attachments/projects/    → Project attachments

-- ────────────────────────────────────────────────────────────
-- 4. Storage RLS Policies for "images" bucket (public reads)
-- ────────────────────────────────────────────────────────────

-- Allow public read on images bucket
CREATE POLICY "Public read access on images"
    ON storage.objects FOR SELECT
    USING ( bucket_id = 'images' );

-- Allow authenticated users to upload to images bucket
CREATE POLICY "Authenticated upload to images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'images'
        AND auth.role() = 'authenticated'
    );

-- Allow authenticated users to delete from images bucket
CREATE POLICY "Authenticated delete from images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'images'
        AND auth.role() = 'authenticated'
    );

-- ────────────────────────────────────────────────────────────
-- 5. Storage RLS Policies for "documents" bucket (private)
-- ────────────────────────────────────────────────────────────

-- Allow authenticated users to read from documents bucket
CREATE POLICY "Authenticated read on documents"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'documents'
        AND auth.role() = 'authenticated'
    );

-- Allow authenticated users to upload to documents bucket
CREATE POLICY "Authenticated upload to documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND auth.role() = 'authenticated'
    );

-- Allow authenticated users to delete from documents bucket
CREATE POLICY "Authenticated delete from documents"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'documents'
        AND auth.role() = 'authenticated'
    );

-- ────────────────────────────────────────────────────────────
-- NOTE: Since the Spring backend uses service_role key,
-- it bypasses RLS and can access all buckets directly.
-- The policies above apply to direct frontend Supabase client calls.
-- ────────────────────────────────────────────────────────────
