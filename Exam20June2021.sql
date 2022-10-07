use stc;

-- Section 1: Data Definition Language(DDL)
-- 1. Table Design

create table `addresses` (
`id` int primary key auto_increment,
`name` varchar(100) not null);

create table `categories` (
`id` int primary key auto_increment,
`name` varchar(10) not null);

create table `clients` (
`id` int primary key auto_increment,
`full_name` varchar(50) not null,
`phone_number` varchar(20) not null);

create table `drivers` (
`id` int primary key auto_increment,
`first_name` varchar(30) not null,
`last_name` varchar(30) not null,
`age` int not null,
`rating` float default 5.5);

create table `cars`(
`id` int primary key auto_increment,
`make` varchar(20) not null,
`model` varchar(20) not null,
`year` int not null default 0,
`mileage` int default 0,
`condition` char(1) not null,
`category_id` int not null,
constraint fk_car_category
foreign key(category_id) references categories(id));

create table `courses` (
`id` int primary key auto_increment,
`from_address_id` int not null,
`start` datetime not null,
`bill` decimal(10,2) default 10,
`car_id` int not null,
`client_id` int not null,
constraint fk_course_address
foreign key (from_address_id) references addresses(id),
constraint fk_course_car
foreign key (car_id) references cars(id),
constraint fk_course_client
foreign key (client_id) references clients(id));

create table `cars_drivers` (
`car_id` int not null,
`driver_id` int not null,
constraint pk_car_driver
primary key (car_id, driver_id),
constraint fk_car
foreign key (car_id) references cars(id),
constraint fk_driver
foreign key (driver_id) references drivers(id));

-- Section 2: Data Manipulation Language (DML)
-- 2. Insert

insert into clients (full_name, phone_number)
select concat_ws(' ', first_name, last_name), concat('(088) 9999', id*2)
from drivers
where id between 10 and 20;

-- 3. Update

update cars set `condition` = 'C'
where (mileage >= 800000 or mileage is null) and `year` <= 2010 and make not like 'Mercedes-Benz';

-- 4. Delete

delete c from clients as c
left join courses as co on c.id = co.client_id
where co.client_id is null and length(c.full_name) > 3;


-- Section 3: Querying
-- 5. Cars

select `make`, `model`, `condition` from cars
order by `id`;

-- 6. Drivers and cars

select d.first_name, d.last_name, c.make, c.model, c.mileage
from drivers as d 
join cars_drivers as cd on d.id = cd.driver_id
join cars as c on cd.car_id = c.id
where c.mileage is not null
order by c.mileage desc, d.first_name;

-- 7. Numbre of courses for each car

select c.id, c.make, c.mileage, count(co.id) as count_of_courses, round(avg(co.bill), 2) as avg_bill
from cars as c left join courses as co on c.id = co.car_id
group by c.id having count_of_courses <> 2
order by count_of_courses DESC, c.id;

-- 8. Regular clients

select c.full_name, count(co.id) as count_of_cars,	sum(co.bill) as total_sum
from clients as c join courses as co on c.id = co.client_id
group by c.id having count_of_cars > 1 and substr(c.full_name, 2, 1) like 'a'
order by c.full_name;

-- 9. Full info for course

select a.`name`, if(hour(co.`start`) between 6 and 20, 'Day', 'Night') as day_time,
        co.bill, c.full_name, ca.make, ca.model, cat.`name`
from courses as co join addresses as a on a.id = co.from_address_id
left join clients as c on co.client_id = c.id
left join cars as ca on co.car_id = ca.id
left join categories as cat on ca.category_id = cat.id
order by co.id;

-- Section 4: Programmability 
-- 10. Find all courses by clients phone number

DELIMITER $$
create function udf_courses_by_client (phone_num varchar (20)) 
returns int deterministic
begin
	declare count int;
	set count := (select count(c.id)
	 from courses AS c join clients AS cl on c.client_id = cl.id 
	where cl.phone_number = phone_num);
  	return count;
end;

-- 11. Full info for address

create procedure udp_courses_by_address (address_name varchar(100))
begin
	select a.`name`, c.full_name, 
		case
			when co.bill <= 20 then 'Low'
			when co.bill <= 30 then 'Medium'
			else 'High'
        end as level_of_bill, ca.make, ca.condition, cat.`name`
	FROM courses as co join addresses as a on a.id = co.from_address_id
	left join clients as c on co.client_id = c.id
	left join cars as ca on co.car_id = ca.id
	left join categories as cat on ca.category_id = cat.id
	where a.`name` = address_name
	order by ca.make, c.full_name;
end;



