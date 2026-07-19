package com.epms.service;

import com.epms.dto.LoginRequest;
import com.epms.dto.LoginResponse;
import com.epms.entity.User;
import com.epms.exception.BadCredentialsException;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthenticationService {

    private final UserRepository userRepository;

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        // Compare plain-text password as requested for the Phase 3 prototype
        if (!user.getPassword().equals(request.getPassword())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        return LoginResponse.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .role(user.getRole())
                .build();
    }
}
