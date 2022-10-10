create schema fsd;
use fsd;

-- Section 1: Date Definition Language(DML)
-- 1. Table design

create table `players` (
`id` int primary key auto_increment,
`first_name` varchar(10) not null,
`last_name` varchar(10) not null,
`age` int not null default 0,
`position` char(1) not null,
`salary` decimal(10,2) not null default 0,
`hire_date` datetime,
`skills_data_id` int not null,
`team_id` int,
constraint fk_skills_data foreign key (skills_data_id) references skills_data(id),
constraint fk_teams foreign key (team_id) references teams(id));

create table `players_coaches` (
`player_id` int,
`coach_id` int,
key pk_player_coach (player_id, coach_id),
constraint fk_player foreign key (player_id) references players(id),
constraint fk_coach foreign key (coach_id) references coaches(id));

create table `coaches` (
`id` int primary key auto_increment,
`first_name` varchar(10) not null,
`last_name` varchar(20) not null,
`salary` decimal(10,2) not null default 0,
`coach_level` int not null default 0);

create table `skills_data` (
`id` int primary key auto_increment,
`dribbling` int default 0,
`pace` int default 0,
`passing` int default 0,
`shooting` int default 0,
`speed` int default 0,
`strength` int default 0);

create table `teams` (
`id` int primary key auto_increment,
`name` varchar(45) not null,
`established` date not null,
`fan_base` bigint not null default 0,
`stadium_id` int not null,
constraint fk_team_stadium foreign key (stadium_id) references stadiums(id));

create table `stadiums` (
`id` int primary key auto_increment,
`name` varchar(45) not null,
`capacity` int not null,
`town_id` int not null,
constraint fk_stadium_town foreign key (town_id) references towns(id));

create table `towns` (
`id` int primary key auto_increment,
`name` varchar(45) not null,
`country_id` int not null,
constraint fk_town_country foreign key (country_id) references countries(id));

create table `countries` (
`id` int primary key auto_increment,
`name` varchar(45) not null);

-- Section 2: Data Manipulation Language(DML)
-- 2. Insert

insert into `coaches` (first_name, last_name, salary, coach_level)
select first_name, last_name, salary * 2, length(first_name)
from players where age >= 45;

-- 3. Update

update coaches as c left join players_coaches as pc
on c.id = pc.coach_id
set c.coach_level = c.coach_level + 1
where left(first_name, 1) = 'A' and pc.player_id is not null;

-- 4. Delete

delete from players where age >= 45;

-- Section 3: Querying
-- 5. Players

select first_name, age, salary from players
order by salary desc;

-- 6. Young offense players without contract

select p.id, concat_ws(' ', first_name, last_name) as full_name, age, `position`, hire_date
from players as p join skills_data as sd
on p.skills_data_id = sd.id
where age < 23 and `position` = 'A' and hire_date is null and sd.strength > 50
order by salary, age;

-- 7. Detail info for all teams

select `name`, established, fan_base, (select count(id) from players where team_id = t.id) as players_count
from teams as t order by players_count desc, fan_base desc;

-- 8. The fastest player by towns

select max(sd.speed) as max_speed, t.`name` from players as p
right join skills_data as sd on p.skills_data_id = sd.id
right join teams as tm on p.team_id = tm.id
right join stadiums as s on tm.stadium_id = s.id
right join towns as t on s.town_id = t.id
where tm.`name` not like 'Devify'
group by t.`name` order by max_speed desc, t.`name`;

-- 9. Total salaries and players by country

select c.`name`, count(p.id) as total_count_of_players, sum(p.salary) as total_sum_of_salaries
from players as p
right join skills_data as sd on p.skills_data_id = sd.id
right join teams as tm on p.team_id = tm.id
right join stadiums as s on tm.stadium_id = s.id
right join towns as t on s.town_id = t.id
right join countries as c on t.country_id = c.id
group by c.`name` order by total_count_of_players desc, c.`name`;

DELIMITER $$
-- Section 4: Programmability
-- 10. Find all players that play on stadium

create function udf_stadium_players_count (stadium_name VARCHAR(30))
returns int deterministic
begin
     declare count int;
     set count := (
     select count(p.id) 
     from stadiums as s join teams as tm on tm.stadium_id = s.id
     join players as p on p.team_id = tm.id
     where s.`name` = stadium_name);
     return count;
     end;
     
-- 11. Find good playmaker by teams

create procedure udp_find_playmaker (min_dribble_points int, team_name varchar(45))
begin
	 select concat_ws(' ', first_name, last_name) as full_name, age, salary, sd.dribbling, sd.speed, tm.`name`
     from players as p join skills_data as sd on p.skills_data_id = sd.id
     join teams as tm on p.team_id = tm.id
     where sd.dribbling > min_dribble_points and tm.`name` = team_name
     and sd.speed > (select avg(speed) from skills_data)
     order by sd.speed desc limit 1;
     end;