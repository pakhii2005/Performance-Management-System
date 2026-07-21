package com.epms.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import com.epms.dto.UserRequest;
import com.epms.dto.UserResponse;
import com.epms.entity.Role;
import com.epms.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserService userService;

    @PostMapping
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody UserRequest request) {
        UserResponse response = userService.save(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<List<UserResponse>> getAllUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) String department,
            @RequestParam(required = false) Boolean enabled) {
        List<UserResponse> users = userService.searchAndFilter(search, role, department, enabled);
        return ResponseEntity.ok(users);
    }

    @GetMapping("/employees")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<List<UserResponse>> getEmployees() {
        List<UserResponse> employees = userService.findEmployees();
        return ResponseEntity.ok(employees);
    }

    @GetMapping("/managers")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<List<UserResponse>> getManagers() {
        List<UserResponse> managers = userService.findManagers();
        return ResponseEntity.ok(managers);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('CEO') or @securityService.isSelf(principal.username, #id)")
    public ResponseEntity<UserResponse> getUserById(@PathVariable Long id) {
        UserResponse user = userService.findById(id);
        return ResponseEntity.ok(user);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<UserResponse> updateUser(@PathVariable Long id, @Valid @RequestBody UserRequest request) {
        UserResponse response = userService.updateUser(id, request);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}/activate")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<Void> activateUser(@PathVariable Long id) {
        userService.setEnabled(id, true);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<Void> deactivateUser(@PathVariable Long id) {
        userService.setEnabled(id, false);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/reset-password")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<Map<String, String>> resetPassword(@PathVariable Long id) {
        String tempPassword = userService.resetPassword(id);
        return ResponseEntity.ok(Map.of("temporaryPassword", tempPassword));
    }

    @PatchMapping("/{id}/assign-manager")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<Void> assignManager(
            @PathVariable Long id, 
            @RequestParam(required = false) Long managerId) {
        userService.assignManager(id, managerId);
        return ResponseEntity.ok().build();
    }
}
