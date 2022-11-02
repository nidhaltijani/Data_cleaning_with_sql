--sal 2018 and sal2019 have the same structure so we are going to perform the data cleaning for both
SELECT * 
From IT_salaries..sal2018

SELECT * 
FROM IT_salaries..sal2019
--standarize the date 
SELECT PARSE(SUBSTRING("Timestamp",1,10) as date using 'AR-LB'),*
FROM IT_salaries..sal2018

SELECT  PARSE(replace(SUBSTRING(Zeitstempel,1,10),'.','/') as date using 'AR-LB')
  FROM [IT_salaries].[dbo].[sal2019]

ALTER TABLE sal2018
Add date_converted date

ALTER TABLE sal2019
Add date_converted date

UPDATE sal2018
set date_converted=PARSE(SUBSTRING("Timestamp",1,10) as date using 'AR-LB')
UPDATE sal2019
set date_converted=PARSE(replace(SUBSTRING(Zeitstempel,1,10),'.','/') as date using 'AR-LB')

ALTER TABLE sal2018 
DROP COLUMN Timestamp
ALTER TABLE sal2019
DROP COLUMN Zeitstempel


--age column
SELECT * 
FROM IT_salaries .. sal2019
where age = ''
update sal2019
set age=null
where age = ''
update sal2018
set age=null
where age = ''

ALTER TABLE sal2018 ALTER COLUMN age int
ALTER TABLE sal2019 ALTER COLUMN age int


--filling missing values in age with the avg since the age column doesnt have any outliers
update sal2018
set age=(SELECT AVG(age) FROM IT_salaries..sal2018)
where age is null

update sal2019
set age=(SELECT AVG(age) FROM IT_salaries..sal2019)
where age is null

--Checking for gender column
SELECT distinct gender FROM IT_salaries..sal2018

select case gender
		when 'F' then 'Female'
		when 'M' then 'Male'
		else 'Nan'
		end
		FROM IT_salaries..sal2018

UPDATE IT_salaries..sal2018
SET gender=case gender
		when 'F' then 'Female'
		when 'M' then 'Male'
		else 'Nan'
		end

select * FROM IT_salaries..sal2018 where gender='Nan'
-- we have 3 actual nan values in gender column the rest are empty rows
DELETE FROM IT_salaries..sal2018 WHERE gender='Nan' and city=''

-- calculating the mode to fill these nan values 
SELECT gender,COUNT(*) FROM IT_salaries..sal2018 Group BY gender

UPDATE IT_salaries..sal2018
set gender ='Male'
WHERE gender='Nan'



select distinct gender FROM IT_salaries..sal2019
-- all good for sal2019 table

--Position column


SELECT * 
FROM IT_salaries..sal2018 
WHERE Position =''
-- either impute with mode or compare salary to avg salary for every position
--or drop columns


--SELECT Position,AVG(cast("Current Salary" as int))
--FROM IT_salaries..sal2018 
--WHERE "Current Salary" <> 'Senior' and "Current Salary" <> 'Middle'
--GROUP BY Position

SELECT position,Count(*)
FROM IT_salaries..sal2018
WHERE "Current Salary" <> 'Senior' and "Current Salary" <> 'Middle'
GROUP BY Position
order by 2 desc

--java developper is the mode 
select * from IT_salaries..sal2018 where Position like '%Java Developer%'

update IT_salaries..sal2018
set Position='Java Developer'
where Position=''


--initcap doesnt work in sql server
UPDATE IT_salaries..sal2018 
set Position=Upper(LEFT(Trim(Position),1))+LOWER(SUBSTRING(TRIM(Position),2,LEN(Trim(Position))))

select Position from IT_salaries..sal2018 

--Years of exp 
SELECT "Years of experience" FROM IT_salaries..sal2018 where "Years of experience"=''

--22 blank rows and many roww containing a wrong value which is the position and we should know why
--identifying these rows using regexp
SELECT * 
FROM IT_salaries..sal2018
WHERE "Years of experience" not like '%[0-9]%' and "Years of experience" <>''
--in these 5 rows they added the country to the values so every value has passed its column with 1 step
-- in theese rows the company type column actually contains the company size and type

UPDATE IT_salaries..sal2018 
set Position=[Years of experience],
[Years of experience]=[Your level],
[Your level]=[Current Salary],
[Current Salary]=[Salary one year ago],
[Salary one year ago]=[Salary two years ago],
[Salary two years ago]=[Are you getting any Stock Options?],
[Are you getting any Stock Options?]=[Main language at work],
[Main language at work]=[Company size]
WHERE [Years of experience] not like '%[0-9]%' and "Years of experience" <>''
select * from IT_salaries..sal2018 where [Company type] like '%IT,%'
--query to split the column into 2 
SELECT  SUBSTRING([Company type],1,CHARINDEX(',',[company type])-1),SUBSTRING([Company type],CHARINDEX(',',[company type])+1,len([company type]))
FROM IT_salaries..sal2018
Where [Company type] like '%,%' and [Company type] not like '%IT,%'

UPDATE IT_salaries..sal2018 
set [Company size]=SUBSTRING([Company type],1,CHARINDEX(',',[company type])-1),
[Company type]=SUBSTRING([Company type],CHARINDEX(',',[company type])+1,len([company type]))
WHERE [Company type] like '%,%' and [Company type] not like '%IT,%'



--back to imputing values in the years of exp column
select avg(cast("Years of experience" as float))
from IT_salaries..sal2018 

UPDATE IT_salaries..sal2018
set [Years of experience]=(select avg(cast("Years of experience" as float))
from IT_salaries..sal2018 )
where "Years of experience"=''

--changing the column type
ALTER TABLE IT_salaries..sal2018 ALTER COLUMN [Years of experience] float

-- your level
SELECT distinct [Your level],[Current salary],[Years of experience]
FROM IT_salaries..sal2018
-- junior / middle / senior


select *
FROM IT_salaries..sal2018
where [Your level]=''

-- we will calculate
SELECT * FROM IT_salaries..sal2018 where Position='CEO'
--we are going to drow the row of the ceo 
DELETE FROM IT_salaries..sal2018 
WHERE Position='CEO'

-- we have 3 rows that appears to be a wrong entry one with a male who is 32 YO from zurich and 2 others from berlin with the same age  and position and years of experience but all other columns are empty 
--so we will drop the 2 rows with empty columns and we will correct the years of exp because 8.29907 doesnt make sense
DELETE FROM IT_salaries..sal2018 
WHERE  [Years of experience]=8.29907 and [Current Salary]=''
-- corrected all the years of exp to 1 decimal number
UPDATE IT_salaries..sal2018
set [Years of experience]=(SELECT ROUND([Years of experience],1))

-- to correct the empty columns in the level column we will assume 
select ROUND(avg([Years of experience]),0)
FROM IT_salaries..sal2018 
where [Your level]='Junior'


select ROUND(avg([Years of experience]),0)
FROM IT_salaries..sal2018 
where [Your level]='Middle'


select ROUND(avg([Years of experience]),0)
FROM IT_salaries..sal2018 
where [Your level]='Senior'

-- the average of exp for junior is 2 and 6 for middle and 10 for senior so we will assume that from 0 to 4 would be junior and from 4 to 8 would be middle and the rest is senior

-- _ rows to update and fill the level column
UPDATE a
SET a.[Your level] = CASE 
					WHEN a.[Years of experience] < 4 then 'Junior'
					When a.[Years of experience] < 8 then 'Middle'
					When a.[Years of experience] >=8 then 'Senior'
					ELSE 'NA'
					END 
					FROM IT_salaries..sal2018 a
					JOIN IT_salaries..sal2018 e
					on a.Age=e.Age and a.City=e.City and a.[Years of experience]=e.[Years of experience]
					WHERE a.[Your level]=''



--current salary 
SELECT * from IT_salaries..sal2018 where [Current Salary]=''
--only one row contains an empty column of salary for a female  with the position data scientist so we can calculate tha average of salary of female in data science and impute the value
--Although we only have 2 female data scientist so the value could be so far from real 
SELECT AVG(CAST([Current salary] as int)),COUNT(*)
FROM IT_salaries..sal2018 
WHERE Gender='Female' and Position='Data scientist' and [Current Salary] <>''

UPDATE IT_salaries..sal2018 
SET [Current Salary]=(SELECT AVG(CAST([Current salary] as int))
FROM IT_salaries..sal2018 
WHERE Gender='Female' and Position='Data scientist' and [Current Salary] <>'')
WHERE [Current Salary]=''

--verify for non numeric values 
SELECT * 
FROM IT_salaries..sal2018
WHERE [Current Salary] not like '%[0-9]%'

-- all the values are numeric so we can change the column type 

ALTER TABLE IT_salaries..sal2018 ALTER COLUMN [Current salary] int

-- DROPING SALARY one year ago  and 2 years ago because we don't need them in our analysis and stock options
ALTER TABLE IT_salaries..sal2018 DROP COLUMN [Salary one year ago]
ALTER TABLE IT_salaries..sal2018 DROP COLUMN [Salary two years ago]
ALTER TABLE IT_salaries..sal2018 DROP COLUMN [Are you getting any Stock Options?]

-- main language column
SELECT distinct [Main language at work]
FROM IT_salaries..sal2018 



SELECT *
FROM IT_salaries..sal2018 
WHERE [Main language at work]=''

-- 2 empty values where the city is hamburg and munchen we will verify them one by  one 
SELECT [Main language at work], COUNT(*)
FROM IT_salaries..sal2018
where City like '%nchen%' -- we need to fix munchen name
GROUP BY [Main language at work]
Order by 2 DESC

--In munchen they are more likely to speak English at work

SELECT [Main language at work], COUNT(*)
FROM IT_salaries..sal2018
where City like '%Hamburg%' -- we need to fix munchen name
GROUP BY [Main language at work]
Order by 2 DESC

-- Same in hamburg 

UPDATE IT_salaries..sal2018
SET [Main language at work]='English'
WHERE (City like '%Hamburg%' or City like '%nchen%') and [Main language at work]=''


--verify the value "team-russian.."


SELECT *
FROM IT_salaries..sal2018 
WHERE [Main language at work] like '%Team%'
-- change it to Russian/English

UPDATE IT_salaries..sal2018
SET [Main language at work]='Russian/English'
WHERE [Main language at work] like '%Team%'

--Company size  column 
SELECT distinct [Company size]
FROM IT_salaries..sal2018


SELECT  *
FROM IT_salaries..sal2018
WHERE [Company size]=''
-- ios dev middle 70000 salary and java dev senior 70000 salary


SELECT [Company size],AVG([Current salary]),[Your level]
FROM IT_salaries..sal2018
group by [Company size],[Your level]

-- from this query we can say that an employee in the middle level is more likely to get 70000 salary ina 1000+ company the max was 66487
--and for an employee ine the senior level  is more likely to get 70000 in a 50-100 company the avg was 70816 the closest one
UPDATE IT_salaries..sal2018
SET [Company size]='1000+'
WHERE [Company size]='' and [Your level]='Middle'

UPDATE IT_salaries..sal2018
SET [Company size]='50-100'
WHERE [Company size]='' and [Your level]='Senior'


--Company type 

SELECT distinct [Company type]
FROM IT_salaries..sal2018 



SELECT COUNT(*),[Company type]
FROM IT_salaries..sal2018
GROUP BY [Company type]
ORDER BY 1 DESC


--Product is the mode  of this categorical columns so we can use it to impute empty values

SELECT  *
FROM IT_salaries..sal2018 
WHERE [Company type]=''


UPDATE IT_salaries..sal2018
SET [Company type]='Product'
WHERE [Company type]=''

-- back to the city names 

SELECT distinct City
FROM IT_salaries..sal2018


UPDATE IT_salaries..sal2018 
SET City=RIGHT(CITY,LEN(City)-1)
WHERE city LIKE '"%'

-- correct munchen name

UPDATE IT_salaries..sal2018 
SET City='Munchen'
WHERE city LIKE 'M%nchen%'

--tubingen
UPDATE IT_salaries..sal2018 
SET City='Tubinger'
WHERE city LIKE 'T%bingen%'


UPDATE IT_salaries..sal2018 
SET City='Baden Wurttemberg'
WHERE city LIKE 'Baden-W%temberg%'



UPDATE IT_salaries..sal2018 
SET City='Dusseldorf'
WHERE city LIKE 'D%seldorf%'


UPDATE IT_salaries..sal2018 
SET City='Koln'
WHERE city LIKE 'K%n'

UPDATE IT_salaries..sal2018 
SET City='Nurnberg'
WHERE city LIKE 'N%rnberg'



UPDATE IT_salaries..sal2018 
SET City='Munster'
WHERE city LIKE 'M%nster'



SELECT *
FROM IT_salaries..sal2018
WHERE City=''

SELECT AVG([Current salary]),[Your level],[Company size],City
FROM IT_salaries..sal2018
WHERE City <> ''
GROUP BY [Your level],[Company size],City


-- we need to impute the city name but with which strat ?
