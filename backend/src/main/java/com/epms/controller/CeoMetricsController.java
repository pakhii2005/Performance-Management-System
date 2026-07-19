package com.epms.controller;

import com.epms.dto.DashboardMetricsResponse;
import com.epms.entity.ReviewCycleStatus;
import com.epms.entity.Role;
import com.epms.repository.EvaluationRepository;
import com.epms.repository.ReviewCycleRepository;
import com.epms.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ceo")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CeoMetricsController {

    private final UserRepository userRepository;
    private final ReviewCycleRepository reviewCycleRepository;
    private final EvaluationRepository evaluationRepository;

    @GetMapping("/metrics")
    public ResponseEntity<DashboardMetricsResponse> getMetrics() {
        long totalEmployees = userRepository.countByRole(Role.EMPLOYEE);
        long totalManagers = userRepository.countByRole(Role.MANAGER);
        long activeCycles = reviewCycleRepository.countByStatus(ReviewCycleStatus.ACTIVE);
        long submittedEvaluations = evaluationRepository.count();

        DashboardMetricsResponse metrics = DashboardMetricsResponse.builder()
                .totalEmployees(totalEmployees)
                .totalManagers(totalManagers)
                .activeReviewCycles(activeCycles)
                .submittedEvaluations(submittedEvaluations)
                .build();

        return ResponseEntity.ok(metrics);
    }
}
