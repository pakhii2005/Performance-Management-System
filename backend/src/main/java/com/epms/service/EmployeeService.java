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

import com.epms.dto.PerformanceRadarResponse;
import java.util.List;
import java.util.Map;
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

    /**
     * Retrieves competency radar data points for this employee.
     */
    public List<PerformanceRadarResponse> getEmployeePerformanceRadar(Long employeeId) {
        User user = userRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));

        if (user.getRole() != Role.EMPLOYEE) {
            throw new ResourceNotFoundException("User with ID " + employeeId + " is not an Employee");
        }

        List<Evaluation> evaluations = evaluationRepository.findByEmployeeId(employeeId);
        return evaluations.stream().map(eval -> {
            Map<String, Integer> competencyScores = Map.of(
                "Communication", eval.getCommunicationScore() != null ? eval.getCommunicationScore() : 0,
                "Technical Skills", eval.getTechnicalSkillScore() != null ? eval.getTechnicalSkillScore() : 0,
                "Problem Solving", eval.getProblemSolvingScore() != null ? eval.getProblemSolvingScore() : 0,
                "Leadership", eval.getLeadershipScore() != null ? eval.getLeadershipScore() : 0,
                "Teamwork", eval.getTeamworkScore() != null ? eval.getTeamworkScore() : 0,
                "Adaptability", eval.getAdaptabilityScore() != null ? eval.getAdaptabilityScore() : 0,
                "Customer Focus", eval.getCustomerFocusScore() != null ? eval.getCustomerFocusScore() : 0,
                "Innovation", eval.getInnovationScore() != null ? eval.getInnovationScore() : 0
            );
            return PerformanceRadarResponse.builder()
                .reviewCycle(eval.getReviewCycle().getTitle())
                .reviewCycleId(eval.getReviewCycle().getId())
                .competencyScores(competencyScores)
                .performanceRating(eval.getPerformanceRating())
                .potentialRating(eval.getPotentialRating())
                .managerComments(eval.getManagerComments())
                .reviewDate(eval.getSubmittedDate())
                .build();
        }).collect(Collectors.toList());
    }
}
