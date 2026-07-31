import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;

public class DbCheck {
    public static void main(String[] args) {
        String url = "jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true&prepareThreshold=0";
        String user = "postgres.daaoeapbouspxcuprsqx";
        String password = "Atirath@2026";
        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM task_live_master LIMIT 1")) {
            ResultSetMetaData meta = rs.getMetaData();
            int cols = meta.getColumnCount();
            System.out.println("Columns in task_live_master:");
            for (int i = 1; i <= cols; i++) {
                System.out.println("  " + meta.getColumnName(i) + " (" + meta.getColumnTypeName(i) + ")");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
