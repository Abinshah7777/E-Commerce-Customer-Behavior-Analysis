@echo off
title Running Automated Test Suite
echo ========================================================
echo Executing Automated Pipeline Unit Tests (tests/test_pipeline.R)...
echo ========================================================
Rscript tests/test_pipeline.R
echo.
pause

