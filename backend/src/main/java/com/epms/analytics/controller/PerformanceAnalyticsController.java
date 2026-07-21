package com.epms.analytics.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import com.epms.analytics.dto.AnalyticsDTOs.*;
import com.epms.analytics.service.PerformanceStandardizationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PerformanceAnalyticsController {

    private final PerformanceStandardizationService standardizationService;

    @GetMapping("/company-summary")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<CompanySummaryResponse> getCompanySummary() {
        CompanySummaryResponse summary = standardizationService.getCompanySummary();
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/manager-calibration")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<List<ManagerCalibrationResponse>> getManagerCalibration() {
        List<ManagerCalibrationResponse> calibration = standardizationService.getManagerCalibration();
        return ResponseEntity.ok(calibration);
    }

    @GetMapping("/department-summary")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<List<DepartmentSummaryResponse>> getDepartmentSummary() {
        List<DepartmentSummaryResponse> departmentSummary = standardizationService.getDepartmentSummary();
        return ResponseEntity.ok(departmentSummary);
    }

    @GetMapping("/executive-insights")
    @PreAuthorize("hasRole('CEO')")
    public ResponseEntity<List<String>> getExecutiveInsights() {
        List<String> insights = standardizationService.getExecutiveInsights();
        return ResponseEntity.ok(insights);
    }
}
