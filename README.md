# LaLiga-Player-Performance-Dashboard-2024-2025-

This project analyzes LaLiga player performance for the 2024–2025 season using advanced football metrics normalized per 90 minutes. The goal is to identify elite performers, over/underperformers, and player archetypes across attacking, creative, dribbling, passing, and defensive dimensions.

https://public.tableau.com/views/LaLigaPlayerPerformanceDashboard2024_2025_ver3-Copy/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link
### Data Sources

FBref (player-level statistics)
- Seasons: 2024–2025 (LaLiga)
  - Stats categories:
    - General
    - Shooting
    - Passing
    - Possession
    - Defensive

### Tools
- Python
- PostgreSQL + DBeaver
- Tableau

### Process
- Cleaned and standardized column names in Python
- Imported datasets into PostgreSQL
- Joined multiple stat tables into a single player-level table
- Created derived metrics (per 90 stats, efficiency measures)
- Exported final dataset for Tableau visualization

### DashBoard Highlights
- Top 10 Goal Contributors per 90
- Overperforming vs Underperforming Players (xG+xAG vs G+A)
- Elite Playmakers (GCA90 vs SCA90)
- Dribbling Efficiency (Take-On Volume vs Success Rate)
- Defensive Impact Profiles
- Ball Progression Analysis
- Minimum minutes played (default: 1000 minutes)
