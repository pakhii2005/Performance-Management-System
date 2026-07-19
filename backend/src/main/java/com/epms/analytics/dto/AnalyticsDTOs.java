package com.epms.analytics.dto;

import lombok.*;
import java.util.List;
import java.util.Map;

public class AnalyticsDTOs {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CompanySummaryResponse {
        private Double companyAveragePerformance;
        private Double companyAveragePotential;
        private Long totalManagers;
        private Long managersRequiringCalibration;
        private Double evaluationCompletionRate;
        private Double overallStandardizationScore;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ManagerCalibrationResponse {
        private String managerName;
        private String department;
        private Long employeesEvaluated;
        private Double averagePerformanceRating;
        private Double averagePotentialRating;
        private Double differenceFromCompanyAverage;
        private String calibrationStatus;
        private String consistencyStatus;
        private Integer standardizationScore;
        private String scoreStatus;
        private Map<Integer, Double> ratingDistribution; // 1 to 5 mapping to percentage
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DepartmentSummaryResponse {
        private String departmentName;
        private Double averagePerformance;
        private Double averagePotential;
        private Double completionRate;
        private Long employeesEvaluated;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ExecutiveInsightsResponse {
        private List<String> insights;
    }
}
