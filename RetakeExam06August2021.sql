create schema sgd;
use sgd;

-- Section 1: Data Definition Language (DDL)
-- 1. Table design

create table `addresses` (
`id` int primary key auto_increment,
`name` varchar(50) not null);

create table `categories` (
`id` int primary key auto_increment,
`name` varchar(10) not null);

create table `offices` (
`id` int primary key auto_increment,
`workspace_capacity` int not null,
`website` varchar(50),
`address_id` int not null,
constraint fk_address_id
foreign key (address_id) references addresses(id));

create table `employees` (
`id` int primary key auto_increment,
`first_name` varchar(30) not null,
`last_name` varchar(30) not null,
`age` int not null,
`salary` decimal(10,2) not null,
`job_title` varchar(20) not null,
`happiness_level` char(1));

create table `teams` (
`id` int primary key auto_increment,
`name` varchar(40) not null,
`office_id` int not null,
`leader_id` int not null unique,
constraint fk_office_id
foreign key (office_id) references offices(id),
constraint fk_leader_id
foreign key (leader_id) references employees(id));

create table `games` (
`id` int primary key auto_increment,
`name`varchar(50) not null unique,
`description` text,
`rating` float not null default 5.5,
`budget` decimal(10,2) not null,
`release_date` date,
`team_id` int not null,
constraint fk_team_id
foreign key (team_id) references teams(id));

create table `games_categories` (
`game_id` int not null,
`category_id` int not null,
constraint pk_game_category primary key (game_id, category_id),
constraint fk_game foreign key (game_id) references games(id),
constraint fk_category foreign key (category_id) references categories(id));

-- Section 2: Data Manipulation Language (DML)
-- 2. Insert

insert into games (`name`, `rating`, `budget`, `team_id`)
select lower(reverse(substr(`name`, 2))), `id`, `leader_id` * 1000, `id`
from teams where id between 1 and 9;

-- 3. Update

update employees left join teams
on employees.id = teams.leader_id
set employees.salary = employees.salary + 1000
where teams.leader_id is not null and employees.salary < 5000 and employees.age <= 40;

-- 4. Delete

delete g from games as g
left join games_categories as gc
on g.id = gc.game_id where gc.game_id is null and g.release_date is null;

-- Section 3: Querying
-- 5. Employees

select `first_name`, `last_name`, `age`, `salary`, `happiness_level` from employees
order by `salary`, `id`;

-- 6. Addresses of the teams

select t.`name`, a.`name`, length(a.`name`)
from teams as t join offices as o 
on t.office_id = o.id
join addresses as a 
on o.address_id = a.id
where o.website is not null
order by t.`name`, a.`name`;

-- 7. Categories info

select c.`name`,
count(gc.game_id) as games_count,
round(avg(g.budget), 2) as avg_budget,
max(g.rating) as max_rating
from games as g join games_categories as gc on gc.game_id = g.id
join categories as c on gc.category_id = c.id
group by c.id having max_rating >= 9.5
order by games_count desc, c.`name`;

-- 8. Games of 2022

select g.`name`, g.release_date, concat(left(g.`description`, 10), '...') as summary,
	case
	when month(g.release_date) BETWEEN 1 AND 3 THEN 'Q1'
	when month(g.release_date) BETWEEN 4 AND 6 THEN 'Q2'
	when month(g.release_date) BETWEEN 7 AND 9 THEN 'Q3'
	else 'Q4'
	end as `quarter`, t.`name`
from games as g join teams as t on g.team_id = t.id
where right(g.`name`, 1) = '2' and year(g.release_date) = 2022 and month(g.release_date) % 2 = 0
order by `quarter`;

-- 9. Full info of games

select g.`name`, if(g.budget < 50000, 'Normal budget', 'Insufficient budget') as budget_level, t.`name`, a.`name`
from games as g left join games_categories as gc on gc.game_id = g.id
join teams as t on g.team_id = t.id
join offices as o on t.office_id = o.id
join addresses as a on o.address_id = a.id
where g.release_date is null and gc.category_id is null
order by g.`name`;

-- Section 4: Programmability
-- 10. Find all the basic info for a game

create function udf_game_info_by_name (game_name varchar(20))
returns varchar(255)
deterministic
begin
	declare info varchar (255);
	declare team_name varchar (40);
	declare address_text varchar (50);
	
	set team_name := (select t.`name`
		from teams as t join games as g on g.team_id = t.id where g.`name` = game_name);
	
  	set address_text := (select a.`name`
		from addresses as a join offices as o on a.id = o.address_id join teams as t
		on o.id = t.office_id where t.`name` = team_name);
    
  	set info := concat_ws(' ', 'The', game_name, 'is developed by a', team_name, 'in an office with an address', address_text);
  	return info;
end;

-- 11. Update budget of the games
   
create procedure udp_update_budget (min_game_rating float)
begin
	update games AS g left join games_categories as c on g.id = c.game_id
    	set g.budget = g.budget + 100000, 
		g.release_date = adddate(g.release_date, interval 1 year)
	where c.category_id is null and g.release_date IS NOT NULL and g.rating > min_game_rating;
end;
