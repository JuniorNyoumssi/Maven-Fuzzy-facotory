SELECT * FROM mavenfuzzyfactory.website_sessions;

-- TASK : Identify where the bulk of the website sessions are coming from before 2012-04-12
-- Breaking it down by UTM source,campaign, and referring domain

USE mavenfuzzyfactory;

ALTER TABLE website_sessions
ADD created_date DATE;

ALTER TABLE website_sessions
ADD created_time  TIME;

UPDATE website_sessions
SET created_date =  DATE(created_at) ;

UPDATE website_sessions
SET created_time =  TIME(created_at) ;

SELECT utm_source,utm_campaign,http_referer,Count(website_session_id) as sessions
FROM website_sessions
WHERE created_date < '2012-04-12'
Group by utm_source, utm_campaign ,http_referer ;

-- TASK : Calculate the coversion rate (CVR) from session to order from the major traffic source
SELECT COUNT(DISTINCT(website_sessions.website_session_id)) as sessions,
       COUNT(DISTINCT(orders.order_id)) as orders,
       COUNT(orders.order_id)/ COUNT(website_sessions.website_session_id) as
       session_to_order_conv_rate
FROM website_sessions
LEFT JOIN orders on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-04-14' 
      AND website_sessions.utm_source = 'gsearch'
      AND website_sessions.utm_campaign  = 'nonbrand';

-- TASK: Pulling gsearch nonbrand trended session volume,by week
SELECT MIN(DATE(created_at)) as week_start_date ,COUNT(DISTINCT website_session_id) as sessions
FROM website_sessions
WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand' AND created_at < '2012-05-12'
GROUP BY YEAR(created_at), WEEK(created_at) ;


-- TASK: Pull conversion rates from session to order by device type
SELECT website_sessions.device_type,COUNT(website_sessions.website_session_id) AS sessions
,COUNT(orders.order_id) AS orders,COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) AS
session_to_order_conv_rate
FROM website_sessions
LEFT JOIN orders ON orders.website_session_id = website_sessions.website_session_id 
WHERE created_date < '2012-05-11' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY website_sessions.device_type ;

-- TASK : Find the total number of sessions by device type for each week start
SELECT  MIN(DATE(created_at)) AS week_start_date,
COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END ) AS dtop_sessions,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END ) AS mob_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-09' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at) ;

-- TASK: Find Top Website Pages 
SELECT pageview_url,COUNT(DISTINCT website_pageview_id) as session_volume
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url  ORDER BY session_volume DESC;

-- TASK : Find Top Entry Pages
CREATE TEMPORARY TABLE First_landing_page
SELECT MIN(website_pageview_id) AS min_pageview_id , website_session_id
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id; 

SELECT  website_pageviews.pageview_url,COUNT(First_landing_page.min_pageview_id)
FROM First_landing_page
LEFT JOIN website_pageviews ON First_landing_page.min_pageview_id = website_pageviews.website_pageview_id
GROUP BY website_pageviews.pageview_url;

DROP TABLE  viewcount_1;

-- TASK: Calculate Bounce Rates

CREATE TEMPORARY TABLE Min_pageview_id
SELECT MIN(website_pageview_id) AS view_id,website_session_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id;

CREATE TEMPORARY TABLE pageview_Landing
SELECT Min_pageview_id.website_session_id AS session_id, website_pageviews.pageview_url AS land_page
FROM Min_pageview_id
LEFT JOIN website_pageviews ON Min_pageview_id.view_id = website_pageviews.website_pageview_id;

CREATE TEMPORARY TABLE bounced_sessions
SELECT pageview_Landing.session_id as s_id,pageview_Landing.land_page AS land_page,COUNT(DISTINCT website_pageviews.website_pageview_id) AS pageview_count
FROM pageview_Landing
LEFT JOIN website_pageviews ON pageview_Landing.session_id=website_pageviews.website_session_id
GROUP BY pageview_Landing.session_id,pageview_Landing.land_page
HAVING COUNT(website_pageviews.website_pageview_id)= 1 ;

SELECT COUNT(DISTINCT bounced_sessions.s_id),COUNT(DISTINCT Min_pageview_id.website_session_id),
COUNT(DISTINCT bounced_sessions.s_id)/COUNT(DISTINCT Min_pageview_id.website_session_id) AS bounced_rate
FROM   Min_pageview_id
LEFT JOIN  bounced_sessions ON bounced_sessions.s_id= Min_pageview_id.website_session_id ;

-- TASK: Calculate Bounce Rates for two specific urls

CREATE TEMPORARY TABLE First_landingpage1
SELECT website_session_id, min(website_pageview_id) AS landing_id
FROM website_pageviews
WHERE created_at < '2012-06-28'
Group by website_session_id;

CREATE TEMPORARY TABLE Url_landingpage
SELECT First_landingpage1.website_session_id, website_pageviews.pageview_url ,First_landingpage1.landing_id 
FROM First_landingpage1
LEFT JOIN website_pageviews ON First_Landingpage1.Landing_id = website_pageviews.website_pageview_id;

CREATE TEMPORARY TABLE Bounced_sessions
SELECT Url_landingpage.website_session_id,Url_landingpage.pageview_url,COUNT(DISTINCT website_pageview_id) AS bounced_sessions
FROM Url_landingpage
LEFT JOIN website_pageviews ON Url_landingpage.website_session_id = website_pageviews.website_session_id
group by Url_landingpage.website_session_id,Url_landingpage.pageview_url
HAVING bounced_sessions = 1;



