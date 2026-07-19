package com.epms.service;

import com.epms.dto.ManagerMetricsResponse;
import com.epms.dto.TeamEmployeeResponse;
import com.epms.dto.EvaluationResponse;
import com.epms.entity.ReviewCycle;
import com.epms.entity.ReviewCycleStatus;
import com.epms.entity.Role;
import com.epms.entity.User;
import com.epms.entity.Evaluation;
import com.epms.repository.EvaluationRepository;
import com.epms.repository.ReviewCycleRepository;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ManagerService {

    private final UserRepository userRepository;
    private final ReviewCycleRepository reviewCycleRepository;
    private final EvaluationRepository evaluationRepository;
    private final EvaluationService evaluationService;

    /**
     * Retrieves direct report employees assigned to a manager and checks their current
     * active review cycle completion status (PENDING or COMPLETED).
     */
    public List<TeamEmployeeResponse> getTeamEmployees(Long managerId) {
        List<User> employees = userRepository.findByManagerIdAndRole(managerId, Role.EMPLOYEE);
        
        ReviewCycle activeCycle = reviewCycleRepository.findAll().stream()
                .filter(c -> c.getStatus() == ReviewCycleStatus.ACTIVE)
                .findFirst()
                .orElse(null);

        return employees.stream().map(emp -> {
            String status = "PENDING";
            if (activeCycle != null) {
                boolean evaluated = evaluationRepository.existsByEmployeeIdAndReviewCycleId(emp.getId(), activeCycle.getId());
                if (evaluated) {
                    status = "COMPLETED";
                }
            }
            return TeamEmployeeResponse.builder()
                    .id(emp.getId())
                    .firstName(emp.getFirstName())
                    .lastName(emp.getLastName())
                    .email(emp.getEmail())
                    .department(emp.getDepartment())
                    .reviewStatus(status)
                    .build();
        }).collect(Collectors.toList());
    }

    /**
     * Retrieves the evaluations submitted by a specific manager.
     */
    public List<EvaluationResponse> getSubmittedEvaluations(Long managerId) {
        List<Evaluation> evaluations = evaluationRepository.findByManagerId(managerId);
        return evaluations.stream()
                .map(evaluationService::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Computes dashboard metrics for a specific manager under the current active review cycle.
     */
    public ManagerMetricsResponse getMetrics(Long managerId) {
        long assignedEmployees = userRepository.findByManagerIdAndRole(managerId, Role.EMPLOYEE).size();
        
        ReviewCycle activeCycle = reviewCycleRepository.findAll().stream()
                .filter(c -> c.getStatus() == ReviewCycleStatus.ACTIVE)
                .findFirst()
                .orElse(null);

        String cycleTitle = activeCycle != null ? activeCycle.getTitle() : "No Active Cycle";
        long submittedCount = 0;
        
        if (activeCycle != null) {
            submittedCount = evaluationRepository.countByManagerIdAndReviewCycleId(managerId, activeCycle.getId());
        }

        long pendingCount = assignedEmployees - submittedCount;
        if (pendingCount < 0) pendingCount = 0;

        return ManagerMetricsResponse.builder()
                .assignedEmployees(assignedEmployees)
                .pendingEvaluations(pendingCount)
                .submittedEvaluations(submittedCount)
                .activeReviewCycleTitle(cycleTitle)
                .build();
    }
}
