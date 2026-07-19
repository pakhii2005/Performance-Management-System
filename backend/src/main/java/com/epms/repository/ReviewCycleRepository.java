package com.epms.repository;

import com.epms.entity.ReviewCycle;
import com.epms.entity.ReviewCycleStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ReviewCycleRepository extends JpaRepository<ReviewCycle, Long> {
    long countByStatus(ReviewCycleStatus status);
}
