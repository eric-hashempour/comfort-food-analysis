

SELECT *
FROM dbo.food_coded_cleaned

SELECT *
FROM dbo.comfort_food_frequency_table

/*******************************************************************************************
-- Weight Perception Accuracy Analysis
--
-- Objective:
-- Analyze the alignment between self-perceived weight and actual weight category
-- using percentile-based classification by gender.
--
-- Steps:
-- 1. Calculate weight percentiles (25th, 75th, 90th) by gender.
-- 2. Map self-perceived weight descriptions to generalized categories.
-- 3. Categorize actual weight based on percentile cutoffs for each gender.
-- 4. Assign numeric scores to perceived and actual categories for comparison.
-- 5. Classify individuals as 'Very Close', 'Close', or 'Far Off' based on perception accuracy.
--
-- Output includes:
-- - Participant ID, weight, gender, and self-perception.
-- - Mapped perceived and actual weight categories.
-- - Perception accuracy level.
-- - Selected behavioral and lifestyle columns for further analysis.
*******************************************************************************************/

-- Step 1: Calculate gender-specific weight percentiles

IF OBJECT_ID('dbo.view_perception_accuracy', 'V') IS NOT NULL
    DROP VIEW view_perception_accuracy;
GO

CREATE VIEW view_perception_accuracy AS
WITH percentiles AS (
	SELECT DISTINCT
		Gender,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY weight) OVER (PARTITION BY Gender) AS p25,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY weight) OVER (PARTITION BY Gender) AS p75,
		PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY weight) OVER (PARTITION BY Gender) AS p90
	FROM dbo.food_coded_cleaned
),

-- Step 2 & 3: Categorize perceived and actual weight
categorized AS (
	SELECT
		f.ID,
		f.self_perception_weight,
		
		-- Map perception text to category
		CASE 
			WHEN LOWER(f.self_perception_weight) = 'slim' THEN 'Underweight'
			WHEN LOWER(f.self_perception_weight) IN ('very fit', 'just right') THEN 'Normal'
			WHEN LOWER(f.self_perception_weight) = 'slightly overweight' THEN 'Overweight'
			WHEN LOWER(f.self_perception_weight) = 'overweight' THEN 'Obese'
			ELSE NULL
		END AS perceived_category,

		-- Actual category based on gender-specific percentiles
		CASE 
			WHEN f.weight < p.p25 THEN 'Underweight'
			WHEN f.weight < p.p75 THEN 'Normal'
			WHEN f.weight < p.p90 THEN 'Overweight'
			ELSE 'Obese'
		END AS actual_category

	FROM dbo.food_coded_cleaned f
	JOIN percentiles p ON f.gender = p.gender
),

-- Step 4: Assign numeric scores for category comparison
comparison AS (
	SELECT
		ID,
		perceived_category,
		actual_category,

		-- Convert perceived category to numeric scale
		CASE perceived_category
			WHEN 'Underweight' THEN 1
			WHEN 'Normal' THEN 2
			WHEN 'Overweight' THEN 3
			WHEN 'Obese' THEN 4
			ELSE NULL
		END AS perceived_score,

		-- Convert actual category to numeric scale
		CASE actual_category
			WHEN 'Underweight' THEN 1
			WHEN 'Normal' THEN 2
			WHEN 'Overweight' THEN 3
			WHEN 'Obese' THEN 4
			ELSE NULL
		END AS actual_score
	FROM categorized
)

-- Step 5: Final Output - Join comparison with base data and calculate perception accuracy
SELECT
	f.ID,
	f.weight,
	f.gender,
	f.self_perception_weight,
	c.perceived_category,
	c.actual_category,

	-- Evaluate how accurate perception is
	CASE 
		WHEN c.perceived_score IS NULL THEN 'Unspecified'
		WHEN ABS(c.perceived_score - c.actual_score) = 0 THEN 'Very Close'
		WHEN ABS(c.perceived_score - c.actual_score) = 1 THEN 'Close'
		ELSE 'Far Off'
	END AS perception_accuracy,

	-- Behavioral and contextual columns for further analysis
	f.calories_day,
	f.eating_out,
	f.cook,
	f.exercise,
	f.fav_food,
	f.fruit_day,
	f.healthy_feeling,
	f.income,
	f.parents_cook,
	f.sports

FROM dbo.food_coded_cleaned f
JOIN comparison c 
	ON f.ID = c.ID
WHERE f.weight IS NOT NULL;


SELECT *
FROM dbo.view_perception_accuracy;

-- ========================================
-- Calory Guess Awareness Analysis
-- ========================================
-- This script evaluates how accurately respondents estimated calorie content
-- for five specific food items, using predefined "actual" calorie values.
-- It assigns awareness levels based on a scoring rubric.

-- Scoring Criteria Per Food Item Guess:
-- -------------------------------------
-- Very Close  = Exact match to actual value → 3 points
-- Close       = Within 225 calories (inclusive) of actual value → 2 points
-- Off         = Within 325 calories (inclusive) but >225 → 1 point
-- Way Off     = More than 325 calories off → 0 points

-- Awareness Level Categorization Based on Total Score (Max = 15):
-- ---------------------------------------------------------------
-- 13 to 15 → Very Aware
-- 10 to 12 → Aware
-- 7 to 9   → Somewhat Aware
-- 0 to 6   → Unaware

-- ========================================
-- CTE: Calculate Calorie Awareness Score
-- ========================================

IF OBJECT_ID('dbo.view_calory_awareness ', 'V') IS NOT NULL
    DROP VIEW dbo.view_calory_awareness ;
GO

CREATE VIEW view_calory_awareness AS
WITH Calory_Awareness AS (
  SELECT
    ID,
    Gender,
    calories_chicken,
    calories_scone,
    tortilla_calories,
    turkey_calories,
    waffle_calories,
    calories_day,
    diet_current_coded,
    eating_out,
    exercise,
	eating_changes_coded,
	employment,
	grade_level,
	healthy_feeling,
	income,
	marital_status,
	sports,
	vitamins,
	life_rewarding,

    -- Calculate a composite awareness score across 5 food items
    (
      -- Chicken Wrap (Actual: 610)
      CASE WHEN ABS(calories_chicken - 610) = 0 THEN 3
           WHEN ABS(calories_chicken - 610) <= 225 THEN 2
           WHEN ABS(calories_chicken - 610) <= 325 THEN 1
           ELSE 0
      END +

      -- Scone (Actual: 420)
      CASE WHEN ABS(calories_scone - 420) = 0 THEN 3
           WHEN ABS(calories_scone - 420) <= 225 THEN 2
           WHEN ABS(calories_scone - 420) <= 325 THEN 1
           ELSE 0
      END +

      -- Tortilla (Actual: 940)
      CASE WHEN ABS(tortilla_calories - 940) = 0 THEN 3
           WHEN ABS(tortilla_calories - 940) <= 225 THEN 2
           WHEN ABS(tortilla_calories - 940) <= 325 THEN 1
           ELSE 0
      END +

      -- Turkey Sandwich (Actual: 690)
      CASE WHEN ABS(turkey_calories - 690) = 0 THEN 3
           WHEN ABS(turkey_calories - 690) <= 225 THEN 2
           WHEN ABS(turkey_calories - 690) <= 325 THEN 1
           ELSE 0
      END +

      -- Waffle (Actual: 900)
      CASE WHEN ABS(waffle_calories - 900) = 0 THEN 3
           WHEN ABS(waffle_calories - 900) <= 225 THEN 2
           WHEN ABS(waffle_calories - 900) <= 325 THEN 1
           ELSE 0
      END
    ) AS calorie_awareness_score

  FROM dbo.food_coded_cleaned
)

-- ========================================
-- Final Output with Categorization
-- ========================================

SELECT 
  ID,
  Gender,

  -- Original guesses and their proximity interpretation
  calories_chicken,
  CASE 
    WHEN ABS(calories_chicken - 610) = 0 THEN 'Very Close'
    WHEN ABS(calories_chicken - 610) <= 225 THEN 'Close'
    WHEN ABS(calories_chicken - 610) <= 325 THEN 'Off'
    ELSE 'Way Off'
  END AS guess_to_actual_chicken,

  calories_scone,
  CASE 
    WHEN ABS(calories_scone - 420) = 0 THEN 'Very Close'
    WHEN ABS(calories_scone - 420) <= 225 THEN 'Close'
    WHEN ABS(calories_scone - 420) <= 325 THEN 'Off'
    ELSE 'Way Off'
  END AS guess_to_actual_scone,

  tortilla_calories,
  CASE 
    WHEN ABS(tortilla_calories - 940) = 0 THEN 'Very Close'
    WHEN ABS(tortilla_calories - 940) <= 225 THEN 'Close'
    WHEN ABS(tortilla_calories - 940) <= 325 THEN 'Off'
    ELSE 'Way Off'
  END AS guess_to_actual_tortilla,

  turkey_calories,
  CASE 
    WHEN ABS(turkey_calories - 690) = 0 THEN 'Very Close'
    WHEN ABS(turkey_calories - 690) <= 225 THEN 'Close'
    WHEN ABS(turkey_calories - 690) <= 325 THEN 'Off'
    ELSE 'Way Off'
  END AS guess_to_actual_turkey,

  waffle_calories,
  CASE 
    WHEN ABS(waffle_calories - 900) = 0 THEN 'Very Close'
    WHEN ABS(waffle_calories - 900) <= 225 THEN 'Close'
    WHEN ABS(waffle_calories - 900) <= 325 THEN 'Off'
    ELSE 'Way Off'
  END AS guess_to_actual_waffle,
  calorie_awareness_score,
  -- Final Awareness Level Based on Total Score
  CASE 
    WHEN calorie_awareness_score >= 13 THEN 'Very Aware'
    WHEN calorie_awareness_score >= 10 THEN 'Aware'
    WHEN calorie_awareness_score >= 7 THEN 'Somewhat Aware'
    ELSE 'Unaware'
  END AS awareness_level,

  -- Other Participant Variables
  calories_day,
  diet_current_coded,
  eating_out,
  exercise,
  eating_changes_coded,
  employment,
  grade_level,
  healthy_feeling,
  income,
  marital_status,
  sports,
  vitamins,
  life_rewarding

FROM Calory_Awareness;


SELECT *
FROM dbo.view_calory_awareness;



/*******************************************************************************************
-- View: dbo.view_behavioral_insight_analysis
-- Purpose:
-- Combines data on calorie awareness and weight perception accuracy per individual
-- to explore behavioral insight patterns by gender and income.

-- Key Questions Answered:
-- 1. Are people who guess their calorie intake more accurately also more accurate about their weight?
-- 2. Does awareness scores differ significantly across genders or income brackets?
*******************************************************************************************/

IF OBJECT_ID('dbo.view_behavioral_insight_analysis', 'V') IS NOT NULL
    DROP VIEW dbo.view_behavioral_insight_analysis;
GO

CREATE VIEW view_behavioral_insight_analysis AS
SELECT
    pa.ID,
    pa.Gender,
    pa.weight,
    pa.self_perception_weight,
    pa.perceived_category,
    pa.actual_category,
    pa.perception_accuracy,
    ca.calorie_awareness_score,
    ca.awareness_level,
    ca.calories_day,
    pa.income,
	ca.eating_changes_coded,
    ca.employment,
    ca.grade_level,
    ca.healthy_feeling,
    ca.marital_status,
	ca.sports,
	ca.vitamins,
	ca.life_rewarding
FROM dbo.view_calory_awareness ca
JOIN dbo.view_perception_accuracy pa 
    ON ca.ID = pa.ID;  -- Align both views on participant ID to merge calorie and perception data

-- Preview merged behavioral insights
SELECT *
FROM view_behavioral_insight_analysis;



/*******************************************************************************************
-- Purpose:
-- Analyze perception accuracy and calorie awareness scores by gender.
-- Filters out unspecified perceptions, calculates count and average awareness per accuracy 
-- bracket, compares each bracket's average to the gender-wide average, and assigns a
-- custom sort order to perception categories for consistent output ordering.
*******************************************************************************************/


SELECT 
    Gender, 
	perception_accuracy,
	COUNT(*) AS people_count,
	ROUND(AVG(CAST(calorie_awareness_score AS FLOAT)), 2) AS avg_awareness_bracket,
	ROUND(AVG(AVG(CAST(calorie_awareness_score AS FLOAT))) OVER (PARTITION BY Gender), 2) AS gender_avg_awareness,
	CASE perception_accuracy
		WHEN 'Very Close' THEN 1
		WHEN 'Close' THEN 2
		WHEN 'Far Off' THEN 3
		ELSE 4
	END AS perception_accuracy_order
FROM dbo.view_behavioral_insight_analysis
WHERE perception_accuracy <> 'Unspecified'
GROUP BY Gender, perception_accuracy
ORDER BY Gender, perception_accuracy_order;


/*******************************************************************************************
-- Purpose:
-- Analyze calorie awareness scores across income brackets.
-- Filters out null or empty income values, computes average awareness per bracket,
-- and assigns a custom numeric order to income ranges for proper sorting.
*******************************************************************************************/

SELECT 
    income,
	COUNT(*) AS people_count,
	ROUND(AVG(CAST(calorie_awareness_score AS FLOAT)), 2) AS avg_awareness_bracket,
	CASE income
		WHEN 'Less than $15,000' THEN 1
		WHEN '$15,001 to $30,000' THEN 2
		WHEN '$30,001 to $50,000' THEN 3
		WHEN '$50,001 to $70,000' THEN 4
		WHEN '$70,001 to $100,000' THEN 5
		WHEN 'More than $100,000' THEN 6
	END AS income_order
FROM dbo.view_behavioral_insight_analysis
WHERE income IS NOT NULL AND TRIM(income) <> ''
GROUP BY income
ORDER BY income_order;



/*******************************************************************************************
-- Purpose:
-- Analyze alignment between calorie awareness level and weight perception accuracy by 
-- quantifying score differences and categorizing misalignment severity.
*******************************************************************************************/

IF OBJECT_ID('dbo.view_alignment', 'V') IS NOT NULL
    DROP VIEW dbo.view_alignment;
GO

CREATE VIEW dbo.view_alignment AS
WITH scored_data AS (
  SELECT *,
    -- Map awareness_level to numeric score for comparison
    CASE awareness_level
      WHEN 'Very Aware' THEN 3
      WHEN 'Aware' THEN 2
      WHEN 'Somewhat Aware' THEN 1
      ELSE 0
    END AS awareness_level_score,
    
    -- Map perception_accuracy to numeric score for comparison
    CASE perception_accuracy
      WHEN 'Very Close' THEN 3
      WHEN 'Close' THEN 2
      WHEN 'Far Off' THEN 1
      ELSE 0
    END AS perception_level_score
  FROM dbo.view_behavioral_insight_analysis
),
scored_with_difference AS (
  SELECT *,
    -- Calculate absolute difference between awareness and perception scores
    ABS(awareness_level_score - perception_level_score) AS score_difference
  FROM scored_data
)
SELECT *,
  -- Categorize the degree of alignment/misalignment
  CASE 
    WHEN score_difference = 0 THEN 'Perfectly Aligned'
    WHEN score_difference = 1 THEN 'Slight Misalignment'
    WHEN score_difference = 2 THEN 'Moderate Misalignment'
    ELSE 'Severe Misalignment'
  END AS alignment_level
FROM scored_with_difference
-- Exclude entries without a valid perceived category
WHERE perceived_category IS NOT NULL;

-- Check results
SELECT * FROM dbo.view_alignment;



/*******************************************************************************************
-- Purpose:
-- Calculate participant distribution by alignment level of calorie awareness vs perception,
-- segmented by gender, including relative portion per gender group.
*******************************************************************************************/

WITH total_participant AS (
    SELECT 
        Gender,
        alignment_level,
        COUNT(*) AS participant_count,
        -- Numeric order for alignment levels for sorting
        CASE alignment_level
            WHEN 'Perfectly Aligned' THEN 1
            WHEN 'Slight Misalignment' THEN 2
            WHEN 'Moderate Misalignment' THEN 3
            WHEN 'Severe Misalignment' THEN 4
        END AS alignment_order
    FROM view_alignment
    GROUP BY Gender, alignment_level	
)

SELECT 
    Gender,
    alignment_level,
    participant_count,
    -- Total participants within each gender
    SUM(participant_count) OVER (PARTITION BY Gender) AS total_gender_participant_count,
    -- Portion of participants per alignment level within each gender, rounded to 2 decimals
    ROUND(CAST(participant_count AS FLOAT) / SUM(participant_count) OVER (PARTITION BY Gender), 2) AS portion_to_gender_total
FROM total_participant
ORDER BY Gender, alignment_order;


/*******************************************************************************************
-- Purpose:
-- Analyze the popularity of mapped comfort foods by gender (Aggregate).
-- Counts how often each comfort food appears, filters out blanks,
-- ranks them within each gender group using DENSE_RANK based on frequency.
*******************************************************************************************/

IF OBJECT_ID('dbo.comfort_food_frequency_table_by_gender ', 'V') IS NOT NULL
    DROP VIEW dbo.comfort_food_frequency_table_by_gender ;
GO

CREATE VIEW dbo.comfort_food_frequency_table_by_gender AS
SELECT 
	c.Gender,
	c.comfort_food_mapped,
	COUNT(c.comfort_food_mapped) AS comfort_food_count,
	ROUND(AVG(f.healthy_feeling), 2) AS average_healthy_feeling,
	DENSE_RANK() OVER (PARTITION BY c.Gender ORDER BY COUNT(c.comfort_food_mapped) DESC) AS comfort_food_rank
FROM dbo.comfort_food_frequency_table c
JOIN dbo.food_coded_cleaned f
	On c.ID = f.ID
WHERE c.comfort_food_mapped <> ''
GROUP BY c.Gender, c.comfort_food_mapped;


SELECT *
FROM dbo.comfort_food_frequency_table_by_gender;


/*******************************************************************************************
-- Purpose:
-- Non-Aggregate version of comfort_food_frequency_table_by_gender view with emphasis 
-- On income
*******************************************************************************************/


IF OBJECT_ID('dbo.comfort_food_detailed', 'V') IS NOT NULL
    DROP VIEW dbo.comfort_food_detailed ;
GO

CREATE VIEW dbo.comfort_food_detailed AS
SELECT
    f.ID,
    f.Gender,
	c.comfort_food,
    c.comfort_food_mapped,
    f.income,
    CASE 
        WHEN f.income IN ('Less than $15,000', '$15,001 to $30,000') THEN 'Low'
        WHEN f.income IN ('$30,001 to $50,000', '$50,001 to $70,000') THEN 'Mid'
        WHEN f.income IN ('$70,001 to $100,000', 'More than $100,000') THEN 'High'
    END AS income_group,
    f.healthy_feeling
FROM dbo.food_coded_cleaned AS f
JOIN dbo.comfort_food_frequency_table AS c
    ON f.ID = c.ID
WHERE c.comfort_food_mapped <> '';


SELECT * 
FROM dbo.comfort_food_detailed;