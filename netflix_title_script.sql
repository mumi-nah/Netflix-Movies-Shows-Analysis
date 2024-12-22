SELECT * FROM netflix_title;

--how many movies and TV shows are there in the dataset?. Display the count for each type.
SELECT type, COUNT(*)
FROM netflix_title
GROUP BY type;

--what percentage of content doesn't have a country associated with it?
SELECT (no_country*100 / total_content) AS no_country_percentage
FROM
    (SELECT COUNT(*) AS total_content FROM netflix_title) total,
    (SELECT COUNT(*) AS no_country
    FROM netflix_title
    WHERE country IS NULL OR country = '') no_country_count;
	
--find the top 3 directors with the most content on Netflix. 
--Display the director's name, the count of their titles, and the year of their most recent content 
SELECT director,
       count(*) AS content_count,
	   MAX(release_year) AS most_recent_year
FROM netflix_title
WHERE director IS NOT NULL
GROUP BY director
ORDER BY content_count DESC
LIMIT 3;

--for each year from 2015 to 2021, calculate the percentage of movies vs TV shows added to Netflix.
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

--Calculate the average month-over-month grow rate of content added to Netflix for each genre. What are the top 5 fastest-growing genres?
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