create schema `restaurant_db`;
use `restaurant_db`;

create table `products`(
`id` int primary key auto_increment,
`name` varchar(30) not null unique,
`type` varchar(30) not null,
`price` decimal(10,2) not null);

create table `clients`(
`id` int primary key auto_increment,
`first_name` varchar(50) not null,
`last_name` varchar(50) not null,
`birthdate` date not null,
`card` varchar(50),
`review` text);

create table `tables`(
`id` int primary key auto_increment,
`floor` int not null,
`reserved` boolean,
`capacity` int not null);

create table `waiters`(
`id` int primary key auto_increment,
`first_name` varchar(50) not null,
`last_name` varchar(50) not null,
`email` varchar(50) not null,
`phone` varchar(50),
`salary` decimal(10,2));

create table `orders`(
`id` int primary key auto_increment,
`table_id` int not null,
`waiter_id` int not null,
`order_time` time not null,
`payed_status` boolean,
constraint fk_order_table foreign key (table_id) references `tables`(id),
constraint fk_order_waiter foreign key (waiter_id) references waiters(id));

create table `orders_clients`(
`order_id` int,
`client_id` int,
constraint fk_order foreign key (order_id) references orders(id),
constraint fk_client foreign key (client_id) references clients(id));

create table `orders_products`(
`order_id` int,
`product_id` int,
constraint fk_order_product foreign key (order_id) references orders(id),
constraint fk_product foreign key (product_id) references products(id));

insert into products (`name`,`type`,`price`)
select concat_ws(' ', w.last_name,'specialty'), 'Cocktail', ceil(salary * 0.01)
from waiters as w where w.id > 6;

update orders set table_id = table_id - 1
where id between 12 and 23;

delete w from waiters as w
left join orders as o on w.id = o.waiter_id
where o.waiter_id is null;

select `id`, first_name, last_name, birthdate, card, review from clients
order by birthdate desc, id desc;

select first_name, last_name, birthdate, review from clients
where card is null and year(birthdate) between 1978 and 1993
order by last_name desc, id asc
limit 5;

select concat(last_name, first_name, char_length(first_name), 'Restaurant') as username,
reverse(substr(email,2,12)) as `password`
from waiters where salary is not null
order by `password` desc;

select p.`id`, p.`name`, count(op.order_id) as 'count' from products as p
join orders_products as op 
on p.id = op.product_id
group by p.`name` having count >= 5
order by count desc, p.`name` asc;

select t.`id` as table_id, t.`capacity`,count(oc.client_id) as count_clients, case
when t.`capacity` > count(oc.client_id) then 'Free seats'
when t.`capacity` = count(oc.client_id) then 'Full'
when t.`capacity` < count(oc.client_id) then 'Extra seats'
end as availability
from `tables` as t
join orders as o on t.id = o.table_id
join orders_clients as oc on o.id = oc.order_id
where t.`floor` = 1 group by t.`id`
order by t.`id` desc;

delimiter $$

create procedure udp_happy_hour(`type` varchar(50))
begin
update products as p
join orders_products as op
on p.id = op.product_id
join orders as o
on op.order_id = o.id
set p.price = p.price - (p.price * 0.2)
where p.price >= 10 and `type` = p.`type`;
end;

delimiter $$

create function udf_client_bill(full_name varchar(50))
returns varchar(255) deterministic
begin
	declare total_price decimal(19,2);
    set total_price := (
        select sum(p.price) as 'bill'
        from products as p
        join orders_products as op on p.id = op.product_id
        join orders as o on o.id = op.order_id
        join orders_clients as oc on o.id = oc.order_id
        join clients as c on c.id = oc.client_id
        where concat(c.first_name,' ', c.last_name) = full_name);
        return total_price;
        end;