package com.epms.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EvaluationRequest {

    @NotNull(message = "Employee ID is required")
    private Long employeeId;

    @NotNull(message = "Manager ID is required")
    private Long managerId;

    @NotNull(message = "Review cycle ID is required")
    private Long reviewCycleId;

    @NotNull(message = "Performance rating is required")
    @Min(value = 1, message = "Performance rating must be at least 1")
    @Max(value = 5, message = "Performance rating cannot exceed 5")
    private Integer performanceRating;

    @NotNull(message = "Potential rating is required")
    @Min(value = 1, message = "Potential rating must be at least 1")
    @Max(value = 5, message = "Potential rating cannot exceed 5")
    private Integer potentialRating;

    @Min(value = 1, message = "Communication score must be at least 1")
    @Max(value = 5, message = "Communication score cannot exceed 5")
    private Integer communicationScore;

    @Min(value = 1, message = "Technical skill score must be at least 1")
    @Max(value = 5, message = "Technical skill score cannot exceed 5")
    private Integer technicalSkillScore;

    @Min(value = 1, message = "Problem solving score must be at least 1")
    @Max(value = 5, message = "Problem solving score cannot exceed 5")
    private Integer problemSolvingScore;

    @Min(value = 1, message = "Leadership score must be at least 1")
    @Max(value = 5, message = "Leadership score cannot exceed 5")
    private Integer leadershipScore;

    @Min(value = 1, message = "Teamwork score must be at least 1")
    @Max(value = 5, message = "Teamwork score cannot exceed 5")
    private Integer teamworkScore;

    @Min(value = 1, message = "Adaptability score must be at least 1")
    @Max(value = 5, message = "Adaptability score cannot exceed 5")
    private Integer adaptabilityScore;

    @Min(value = 1, message = "Customer focus score must be at least 1")
    @Max(value = 5, message = "Customer focus score cannot exceed 5")
    private Integer customerFocusScore;

    @Min(value = 1, message = "Innovation score must be at least 1")
    @Max(value = 5, message = "Innovation score cannot exceed 5")
    private Integer innovationScore;

    private String managerComments;
}
