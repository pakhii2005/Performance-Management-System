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

    private String managerComments;
}
