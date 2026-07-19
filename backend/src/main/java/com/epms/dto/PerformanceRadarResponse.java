package com.epms.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PerformanceRadarResponse {
    private String reviewCycle;
    private Long reviewCycleId;
    private Map<String, Integer> competencyScores;
    private Integer performanceRating;
    private Integer potentialRating;
    private String managerComments;
    private LocalDateTime reviewDate;
}
