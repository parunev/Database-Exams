create schema `colonial_journey_management_system_db`;
use `colonial_journey_management_system_db`;

-- 1. Table Design

create table `planets` (
`id` int primary key auto_increment,
`name` varchar(30) not null);

create table `spaceports` (
`id` int primary key auto_increment,
`name` varchar(50) not null,
`planet_id` int,
constraint fk_planet_spaceport foreign key (planet_id) references planets(id));

create table `spaceships` (
`id` int primary key auto_increment,
`name` varchar(50) not null,
`manufacturer` varchar(30) not null,
`light_speed_rate` int default 0);

create table `colonists` (
`id` int primary key auto_increment,
`first_name` varchar(20) not null,
`last_name` varchar(20) not null,
`ucn` char(10) not null unique,
`birth_date` date not null);

create table `journeys` (
`id` int primary key auto_increment,
`journey_start` datetime not null,
`journey_end` datetime not null,
`purpose` enum ('Medical', 'Technical', 'Educational', 'Military'),
`destination_spaceport_id` int,
`spaceship_id` int,
constraint fk_destination_journey foreign key (destination_spaceport_id) references spaceports(id),
constraint fk_spaceship_journey foreign key (spaceship_id) references spaceships(id));

create table `travel_cards` (
`id` int primary key auto_increment,
`card_number` varchar(10) not null unique,
`job_during_journey` enum ('Pilot', 'Engineer', 'Trooper', 'Cleaner', 'Cook'),
`colonist_id` int,
`journey_id` int,
constraint fk_colonist_tc foreign key (colonist_id) references colonists(id),
constraint fk_journey_tc foreign key (journey_id) references journeys(id));

-- 2. Insert

insert into travel_cards (card_number, job_during_journey, colonist_id, journey_id)
select if(birth_date >= '1980-01-01', concat(year(birth_date), day(birth_date), left(ucn,4)),
	   concat(year(birth_date), month(birth_date), right(ucn,4))) as card_number,
       case
           when id % 2 = 0 then 'Pilot'
           when id % 3 = 0 then 'Cook'
           else 'Engineer'
	   end as job_during_journey, 
       id, left(ucn,1) as journey_id
       from colonists
where id between 96 and 100;

-- 2. Update

update journeys 
set purpose = case
    when id % 2 = 0 then 'Medical'
    when id % 3 = 0 then 'Technical'
    when id % 5 = 0 then 'Educational'
    when id % 7 = 0 then 'Millitary'
end
where id % 2 = 0 or id % 3 = 0 or id % 5 = 0 or id % 7 = 0;

-- 3. Delete

delete c from colonists as c
left join travel_cards as tc
on tc.colonist_id = c.id
where tc.colonist_id is null;

-- 4. Extract all travel cards

select card_number, job_during_journey from travel_cards
order by card_number;

-- 5. Extract all colonists

select id, concat_ws(' ', first_name, last_name) as full_name, ucn from colonists
order by first_name, last_name, id asc;

-- 6. Extract all millitary journeys

select id, journey_start, journey_end from journeys
where purpose = 'Military' order by journey_start;

-- 7. Extract all pilots

select c.id, concat_ws(' ', first_name, last_name) as full_name from colonists as c
join travel_cards as tc on c.id = tc.colonist_id
where tc.job_during_journey = 'Pilot'
order by c.id;

-- 8. Count all colonists that are on technical journey

select count(c.id) from colonists as c
join travel_cards as tc on c.id = tc.colonist_id
join journeys as j on tc.journey_id = j.id
where j.purpose = 'Technical';

-- 9. Exctract the fastest spaceship

select s.`name`, sp.`name` from spaceships as s
join journeys as j on s.id = j.spaceship_id
join spaceports as sp on j.destination_spaceport_id = sp.id
order by s.light_speed_rate desc limit 1;

-- 10. Extract - pilots younger than 30 years

select s.`name`, s.manufacturer from spaceships as s
join journeys as j on s.id = j.spaceship_id
join travel_cards as tc on j.id = tc.journey_id
join colonists as c on c.id = tc.colonist_id
where 2019 - year(c.birth_date) < 30 and tc.job_during_journey = 'Pilot'
group by s.id order by s.`name`;

-- 11. Extract all educational mission

select p.`name`, s.`name` from spaceports as s
join journeys as j on s.id = j.destination_spaceport_id
join planets as p on p.id = s.planet_id
where j.purpose = 'Educational' order by s.`name` desc;

-- 12. Extract all planets and their journey count

select p.`name`, count(j.id) as journeys_count from planets as p
join spaceports as s on p.id = s.planet_id
join journeys as j on s.id = j.destination_spaceport_id
group by p.`name` order by journeys_count desc, p.`name`;

-- 13. Extract the shortest journey

select j.id, p.`name`, s.`name`, j.purpose
from planets as p
join spaceports as s on p.id = s.planet_id
join journeys as j on s.id = j.destination_spaceport_id
order by j.journey_end - j.journey_start limit 1;

-- 14. Extract the less popular job

select tc.job_during_journey from travel_cards as tc
join journeys as j on tc.journey_id = j.id
group by j.id, tc.job_during_journey
order by j.journey_end - j.journey_start desc, count(tc.id) LIMIT 1;

DELIMITER $$
-- 15. Get colonists count

create function udf_count_colonists_by_destination_planet (planet_name varchar(30))
returns int deterministic
begin
	declare count_colonists int;
	set count_colonists := (
		select count(c.id) from colonists as c
		join travel_cards as tc on c.id = tc.colonist_id
		join journeys as j on j.id = tc.journey_id
        join spaceports as s on j.destination_spaceport_id = s.id
        join planets as p on p.id = s.planet_id
        where p.`name` = planet_name);
  	return count_colonists;
end;

