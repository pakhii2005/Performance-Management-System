package com.epms.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "evaluations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Evaluation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private User employee;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manager_id", nullable = false)
    private User manager;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "review_cycle_id", nullable = false)
    private ReviewCycle reviewCycle;

    @Column(nullable = false)
    private Integer performanceRating;

    @Column(nullable = false)
    private Integer potentialRating;

    @Column
    private Integer communicationScore;

    @Column
    private Integer technicalSkillScore;

    @Column
    private Integer problemSolvingScore;

    @Column
    private Integer leadershipScore;

    @Column
    private Integer teamworkScore;

    @Column
    private Integer adaptabilityScore;

    @Column
    private Integer customerFocusScore;

    @Column
    private Integer innovationScore;

    @Column(length = 2000)
    private String managerComments;

    @Column(nullable = false, updatable = false)
    private LocalDateTime submittedDate;

    @PrePersist
    protected void onSubmit() {
        submittedDate = LocalDateTime.now();
    }
}
