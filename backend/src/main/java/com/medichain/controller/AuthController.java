package com.medichain.controller;

import com.medichain.dao.AuditDAO;
import com.medichain.dao.UserDAO;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final UserDAO userDAO;
    private final AuditDAO auditDAO;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Value("${app.jwt.secret}")
    private String jwtSecret;

    @Value("${app.jwt.expiration}")
    private long jwtExpiration;

    public AuthController(UserDAO userDAO, AuditDAO auditDAO) {
        this.userDAO = userDAO;
        this.auditDAO = auditDAO;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, Object> body) {
        String username = (String) body.get("username");
        String password = (String) body.get("password");
        String role = (String) body.getOrDefault("role", "patient");

        if (username == null || password == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Username and password required"));
        }

        if (userDAO.findByUsername(username) != null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Username already exists"));
        }

        String hash = encoder.encode(password);
        Long userId = userDAO.createUser(username, hash, role);

        // Link to role-specific table
        if ("patient".equals(role) && body.get("health_id") != null) {
            userDAO.linkPatientUser(userId, (String) body.get("health_id"));
        } else if ("doctor".equals(role) && body.get("doctor_id") != null) {
            userDAO.linkDoctorUser(userId, Long.valueOf(body.get("doctor_id").toString()));
        } else if ("admin".equals(role)) {
            userDAO.linkAdminUser(userId);
        }

        auditDAO.logAction(userId, "USER_REGISTER", "APP_USER", userId.toString(),
                null, null, "New user registered: " + username + " (role: " + role + ")");

        return ResponseEntity.ok(Map.of("message", "User registered successfully", "user_id", userId));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, Object> body,
                                   @RequestHeader(value = "X-Forwarded-For", defaultValue = "127.0.0.1") String ip) {
        String username = (String) body.get("username");
        String password = (String) body.get("password");
        String selectedRole = (String) body.get("role"); // Role selected on the login form

        if (username == null || password == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Username and password required"));
        }

        Map<String, Object> user = userDAO.findByUsername(username);

        if (user == null || !encoder.matches(password, (String) user.get("password_hash"))) {
            auditDAO.logLoginAttempt(username, ip, "Web", false);
            return ResponseEntity.status(401).body(Map.of("error", "Invalid credentials"));
        }

        if (!"Active".equals(user.get("status"))) {
            return ResponseEntity.status(403).body(Map.of("error", "Account is " + user.get("status")));
        }

        Long userId = ((Number) user.get("user_id")).longValue();
        String role = (String) user.get("role");

        // Validate that selected role matches the user's actual role
        if (selectedRole != null && !selectedRole.isEmpty() && !role.equals(selectedRole)) {
            auditDAO.logLoginAttempt(username, ip, "Web", false);
            return ResponseEntity.status(403).body(Map.of(
                "error", "Access denied. This account does not have " + selectedRole + " privileges. Your role is: " + role
            ));
        }

        userDAO.updateLastLogin(userId);
        auditDAO.logLoginAttempt(username, ip, "Web", true);

        // Generate JWT
        SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
        String token = Jwts.builder()
                .subject(userId.toString())
                .claim("username", username)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(key)
                .compact();

        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        response.put("user_id", userId);
        response.put("username", username);
        response.put("role", role);

        // Add linked IDs
        String healthId = userDAO.getHealthIdForUser(userId);
        Long doctorId = userDAO.getDoctorIdForUser(userId);
        if (healthId != null) response.put("health_id", healthId);
        if (doctorId != null) response.put("doctor_id", doctorId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/users")
    public ResponseEntity<?> listUsers() {
        return ResponseEntity.ok(userDAO.findAllUsers());
    }
}
