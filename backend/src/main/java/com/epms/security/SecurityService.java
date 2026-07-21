package com.epms.security;

import com.epms.entity.Role;
import com.epms.entity.User;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service("securityService")
@RequiredArgsConstructor
public class SecurityService {

    private final UserRepository userRepository;

    public boolean isSelf(String email, Long userId) {
        return userRepository.findByEmail(email)
                .map(user -> user.getId().equals(userId))
                .orElse(false);
    }

    public boolean isManagerOf(String managerEmail, Long employeeId) {
        User employee = userRepository.findById(employeeId).orElse(null);
        if (employee == null) {
            return false;
        }
        User manager = employee.getManager();
        return manager != null && manager.getEmail().equals(managerEmail);
    }

    public boolean canAccessEmployee(String email, Long employeeId) {
        User currentUser = userRepository.findByEmail(email).orElse(null);
        if (currentUser == null) {
            return false;
        }
        if (currentUser.getRole() == Role.CEO) {
            return true;
        }
        if (currentUser.getId().equals(employeeId)) {
            return true;
        }
        return isManagerOf(email, employeeId);
    }

    public boolean canAccessManager(String email, Long managerId) {
        User currentUser = userRepository.findByEmail(email).orElse(null);
        if (currentUser == null) {
            return false;
        }
        if (currentUser.getRole() == Role.CEO) {
            return true;
        }
        return currentUser.getId().equals(managerId);
    }
}
