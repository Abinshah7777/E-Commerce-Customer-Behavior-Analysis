@echo off
title E-Commerce Interactive Shiny Dashboard
echo ========================================================
echo Launching Interactive R Shiny Dashboard...
echo Open http://127.0.0.1:3838 in your web browser
echo Press Ctrl+C in this terminal to terminate the app.
echo ========================================================
Rscript -e "shiny::runApp('app', launch.browser = TRUE, port = 3838)"
pause

