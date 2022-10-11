create schema `ruk_database`;
use `ruk_database`;

-- Section 1: Data Definition Language(DDL)
-- 1. Table design

create table `branches` (
`id` int primary key auto_increment,
`name` varchar(30) not null unique);

create table `employees` (
`id` int primary key auto_increment,
`first_name` varchar(20) not null,
`last_name` varchar(20) not null,
`salary` decimal(10,2) not null,
`started_on` date not null,
`branch_id` int not null,
constraint fk_employee_branch foreign key (branch_id) references branches(id));

create table `clients` (
`id` int primary key auto_increment,
`full_name` varchar(50) not null,
`age` int not null);

create table `employees_clients`(
`employee_id` int not null,
`client_id` int not null,
key pk_employee_client (employee_id, client_id),
constraint fk_employee foreign key (employee_id) references employees(id),
constraint fk_client foreign key (client_id) references clients(id));

create table `bank_accounts` (
`id`int primary key auto_increment,
`account_number` varchar(10) not null,
`balance` decimal(10,2) not null,
`client_id` int not null unique,
constraint fk_client_account foreign key (client_id) references clients(id));

create table `cards` (
`id` int primary key auto_increment,
`card_number` varchar(19) not null,
`card_status` varchar(7) not null,
`bank_account_id` int not null,
constraint fk_card_account foreign key (bank_account_id) references bank_accounts(id));

-- Section 2: Data Manipulation Language(DML)
-- 2. Insert

insert into `cards` (card_number, card_status, bank_account_id)
select reverse(full_name), 'Active', id
from clients where id between 191 and 200;

-- 3. Update

update employees_clients set employee_id =
(select * from ( select employee_id from employees_clients group by employee_id order by count(client_id), employee_id limit 1) as ec)
where client_id = employee_id;

-- 4. Delete

delete e from employees as e left join employees_clients as ec
on e.id = ec.employee_id where ec.client_id is null;

-- Section 3: Querying
-- 5. Clients

select id, full_name from clients
order by id;

-- 6. Newbies

select id, concat_ws(' ', first_name, last_name) as full_name, concat('$',salary) as salary, started_on from employees
where salary >= 100000 and started_on >= '2018-01-01' 
order by salary desc, id;

-- 7. Cards against humanity

select c.id, concat_ws(' ', c.card_number, ':', cl.full_name) as card_token
from cards as c join bank_accounts as ba on c.bank_account_id = ba.id
join clients as cl on ba.client_id = cl.id
order by c.id desc;

-- 8. Top 5 employees

select concat_ws(' ', first_name, last_name) as `name`, started_on, count(ec.client_id) as count_of_clients
from employees as e join employees_clients as ec on e.id = ec.employee_id
group by e.id order by count_of_clients desc, e.id limit 5;

-- 9. Branch cards

select b.`name`, count(ca.id) as count_of_cards
from branches as b
left join employees as e on e.branch_id = b.id
left join employees_clients as ec on e.id = ec.employee_id
left join clients as c on ec.client_id = c.id
left join bank_accounts as ba on c.id = ba.client_id
left join cards as ca on ba.id = ca.bank_account_id
group by b.`name` order by count_of_cards desc, b.`name`;

DELIMITER $$
-- Section 4: Programmability
-- 10. Extract client card count

create function udf_client_cards_count(`name` varchar(30))
returns int deterministic
begin
	declare cards int;
	set cards := (
		select count(ca.id) from clients as c
		left join bank_accounts as ba on c.id = ba.client_id
		left join cards as ca on ba.id = ca.bank_account_id
        where c.full_name = `name`);
  	return cards;
end;

-- 11. Client info

create procedure udp_clientinfo (full_name varchar(50))
begin
	select c.full_name, c.age, ba.account_number, concat('$', ba.balance) as balance
    	from clients as c join bank_accounts as ba on c.id = ba.client_id
	    where c.full_name = full_name;
end;