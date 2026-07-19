package com.epms.controller;

import com.epms.dto.ReviewCycleRequest;
import com.epms.dto.ReviewCycleResponse;
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
    public ResponseEntity<ReviewCycleResponse> createReviewCycle(@Valid @RequestBody ReviewCycleRequest request) {
        ReviewCycleResponse response = reviewCycleService.save(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<List<ReviewCycleResponse>> getAllReviewCycles() {
        List<ReviewCycleResponse> cycles = reviewCycleService.findAll();
        return ResponseEntity.ok(cycles);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReviewCycleResponse> getReviewCycleById(@PathVariable Long id) {
        ReviewCycleResponse cycle = reviewCycleService.findById(id);
        return ResponseEntity.ok(cycle);
    }
}
