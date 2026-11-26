package com.bionova.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class SqlMigrateSku {
    public static void main(String[] args) {
        String url = "jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require&prepareThreshold=0";
        String user = "postgres.daaoeapbouspxcuprsqx";
        String pass = "Atirath@2026";

        System.out.println("Connecting to Supabase PostgreSQL database directly...");
        try (Connection conn = DriverManager.getConnection(url, user, pass);
             Statement stmt = conn.createStatement()) {

            System.out.println("Connected successfully! Creating SKU tables and columns...");

            // 1. inventory_sku_master table
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS inventory_sku_master (" +
                "  id BIGSERIAL PRIMARY KEY, " +
                "  category VARCHAR(50) NOT NULL, " +
                "  option_type VARCHAR(50) NOT NULL, " +
                "  code VARCHAR(50) NOT NULL, " +
                "  label VARCHAR(150) NOT NULL, " +
                "  metadata VARCHAR(255), " +
                "  sort_order INT, " +
                "  is_active BOOLEAN NOT NULL DEFAULT TRUE" +
                ")"
            );
            System.out.println("Created table inventory_sku_master");

            // 2. sku_sequence_counter table
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS sku_sequence_counter (" +
                "  id BIGSERIAL PRIMARY KEY, " +
                "  category_prefix VARCHAR(20) NOT NULL UNIQUE, " +
                "  current_sequence BIGINT NOT NULL DEFAULT 0, " +
                "  last_assigned_sku VARCHAR(100), " +
                "  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                ")"
            );
            System.out.println("Created table sku_sequence_counter");

            // 3. Add SKU columns to existing tables if not present
            stmt.execute("ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS sku VARCHAR(100)");
            stmt.execute("ALTER TABLE inventory_civil_bom ADD COLUMN IF NOT EXISTS sku VARCHAR(100)");
            stmt.execute("ALTER TABLE inventory_fasteners ADD COLUMN IF NOT EXISTS sku VARCHAR(100)");
            stmt.execute("ALTER TABLE inventory_piping ADD COLUMN IF NOT EXISTS sku VARCHAR(100)");
            System.out.println("Added sku columns to inventory tables");

            // 4. Unique constraints
            try {
                stmt.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_inv_items_sku ON inventory_items(sku) WHERE sku IS NOT NULL AND sku <> ''");
                stmt.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_inv_fasteners_sku ON inventory_fasteners(item_code) WHERE item_code IS NOT NULL AND item_code <> ''");
                System.out.println("Added unique constraints for SKU codes");
            } catch (Exception ex) {
                System.out.println("Notice on unique constraints: " + ex.getMessage());
            }

            // 5. Initialize sequence counters
            stmt.execute(
                "INSERT INTO sku_sequence_counter (category_prefix, current_sequence, last_assigned_sku) " +
                "VALUES ('AGR', 4, 'AGR-SD-004'), ('PCB', 3, 'PCB-ELE-MTR-001-0003'), " +
                "       ('FST', 3, 'FST-WSH-316-03'), ('PIP', 2, 'PIP-PV-02'), ('INS', 1, 'INS-FM-01') " +
                "ON CONFLICT (category_prefix) DO NOTHING"
            );
            System.out.println("Initialized sku_sequence_counter rows");

            System.out.println("=== SKU DATABASE MIGRATION COMPLETED SUCCESSFULLY ===");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
