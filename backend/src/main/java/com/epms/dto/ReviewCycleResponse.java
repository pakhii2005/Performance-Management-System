package com.epms.dto;

import com.epms.entity.ReviewCycleStatus;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewCycleResponse {

    private Long id;
    private String title;
    private String description;
    private LocalDate startDate;
    private LocalDate endDate;
    private ReviewCycleStatus status;
    private LocalDateTime createdAt;
}
