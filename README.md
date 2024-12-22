# Netflix-Movies &-Shows-Analysis

## Project Overview
This project involves analyzing the Netflix Movies and Shows dataset using PostgreSQL to answer various business-related questions. The dataset provides comprehensive information about movies and TV shows available on Netflix, including their genres, release dates, and countries of origin. The goal is to uncover insights and demonstrate SQL proficiency.

## Dataset 
Source: Publicly available Netflix Movies and Shows dataset

Columns: There are 12 columns in the dataset:
- show_id: A unique identifier for each title.
- type: The category of the title, which is either 'Movie' or 'TV Show'.
- title: The name of the movie or TV show.
- director: The director(s) of the movie or TV show. (Contains null values for some entries, especially TV shows where this information might not be applicable.)
- cast: The list of main actors/actresses in the title. (Some entries might not have this information.)
- country: The country or countries where the movie or TV show was produced.
- date_added: The date the title was added to Netflix.
- release_year: The year the movie or TV show was originally released.
- rating: The age rating of the title.
- duration: The duration of the title, in minutes for movies and seasons for TV shows.
- listed_in: The genres the title falls under.
- description: A brief summary of the title.
***

## Questions Answered
**1. How many movies and TV shows are there in the dataset? Display the count for each type.**
````sql
SELECT type, COUNT(*)
FROM netflix_title
GROUP BY type;
````
|Movie  | 6131 |

|TV Show|	2677 | 

**2. What percentage of content doesn’t have a country associated with it?**
````sql
SELECT (no_country*100 / total_content) AS no_country_percentage
FROM
    (SELECT COUNT(*) AS total_content FROM netflix_title) total,
    (SELECT COUNT(*) AS no_country
    FROM netflix_title
    WHERE country IS NULL OR country = '') no_country_count;
````

**3. Find the top 3 directors with the most content on Netflix. Display the director's name, the count of their titles, and the year of their most recent content.**
```sql
SELECT director,
       count(*) AS content_count,
	   MAX(release_year) AS most_recent_year
FROM netflix_title
WHERE director IS NOT NULL
GROUP BY director
ORDER BY content_count DESC
LIMIT 3;
````

**4. For each year from 2015 to 2021, calculate the percentage of movies vs TV shows added to Netflix.**
````sql
WITH percentage_stat AS(
SELECT 
    EXTRACT(YEAR FROM date_added) AS year_added,
	COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movie_count,
	COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tvShow_count,
	count(*) AS total_count
FROM netflix_title
WHERE date_added BETWEEN '2015-01-01' AND '2021-12-31'
GROUP BY year_added
ORDER BY year_added)

SELECT year_added,
       (movie_count *100 / total_count) AS movie_percentage,
	   (tvShow_count *100 / total_count) AS tvShow_percentage
FROM percentage_stat;	   
````

**5. Calculate the average month-over-month growth rate of content added to Netflix for each genre. What are the top 5 fastest-growing genres?**
````sql
WITH month_genre AS(
SELECT 
    DATE_TRUNC('month', date_added)::DATE AS month,
	TRIM(UNNEST(STRING_TO_ARRAY(listed_in, ','))) AS genre,
	COUNT(*) AS monthly_content
FROM netflix_title
GROUP BY 1, 2),

prev_month_count AS(
SELECT 
    month,
	genre,
	monthly_content,
	COALESCE(
		LAG(monthly_content) OVER(PARTITION BY genre ORDER BY month),1) AS prev_month_content
FROM month_genre	
ORDER BY month),

growth_rate_cte AS(
SELECT 
    month,
	genre,
	monthly_content,
	prev_month_content,
	ROUND(((monthly_content - prev_month_content)::NUMERIC / prev_month_content), 2) AS growth_rate
FROM prev_month_count)

SELECT 
    genre,
	ROUND(AVG(growth_rate),2) AS avg_growth_rate
FROM growth_rate_cte
WHERE growth_rate IS NOT NULL
GROUP BY genre
ORDER BY avg_growth_rate DESC
LIMIT 5;
````
### Key Insights
- Netflix has more movies than TV Shows in its library
- There's no pattern associated with the addition of movies and TV Shows. i.e they are added randomly.
- About 98 percent of the genre has less than 1 percent month-over-month growth rate.

#### Tools Used
- Database: PostgreSQL
- Languages: SQL
- Dataset Source: https://lnkd.in/gpe8RMFb
