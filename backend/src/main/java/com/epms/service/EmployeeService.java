package com.epms.service;

import com.epms.dto.UserResponse;
import com.epms.dto.EvaluationResponse;
import com.epms.entity.Evaluation;
import com.epms.entity.Role;
import com.epms.entity.User;
import com.epms.exception.ResourceNotFoundException;
import com.epms.repository.EvaluationRepository;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EmployeeService {

    private final UserRepository userRepository;
    private final EvaluationRepository evaluationRepository;
    private final UserService userService;
    private final EvaluationService evaluationService;

    /**
     * Retrieves the employee user profile mapping fields.
     * Throws ResourceNotFoundException (404) if user does not exist or role is not EMPLOYEE.
     */
    public UserResponse getEmployeeProfile(Long employeeId) {
        User user = userRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));

        if (user.getRole() != Role.EMPLOYEE) {
            throw new ResourceNotFoundException("User with ID " + employeeId + " is not an Employee");
        }

        return userService.mapToResponse(user);
    }

    /**
     * Retrieves evaluations specifically belonging to this employee.
     * Returns empty list if no evaluations exist.
     */
    public List<EvaluationResponse> getEmployeeEvaluations(Long employeeId) {
        User user = userRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));

        if (user.getRole() != Role.EMPLOYEE) {
            throw new ResourceNotFoundException("User with ID " + employeeId + " is not an Employee");
        }

        List<Evaluation> evaluations = evaluationRepository.findByEmployeeId(employeeId);
        return evaluations.stream()
                .map(evaluationService::mapToResponse)
                .collect(Collectors.toList());
    }
}
