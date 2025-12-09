
# 📊 Comfort Food Choices Analysis

A multi-tool data analytics project using Python, SQL, Excel, and Power BI

# 📁 Project Overview

This project analyzes survey responses about comfort food choices, health perception, calorie awareness, and demographic variables.
The goal is to understand misalignment between perceived and actual health awareness, explore key predictors of health-related behaviors, and demonstrate full-stack analytics skills across the data workflow.

The project includes:

- Data cleaning (Excel, Python)

- SQL analysis (joins, CTEs, views, aggregations)

- Python analytics (regressions, scoring systems, visualizations)

- Power BI report (interactive dashboards)

# 🛠 Tools & Technologies

**Python:** pandas, numpy, statsmodels, matplotlib

**SQL:** joins, CTEs, temp tables, views

**Excel:** initial cleaning, preprocessing

**Power BI:** final dashboard & storytelling

**Git / GitHub:** version control and workflow

# 📑 Key Features

**1. Custom Scoring Metrics**

To evaluate perception accuracy and awareness:

- Weight Perception Score
    
    Measures misalignment between perceived weight category and normalized distribution of actual weight.

- Calorie Awareness Score
    
    Based on correctness when estimating calories for 5 items; categorized as:

    - Aware

    - Moderately aware

    - Unaware

- Misalignment Score
    
    Absolute difference between perception and awareness scores. higher score = greater discrepancy.

**2. Python Analytics**

Includes:

- Missing value handling

- Categorical encoding

- Correlation heatmaps

- Two OLS regressions with predictors like:

    - gender

    - calorie awareness

    - misalignment score

    - income (low/mid/high)

    - vitamins, sports, employment

    - healthy feeling

    - marital status

**3. SQL Data Exploration**

SQL scripts include:

- Data filtering & cleaning

- Global/US subgroup analysis

- Complex joins

- CTEs

- Temp tables

- Views for dashboard-ready datasets

**4. Power BI Dashboard**

Final dashboard includes:

- Categorical breakdowns

- Awareness/Perception comparison visuals

- Demographic analysis

- Navigation buttons & layout

- Cleaned data model based on exported Excel

# 🚀 How to Run the Project
Python
-     pip install -r requirements.txt


Run notebooks in notebooks/.

**SQL**

SQL Server is recommended for full compatibility.

Scripts are written using T-SQL and stored in the sql/ folder.

**Power BI**

Open the .pbix file in Power BI Desktop.

# 📈 Results & Insights

A more detailed findings section is included in the dashboard, but examples of findings include:

- Distinct patterns in calorie awareness across demographic groups, with higher-income participants (especially females) showing stronger nutritional accuracy.

- Clear gender-specific links between weight perception accuracy and calorie awareness, with males showing higher variability and females displaying more stable patterns.

- Meaningful connections between perception–awareness alignment and wellbeing, revealing opposite trends for males and females in life rewarding scores.

- Consistent comfort-food preferences across genders, with females leaning toward sweet items and males toward salty snacks.

- Polarized distributions in subjective wellbeing, highlighting strong “all-or-none” response tendencies in life rewarding and healthy feeling measures.

# 📬 Contact

If you'd like feedback or suggestions, feel free to reach out through GitHub or open an issue.

# 📁 Data Source

This project uses the “Food choices” dataset, publicly available on Kaggle:

- [Food Choices Dataset](https://www.kaggle.com/datasets/borapajo/food-choices/data?select=food_coded.csv)