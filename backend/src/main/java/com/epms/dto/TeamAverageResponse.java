package com.epms.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeamAverageResponse {
    private Double averagePerformance;
    private Double averagePotential;
    private Long numberOfEmployeesEvaluated;
}
