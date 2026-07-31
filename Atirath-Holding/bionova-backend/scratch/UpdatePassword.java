import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class UpdatePassword {
    public static void main(String[] args) {
        String rawPassword = "Aathika@123";
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hashedPassword = encoder.encode(rawPassword);

        System.out.println("Raw Password: " + rawPassword);
        System.out.println("Hashed Password: " + hashedPassword);

        String url = "jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true&prepareThreshold=0";
        String user = "postgres.daaoeapbouspxcuprsqx";
        String password = "Atirath@2026";

        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            // Update employee password in employee_master / employee table for emp_id = 29 or email = shaikaathikafarheen@gmail.com
            String sql = "UPDATE employee_master SET password = ? WHERE emp_id = 29 OR email = 'shaikaathikafarheen@gmail.com'";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, hashedPassword);
                int rows = pstmt.executeUpdate();
                System.out.println("Updated " + rows + " row(s) in employee_master.");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
