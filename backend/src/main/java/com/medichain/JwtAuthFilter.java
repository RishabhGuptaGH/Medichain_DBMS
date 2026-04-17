package com.medichain;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Set;

@Component
@Order(1)
public class JwtAuthFilter implements Filter {

    @Value("${app.jwt.secret}")
    private String jwtSecret;

    // Endpoints that require no authentication
    private static final Set<String> PUBLIC_PATHS = Set.of(
        "/api/auth/login"
    );

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String path = req.getRequestURI();
        String method = req.getMethod();

        // Allow CORS preflight
        if ("OPTIONS".equalsIgnoreCase(method)) {
            chain.doFilter(request, response);
            return;
        }

        // Public endpoints - no auth required
        if (!path.startsWith("/api/") || PUBLIC_PATHS.stream().anyMatch(path::startsWith)) {
            chain.doFilter(request, response);
            return;
        }

        // Extract JWT from Authorization header
        String authHeader = req.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            res.setStatus(401);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Authentication required\"}");
            return;
        }

        // Parse and validate JWT token
        String role;
        try {
            String token = authHeader.substring(7);
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
            var claims = Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            var payload = claims.getPayload();

            role = payload.get("role", String.class);
            Long userId = Long.valueOf(payload.getSubject());
            String username = payload.get("username", String.class);

            // Store user info in request attributes for controllers to use
            req.setAttribute("userId", userId);
            req.setAttribute("username", username);
            req.setAttribute("role", role);
        } catch (Exception e) {
            res.setStatus(401);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Invalid or expired token\"}");
            return;
        }

        // ── Role-Based Access Control ──
        // Clinical endpoints accessible by both admin and doctor
        boolean isDoctorAllowed = "doctor".equals(role) && (
            path.startsWith("/api/encounters")
            || path.startsWith("/api/prescriptions")
            || path.startsWith("/api/lab")
            || path.startsWith("/api/hospitals")
        );

        // Admin-only endpoints (unless doctor is allowed above)
        if ((path.startsWith("/api/dashboard")
                || path.startsWith("/api/patients")
                || path.startsWith("/api/doctors")
                || path.startsWith("/api/hospitals")
                || path.startsWith("/api/encounters")
                || path.startsWith("/api/prescriptions")
                || path.startsWith("/api/lab")
                || path.startsWith("/api/consent")
                || path.startsWith("/api/audit")
                || path.startsWith("/api/transaction-demo")
                || path.startsWith("/api/auth/register")
                || path.equals("/api/auth/users"))
                && !"admin".equals(role)
                && !isDoctorAllowed) {
            res.setStatus(403);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Access denied. Insufficient privileges.\"}");
            return;
        }

        // Doctor portal - doctors only
        if (path.startsWith("/api/doctor-portal") && !"doctor".equals(role)) {
            res.setStatus(403);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Access denied. Doctor role required.\"}");
            return;
        }

        // Patient portal - patients only
        if (path.startsWith("/api/patient-portal") && !"patient".equals(role)) {
            res.setStatus(403);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Access denied. Patient role required.\"}");
            return;
        }

        // Proceed to controller - exceptions here are NOT caught as auth errors
        chain.doFilter(request, response);
    }
}