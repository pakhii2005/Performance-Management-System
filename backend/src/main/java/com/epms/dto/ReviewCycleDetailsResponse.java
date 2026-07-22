package com.epms.dto;

import com.epms.entity.ReviewCycleStatus;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewCycleDetailsResponse {

    private Long id;
    private String title;
    private String description;
    private LocalDate startDate;
    private LocalDate endDate;
    private ReviewCycleStatus status;
    private LocalDateTime createdAt;
    private Long managerId;
    private String managerName;

    // Summary metrics
    private Integer totalEmployees;
    private Integer reviewsCompleted;
    private Integer reviewsPending;
    private Integer selfAssessmentsPending;
    private Double completionPercentage;

    // List of employees with review status
    private List<EmployeeStatus> employees;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EmployeeStatus {
        private Long employeeId;
        private String firstName;
        private String lastName;
        private String email;
        private String department;
        private String reviewStatus;
    }
}
