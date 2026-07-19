package com.epms.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardMetricsResponse {
    private long totalEmployees;
    private long totalManagers;
    private long activeReviewCycles;
    private long submittedEvaluations;
}
