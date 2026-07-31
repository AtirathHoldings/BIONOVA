package com.bionova.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtUtil {

    private final SecretKey secretKey;
    private final long expiration;

    public JwtUtil(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration:86400000}") long expiration) {
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expiration = expiration;
    }

    /**
     * Generate a JWT token for the given email, role, and empId.
     */
    public String generateToken(String email, String role, Long empId) {
        return Jwts.builder()
                .subject(email)
                .claim("role", role)
                .claim("empId", empId)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(secretKey)
                .compact();
    }

    /**
     * Generate a JWT token for the given email and role (no empId - for backward compat).
     */
    public String generateToken(String email, String role) {
        return generateToken(email, role, null);
    }

    /**
     * Extract the empId claim from a token (may be null if not present).
     */
    public Long extractEmpId(String token) {
        Object empId = extractClaims(token).get("empId");
        if (empId instanceof Integer) return ((Integer) empId).longValue();
        if (empId instanceof Long) return (Long) empId;
        if (empId instanceof Number) return ((Number) empId).longValue();
        return null;
    }

    /**
     * Extract all claims from a token (throws if invalid/expired).
     */
    public Claims extractClaims(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Extract the subject (email) from a token.
     */
    public String extractEmail(String token) {
        return extractClaims(token).getSubject();
    }

    /**
     * Validate token: parses it (throws on invalid/expired), returns true if OK.
     */
    public boolean isTokenValid(String token) {
        try {
            extractClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
