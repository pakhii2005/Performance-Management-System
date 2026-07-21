package com.epms.auth;

import com.epms.dto.*;
import com.epms.entity.RefreshToken;
import com.epms.entity.Role;
import com.epms.entity.User;
import com.epms.exception.BadCredentialsException;
import com.epms.exception.ResourceNotFoundException;
import com.epms.jwt.JWTService;
import com.epms.repository.RefreshTokenRepository;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JWTService jwtService;
    private final UserDetailsService userDetailsService;

    private static final int MAX_FAILED_ATTEMPTS = 5;
    private static final int LOCK_TIME_DURATION_MINUTES = 15;

    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        // Check if account is locked
        if (isLocked(user)) {
            throw new BadCredentialsException("Account is temporarily locked. Please try again later.");
        }

        // Compare hashed password
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            increaseFailedAttempts(user);
            throw new BadCredentialsException("Invalid email or password");
        }

        // Login successful: reset failed attempts
        resetFailedAttempts(user);

        // Generate tokens
        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String accessToken = jwtService.generateToken(userDetails, user.getId(), user.getRole().name());
        RefreshToken refreshToken = createRefreshToken(user);

        return LoginResponse.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .role(user.getRole())
                .accessToken(accessToken)
                .refreshToken(refreshToken.getToken())
                .expiresIn(3600L) // 1 hour in seconds
                .passwordResetRequired(user.getPasswordResetRequired())
                .build();
    }

    @Transactional
    public User register(RegisterRequest request) {
        // Validate password match
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("Password and password confirmation do not match");
        }

        // Validate password strength
        validatePasswordStrength(request.getPassword());

        // Validate email uniqueness
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email is already in use");
        }

        // Verify that creator is authenticated and is a CEO
        String currentUserEmail = SecurityContextHolder.getContext().getAuthentication().getName();
        User currentUser = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new AccessDeniedException("CEO authentication required to register users"));
        if (currentUser.getRole() != Role.CEO) {
            throw new AccessDeniedException("Only the CEO can create Managers and Employees");
        }

        User.UserBuilder userBuilder = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .department(request.getDepartment())
                .failedLoginAttempts(0);

        if (request.getManagerId() != null) {
            User manager = userRepository.findById(request.getManagerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + request.getManagerId()));
            userBuilder.manager(manager);
        }

        return userRepository.save(userBuilder.build());
    }

    @Transactional
    public RefreshTokenResponse refresh(RefreshTokenRequest request) {
        String requestRefreshToken = request.getRefreshToken();
        return refreshTokenRepository.findByToken(requestRefreshToken)
                .map(this::verifyExpiration)
                .map(RefreshToken::getUser)
                .map(user -> {
                    UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
                    String accessToken = jwtService.generateToken(userDetails, user.getId(), user.getRole().name());
                    return RefreshTokenResponse.builder()
                            .accessToken(accessToken)
                            .refreshToken(requestRefreshToken)
                            .expiresIn(3600L)
                            .build();
                })
                .orElseThrow(() -> new IllegalArgumentException("Refresh token is invalid or expired"));
    }

    @Transactional
    public void logout(String refreshToken) {
        refreshTokenRepository.findByToken(refreshToken)
                .ifPresent(token -> {
                    refreshTokenRepository.deleteByUser(token.getUser());
                });
    }

    private RefreshToken createRefreshToken(User user) {
        // Delete any existing refresh token for the user to prevent leakage/duplicates
        refreshTokenRepository.deleteByUser(user);
        refreshTokenRepository.flush();

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(UUID.randomUUID().toString())
                .expiryDate(Instant.now().plusMillis(86400000)) // 24 hours
                .build();
        return refreshTokenRepository.save(refreshToken);
    }

    private RefreshToken verifyExpiration(RefreshToken token) {
        if (token.getExpiryDate().compareTo(Instant.now()) < 0) {
            refreshTokenRepository.delete(token);
            throw new IllegalArgumentException("Refresh token was expired. Please log in again");
        }
        return token;
    }

    private boolean isLocked(User user) {
        if (user.getLockTime() == null) {
            return false;
        }
        if (user.getLockTime().isBefore(LocalDateTime.now())) {
            // Lock expired: reset lock
            user.setLockTime(null);
            user.setFailedLoginAttempts(0);
            userRepository.save(user);
            return false;
        }
        return true;
    }

    private void increaseFailedAttempts(User user) {
        int newAttempts = user.getFailedLoginAttempts() + 1;
        user.setFailedLoginAttempts(newAttempts);
        if (newAttempts >= MAX_FAILED_ATTEMPTS) {
            user.setLockTime(LocalDateTime.now().plusMinutes(LOCK_TIME_DURATION_MINUTES));
        }
        userRepository.save(user);
    }

    private void resetFailedAttempts(User user) {
        if (user.getFailedLoginAttempts() > 0 || user.getLockTime() != null) {
            user.setFailedLoginAttempts(0);
            user.setLockTime(null);
            userRepository.save(user);
        }
    }

    private void validatePasswordStrength(String password) {
        if (password == null || password.length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters long");
        }
        boolean hasUpper = false;
        boolean hasLower = false;
        boolean hasDigit = false;
        boolean hasSpecial = false;
        for (char c : password.toCharArray()) {
            if (Character.isUpperCase(c)) hasUpper = true;
            else if (Character.isLowerCase(c)) hasLower = true;
            else if (Character.isDigit(c)) hasDigit = true;
            else if ("!@#$%^&*()_+-=[]{}|;:',.<>?/`~".indexOf(c) >= 0) hasSpecial = true;
        }
        if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
            throw new IllegalArgumentException("Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character");
        }
    }
}
