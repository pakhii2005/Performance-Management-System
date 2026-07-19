package com.epms.service;

import com.epms.dto.TalentMatrixResponse;
import com.epms.dto.TeamAverageResponse;
import com.epms.entity.Evaluation;
import com.epms.repository.EvaluationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AnalyticsService {

    private final EvaluationRepository evaluationRepository;

    public List<TalentMatrixResponse> getTalentMatrix() {
        List<Evaluation> evaluations = evaluationRepository.findAll();
        return evaluations.stream()
                .map(eval -> TalentMatrixResponse.builder()
                        .employeeName(eval.getEmployee().getFirstName() + " " + eval.getEmployee().getLastName())
                        .department(eval.getEmployee().getDepartment())
                        .managerName(eval.getManager().getFirstName() + " " + eval.getManager().getLastName())
                        .performanceRating(eval.getPerformanceRating())
                        .potentialRating(eval.getPotentialRating())
                        .reviewCycle(eval.getReviewCycle().getTitle())
                        .build())
                .collect(Collectors.toList());
    }

    public TeamAverageResponse getTeamAverage(Long managerId) {
        List<Evaluation> evals = evaluationRepository.findByManagerId(managerId);
        
        double avgPerf = evals.stream()
                .mapToInt(Evaluation::getPerformanceRating)
                .average()
                .orElse(0.0);
                
        double avgPot = evals.stream()
                .mapToInt(Evaluation::getPotentialRating)
                .average()
                .orElse(0.0);
                
        long numEvaluated = evals.stream()
                .map(e -> e.getEmployee().getId())
                .distinct()
                .count();

        // Round averages to 1 decimal place
        avgPerf = Math.round(avgPerf * 10.0) / 10.0;
        avgPot = Math.round(avgPot * 10.0) / 10.0;

        return TeamAverageResponse.builder()
                .averagePerformance(avgPerf)
                .averagePotential(avgPot)
                .numberOfEmployeesEvaluated(numEvaluated)
                .build();
    }
}
