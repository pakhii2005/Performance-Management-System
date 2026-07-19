package com.epms.analytics.controller;

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
    public ResponseEntity<CompanySummaryResponse> getCompanySummary() {
        CompanySummaryResponse summary = standardizationService.getCompanySummary();
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/manager-calibration")
    public ResponseEntity<List<ManagerCalibrationResponse>> getManagerCalibration() {
        List<ManagerCalibrationResponse> calibration = standardizationService.getManagerCalibration();
        return ResponseEntity.ok(calibration);
    }

    @GetMapping("/department-summary")
    public ResponseEntity<List<DepartmentSummaryResponse>> getDepartmentSummary() {
        List<DepartmentSummaryResponse> departmentSummary = standardizationService.getDepartmentSummary();
        return ResponseEntity.ok(departmentSummary);
    }

    @GetMapping("/executive-insights")
    public ResponseEntity<List<String>> getExecutiveInsights() {
        List<String> insights = standardizationService.getExecutiveInsights();
        return ResponseEntity.ok(insights);
    }
}
