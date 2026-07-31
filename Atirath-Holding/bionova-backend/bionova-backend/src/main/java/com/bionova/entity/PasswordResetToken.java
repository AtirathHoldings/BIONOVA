package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "password_reset_token")
@Getter
@Setter
public class PasswordResetToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** The secure random token sent in the reset email link */
    @Column(nullable = false, unique = true)
    private String token;

    /** Employee email this token belongs to */
    @Column(nullable = false)
    private String email;

    /** Token expires 30 minutes after creation */
    @Column(nullable = false)
    private LocalDateTime expiresAt;

    /** Marks the token as already used — can't be reused */
    @Column(nullable = false)
    private boolean used = false;
}
