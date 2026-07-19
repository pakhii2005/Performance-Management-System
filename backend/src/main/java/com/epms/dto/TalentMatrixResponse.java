package com.epms.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TalentMatrixResponse {
    private String employeeName;
    private String department;
    private String managerName;
    private Integer performanceRating;
    private Integer potentialRating;
    private String reviewCycle;
}
