package com.epms.service;

import com.epms.dto.ChangePasswordRequest;
import com.epms.dto.UserRequest;
import com.epms.dto.UserResponse;
import com.epms.entity.Role;
import com.epms.entity.User;
import com.epms.exception.ResourceNotFoundException;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public UserResponse save(UserRequest request) {
        // Email uniqueness validation
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email address already in use: " + request.getEmail());
        }

        // Password strength validation
        validatePasswordStrength(request.getPassword());

        User.UserBuilder userBuilder = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .department(request.getDepartment())
                .enabled(true)
                .passwordResetRequired(true); // Mandatory reset on first login for temporary passwords

        if (request.getManagerId() != null) {
            User manager = userRepository.findById(request.getManagerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + request.getManagerId()));
            if (manager.getRole() != Role.MANAGER) {
                throw new IllegalArgumentException("Assigned supervisor must hold the MANAGER role");
            }
            userBuilder.manager(manager);
        }

        User savedUser = userRepository.save(userBuilder.build());
        return mapToResponse(savedUser);
    }

    @Transactional
    public UserResponse updateUser(Long id, UserRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + id));

        // Email cannot be changed
        if (request.getEmail() != null && !request.getEmail().equalsIgnoreCase(user.getEmail())) {
            throw new IllegalArgumentException("Email address cannot be modified after user creation");
        }

        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setDepartment(request.getDepartment());

        if (request.getManagerId() != null) {
            User manager = userRepository.findById(request.getManagerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + request.getManagerId()));
            if (manager.getRole() != Role.MANAGER) {
                throw new IllegalArgumentException("Assigned supervisor must hold the MANAGER role");
            }
            user.setManager(manager);
        } else {
            user.setManager(null);
        }

        User savedUser = userRepository.save(user);
        return mapToResponse(savedUser);
    }

    @Transactional
    public void setEnabled(Long id, boolean enabled) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + id));
        user.setEnabled(enabled);
        userRepository.save(user);
    }

    @Transactional
    public String resetPassword(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + id));

        String temporaryPassword = generateTemporaryPassword();
        user.setPassword(passwordEncoder.encode(temporaryPassword));
        user.setPasswordResetRequired(true);
        user.setFailedLoginAttempts(0);
        user.setLockTime(null);
        userRepository.save(user);

        return temporaryPassword;
    }

    @Transactional
    public void assignManager(Long id, Long managerId) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + id));

        if (user.getRole() != Role.EMPLOYEE) {
            throw new IllegalArgumentException("Only users with the EMPLOYEE role can be assigned a manager");
        }

        if (managerId != null) {
            User manager = userRepository.findById(managerId)
                    .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + managerId));
            if (manager.getRole() != Role.MANAGER) {
                throw new IllegalArgumentException("Supervisor must hold the MANAGER role");
            }
            user.setManager(manager);
        } else {
            user.setManager(null);
        }
        userRepository.save(user);
    }

    @Transactional
    public void changePassword(String email, ChangePasswordRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + email));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Current password verification failed");
        }

        if (!request.getNewPassword().equals(request.getConfirmNewPassword())) {
            throw new IllegalArgumentException("New passwords do not match");
        }

        validatePasswordStrength(request.getNewPassword());

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setPasswordResetRequired(false);
        userRepository.save(user);
    }

    public List<UserResponse> searchAndFilter(String search, Role role, String department, Boolean enabled) {
        String querySearch = (search == null || search.trim().isEmpty()) ? null : "%" + search.trim().toLowerCase() + "%";
        String queryDept = (department == null || department.trim().isEmpty()) ? null : department.trim().toLowerCase();

        return userRepository.searchAndFilterUsers(querySearch, role, queryDept, enabled).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<UserResponse> findAll() {
        return userRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public UserResponse findById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with ID: " + id));
        return mapToResponse(user);
    }

    public List<UserResponse> findEmployees() {
        return userRepository.findByRole(Role.EMPLOYEE).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<UserResponse> findManagers() {
        return userRepository.findByRole(Role.MANAGER).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public UserResponse mapToResponse(User user) {
        String managerName = null;
        if (user.getManager() != null) {
            managerName = user.getManager().getFirstName() + " " + user.getManager().getLastName();
        }
        int employeeCount = user.getEmployees() != null ? user.getEmployees().size() : 0;

        return UserResponse.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .role(user.getRole())
                .department(user.getDepartment())
                .managerId(user.getManager() != null ? user.getManager().getId() : null)
                .managerName(managerName)
                .employeeCount(employeeCount)
                .createdAt(user.getCreatedAt())
                .enabled(user.getEnabled())
                .passwordResetRequired(user.getPasswordResetRequired())
                .build();
    }

    private void validatePasswordStrength(String password) {
        if (password == null || password.length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters long");
        }
        boolean hasUpper = password.chars().anyMatch(Character::isUpperCase);
        boolean hasLower = password.chars().anyMatch(Character::isLowerCase);
        boolean hasDigit = password.chars().anyMatch(Character::isDigit);
        boolean hasSpecial = password.chars().anyMatch(ch -> "!@#$%^&*()_+-=[]{};:'\"\\|,.<>/?~`".indexOf(ch) >= 0);

        if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
            throw new IllegalArgumentException("Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character");
        }
    }

    private String generateTemporaryPassword() {
        return "Temp" + UUID.randomUUID().toString().substring(0, 8) + "!";
    }
}
