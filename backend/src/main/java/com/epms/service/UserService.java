package com.epms.service;

import com.epms.dto.UserRequest;
import com.epms.dto.UserResponse;
import com.epms.entity.User;
import com.epms.exception.ResourceNotFoundException;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;

    @Transactional
    public UserResponse save(UserRequest request) {
        User.UserBuilder userBuilder = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .password(request.getPassword()) // Authentication/encoding is not part of Phase 2
                .role(request.getRole())
                .department(request.getDepartment());

        if (request.getManagerId() != null) {
            User manager = userRepository.findById(request.getManagerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Manager not found with ID: " + request.getManagerId()));
            userBuilder.manager(manager);
        }

        User savedUser = userRepository.save(userBuilder.build());
        return mapToResponse(savedUser);
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
        return userRepository.findByRole(com.epms.entity.Role.EMPLOYEE).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<UserResponse> findManagers() {
        return userRepository.findByRole(com.epms.entity.Role.MANAGER).stream()
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
                .build();
    }
}
