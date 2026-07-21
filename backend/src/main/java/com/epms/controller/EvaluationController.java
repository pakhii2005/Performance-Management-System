package com.epms.controller;

import com.epms.dto.EvaluationRequest;
import com.epms.dto.EvaluationResponse;
import com.epms.service.EvaluationService;
import org.springframework.security.access.prepost.PreAuthorize;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/evaluations")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class EvaluationController {

    private final EvaluationService evaluationService;

    @PostMapping
    @PreAuthorize("hasRole('CEO') or (hasRole('MANAGER') and @securityService.isSelf(principal.username, #request.managerId) and @securityService.isManagerOf(principal.username, #request.employeeId))")
    public ResponseEntity<EvaluationResponse> createEvaluation(@Valid @RequestBody EvaluationRequest request) {
        EvaluationResponse response = evaluationService.save(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<List<EvaluationResponse>> getAllEvaluations() {
        List<EvaluationResponse> evaluations = evaluationService.findAll();
        return ResponseEntity.ok(evaluations);
    }
}
