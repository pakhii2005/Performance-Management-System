package com.epms.service;

import com.epms.dto.ReviewCycleRequest;
import com.epms.dto.ReviewCycleResponse;
import com.epms.entity.ReviewCycle;
import com.epms.exception.ResourceNotFoundException;
import com.epms.repository.ReviewCycleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewCycleService {

    private final ReviewCycleRepository reviewCycleRepository;

    @Transactional
    public ReviewCycleResponse save(ReviewCycleRequest request) {
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new IllegalArgumentException("End date cannot be before start date");
        }

        ReviewCycle cycle = ReviewCycle.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(request.getStatus())
                .build();

        ReviewCycle savedCycle = reviewCycleRepository.save(cycle);
        return mapToResponse(savedCycle);
    }

    public List<ReviewCycleResponse> findAll() {
        return reviewCycleRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public ReviewCycleResponse findById(Long id) {
        ReviewCycle cycle = reviewCycleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Review cycle not found with ID: " + id));
        return mapToResponse(cycle);
    }

    public ReviewCycleResponse mapToResponse(ReviewCycle cycle) {
        return ReviewCycleResponse.builder()
                .id(cycle.getId())
                .title(cycle.getTitle())
                .description(cycle.getDescription())
                .startDate(cycle.getStartDate())
                .endDate(cycle.getEndDate())
                .status(cycle.getStatus())
                .createdAt(cycle.getCreatedAt())
                .build();
    }
}
