package com.epms.repository;

import com.epms.entity.Evaluation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EvaluationRepository extends JpaRepository<Evaluation, Long> {
    List<Evaluation> findByManagerId(Long managerId);
    List<Evaluation> findByEmployeeId(Long employeeId);
    boolean existsByEmployeeIdAndReviewCycleId(Long employeeId, Long reviewCycleId);
    long countByManagerIdAndReviewCycleId(Long managerId, Long reviewCycleId);
}
