package com.epms.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import com.epms.dto.ReviewCycleRequest;
import com.epms.dto.ReviewCycleResponse;
import com.epms.dto.ReviewCycleDetailsResponse;
import com.epms.service.ReviewCycleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/review-cycles")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ReviewCycleController {

    private final ReviewCycleService reviewCycleService;

    @PostMapping
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<ReviewCycleResponse> createReviewCycle(@Valid @RequestBody ReviewCycleRequest request) {
        ReviewCycleResponse response = reviewCycleService.save(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('CEO', 'MANAGER', 'EMPLOYEE')")
    public ResponseEntity<List<ReviewCycleResponse>> getAllReviewCycles() {
        List<ReviewCycleResponse> cycles = reviewCycleService.findAll();
        return ResponseEntity.ok(cycles);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CEO', 'MANAGER', 'EMPLOYEE')")
    public ResponseEntity<ReviewCycleResponse> getReviewCycleById(@PathVariable Long id) {
        ReviewCycleResponse cycle = reviewCycleService.findById(id);
        return ResponseEntity.ok(cycle);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<ReviewCycleResponse> updateReviewCycle(@PathVariable Long id, @Valid @RequestBody ReviewCycleRequest request) {
        ReviewCycleResponse response = reviewCycleService.update(id, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}/details")
    @PreAuthorize("hasAnyRole('CEO', 'MANAGER')")
    public ResponseEntity<ReviewCycleDetailsResponse> getReviewCycleDetails(@PathVariable Long id) {
        ReviewCycleDetailsResponse details = reviewCycleService.getDetails(id);
        return ResponseEntity.ok(details);
    }
}
