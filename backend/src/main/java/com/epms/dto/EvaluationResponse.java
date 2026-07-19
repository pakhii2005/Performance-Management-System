package com.epms.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EvaluationResponse {

    private Long id;
    private Long employeeId;
    private String employeeName;
    private Long managerId;
    private String managerName;
    private Long reviewCycleId;
    private String reviewCycleTitle;
    private Integer performanceRating;
    private Integer potentialRating;
    private String managerComments;
    private LocalDateTime submittedDate;
}
