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
    private Integer communicationScore;
    private Integer technicalSkillScore;
    private Integer problemSolvingScore;
    private Integer leadershipScore;
    private Integer teamworkScore;
    private Integer adaptabilityScore;
    private Integer customerFocusScore;
    private Integer innovationScore;
    private String managerComments;
    private LocalDateTime submittedDate;
}
