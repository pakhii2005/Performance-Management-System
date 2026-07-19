package com.epms.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ManagerMetricsResponse {
    private long assignedEmployees;
    private long pendingEvaluations;
    private long submittedEvaluations;
    private String activeReviewCycleTitle;
}
