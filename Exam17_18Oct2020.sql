create schema softuni_stores_system;
use softuni_stores_system;

-- Section 1: Data Definition Language
-- 1. Table design

create table `pictures` (
`id` int primary key auto_increment,
`url` varchar(100) not null,
`added_on` datetime not null);

create table `categories` (
`id` int primary key auto_increment,
`name` varchar(40) not null unique);

create table `products` (
`id` int primary key auto_increment,
`name` varchar(40) not null unique,
`best_before` date,
`price` decimal(10,2) not null,
`description` text,
`category_id` int not null,
`picture_id` int not null,
constraint fk_product_category foreign key (category_id) references categories(id),
constraint fk_product_picture foreign key (picture_id) references pictures(id));

create table `towns` (
`id` int primary key auto_increment,
`name` varchar(20) not null unique);

create table `addresses` (
`id` int primary key auto_increment,
`name` varchar(50) not null unique,
`town_id` int not null,
constraint fk_town_address foreign key (town_id) references towns(id));

create table `stores` (
`id` int primary key auto_increment,
`name` varchar(20) not null unique,
`rating` float not null,
`has_parking` boolean default false,
`address_id` int not null,
constraint fk_store_address foreign key (address_id) references addresses(id));

create table `products_stores` (
`product_id` int not null,
`store_id` int not null,
constraint pk_product_store primary key (product_id, store_id),
constraint fk_product foreign key (product_id) references products(id),
constraint fk_store foreign key (store_id) references stores(id));

create table `employees` (
`id` int primary key auto_increment,
`first_name` varchar(15) not null,
`middle_name` char(1),
`last_name` varchar(20) not null,
`salary` decimal(19,2) not null default 0,
`hire_date` date not null,
`manager_id` int,
`store_id` int not null,
constraint fk_employee_manager foreign key (manager_id) references employees(id),
constraint fk_employee_store foreign key (store_id) references stores(id));

-- Section 2: Data Manipulation Language
-- 2. Insert

insert into products_stores select p.id, 1 from products as p
left join products_stores as ps on p.id = ps.product_id
where ps.store_id is null;

-- 3. Update

update employees set manager_id = 3, salary = salary - 500
where year(hire_date) > 2003 and store_id not in (5, 14);

-- 4. Delete

delete from employees where salary >= 6000 and manager_id is not null;

-- Section 3: Querying
-- 5. Employees

select first_name, middle_name, last_name, salary, hire_date from employees
order by hire_date desc;

-- 6. Products with old pictures

select p.`name`, p.price, p.best_before, concat(left(p.`description`, 10), '...') as short_description, pic.url
from products as p join pictures as pic on p.picture_id = pic.id
where length(p.`description`) > 100 and year(pic.added_on) < 2019 and p.price > 20
order by p.price desc;

-- 7. Counts of products in stores and their average

select s.`name`, count(ps.product_id) as product_count, round(avg(p.price), 2) as `avg` from stores as s
left join products_stores as ps on s.id = ps.store_id
left join products as p on ps.product_id = p.id
group by s.id order by product_count desc, `avg` desc, s.id;

-- 8. Specific employee

select concat_ws(' ', e.first_name, e.last_name) as Full_name, s.`name`, a.`name`, e.`salary`
from employees as e join stores as s on s.id = e.store_id
join addresses as a on s.address_id = a.id
where e.salary < 4000 and locate(5, a.`name`) > 0 and length(s.`name`) > 8 and right(e.last_name, 1) = 'n';

-- 9. Find all information of stores

select reverse(s.`name`) as reversed_name, concat_ws('-', upper(t.`name`), a.`name`) as full_address, count(e.id) as employees_count
from stores as s join employees as e on s.id = e.store_id
join addresses as a on s.address_id = a.id
join towns as t on a.town_id = t.id
group by s.id order by full_address;

-- Section 4: Programmability

DELIMITER $$ 

-- 10. Find name of top paid employee by store name

create function udf_top_paid_employee_by_store(store_name VARCHAR(50))
returns varchar(255) deterministic
begin
	 declare full_info varchar(255);
     declare full_name varchar(40);
     declare years int;
     declare employee_id int;
     
     set employee_id := (
     select e.id from employees as e
     join stores as s on e.store_id = s.id
     where s.`name` = store_name
     order by e.salary desc limit 1);
     
     set full_name := (
     select concat_ws(' ', first_name, concat(middle_name, '.'), last_name)
     from employees where employees.id = employee_id);
     
     set years := (
     select floor(datediff("2020-10-18", hire_date)/365)
     from employees where employees.id = employee_id);
     
     set full_info := concat_ws(' ', full_name, 'works in store for', years, 'years');
     return full_info;
     end;
     
-- 11. Update product price by address

create procedure udp_update_product_price (address_name VARCHAR (50))
begin
    update products as p join products_stores as ps on ps.product_id = p.id
    join stores as s on ps.store_id = s.id
    join addresses as a on s.address_id = a.id
    set p.price = if (left(address_name, 1) = '0', p.price + 100, p.price + 200)
    where a.`name` = address_name;
end;
     



