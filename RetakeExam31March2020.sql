create schema `instd`;
use `instd`;

-- Section 1: Data Definition Language(DDL)
-- 1. Table design

create table `users` (
`id` int primary key auto_increment,
`username` varchar(30) not null unique,
`password` varchar(30) not null,
`email` varchar(50) not null,
`gender` char(1) not null,
`age` int not null,
`job_title` varchar(40) not null,
`ip` varchar(30) not null);

create table `addresses` (
`id` int primary key auto_increment,
`address` varchar(30) not null,
`town` varchar(30) not null,
`country` varchar(30) not null,
`user_id` int not null,
constraint fk_user_address foreign key (user_id) references users(id));

create table `photos` (
`id` int primary key auto_increment,
`description` text not null,
`date` datetime not null,
`views` int not null default 0);

create table `comments` (
`id` int primary key auto_increment,
`comment` varchar(255) not null,
`date` datetime not null,
`photo_id` int not null,
constraint fk_photo_comment foreign key (photo_id) references photos(id));

create table `users_photos` (
`user_id` int not null,
`photo_id` int not null,
key pk_user_photo (user_id, photo_id),
constraint fk_user foreign key (user_id) references users(id),
constraint fk_photo foreign key (photo_id) references photos(id));

create table `likes` (
`id` int primary key auto_increment,
`photo_id` int, `user_id` int,
constraint fk_photo_like foreign key (photo_id) references photos(id),
constraint fk_user_like foreign key (user_id) references users(id));

-- Section 2: Data Manipulation Language(DML)
-- 2. Insert

insert into addresses (`address`, `town`, `country`, `user_id`)
select `username`, `password`, `ip`, `age` from users
where `gender` = 'M';

-- 3. Update

update addresses set `country` = 
case 
when left(`country`, 1) = 'B' then 'Blocked'
when left(`country`, 1) = 'T' then 'Test'
when left(`country`, 1) = 'P' then 'In Progress'
else `country`
end;

-- 4. Delete

delete from addresses where `id` % 3 = 0;

-- Section 3; Querying
-- 5. Users

select `username`, `gender`, `age` from users
order by `age` desc, `username` asc;

-- 6. Exctract 5 most commented photos

select p.`id`, p.`date`, p.`description`, count(c.`id`) as commentsCount
from comments as c join photos as p on c.photo_id = p.id
group by c.photo_id order by commentsCount desc, p.id limit 5;

-- 7. Lucky users

select concat_ws(' ', u.`id`, u.`username`) as id_username, u.`email`
from users as u join users_photos as up on u.`id` = up.`user_id`
where up.`user_id` = up.`photo_id` order by u.id;

-- 8. Count likes and comments

select p.id,
(select count(id) from likes where `photo_id` = p.id) as likes_count,
(select count(id) from comments where `photo_id` = p.id) as comments_count
from photos as p order by likes_count desc, comments_count desc, p.id;

-- 9. The photo on the tenth day of the month

select concat(left(`description`,30), '...') as summary, `date`
from photos where day(`date`) = 10
order by `date` desc;

DELIMITER $$
-- Section 4: Programmability 
-- 10. Get users photo count

create function udf_users_photos_count(username VARCHAR(30))
returns int deterministic
begin
    declare photosCount int;
    set photosCount := (
         select count(up.photo_id) from users_photos as up
         join users as u on u.id = up.user_id
         where u.username = username);
    return photosCount;
    end;
    
-- 11. Increase user age

create procedure udp_modify_user (address varchar(30), town varchar(30))
begin
    update users as u join addresses as a
    on a.user_id = u.id
    set u.age = u.age + 10
    where a.address = address and a.town = town;
    end;
    





