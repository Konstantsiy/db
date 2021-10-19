-- select 'create database postgres'
-- where not exists(select from pg_database where datname = 'postgres');
-- \gexec
--
-- \c postgres

create schema if not exists cinema;

-- do $$
--     begin
--         if not exists(select 1 from pg_extension where extname = 'uuid-ossp') then
--             create extension "uuid-ossp" with schema cinema;
--         end if;
--     end
-- $$;

do $$
    begin
        if not exists(select 1 from pg_type where typname = 'hall_sector') then
            create type hall_sector as enum ('near the screen', 'center', 'balcony');
        end if;
    end
$$;

do $$
    begin
        if not exists(select 1 from pg_type where typname = 'hall_type') then
            create type hall_type as enum ('2D', '3D', 'IMAX');
        end if;
    end
$$;

set intervalstyle = 'postgres';

create or replace function random_sequence10() returns varchar(10) as
$$
declare
    chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N}';
    result varchar(10) := '';
    i integer := 0;
begin
    for i in 1..10 loop
            result := result || chars[1+random()*(array_length(chars, 1)-1)];
        end loop;
    return result;
end;
$$ language plpgsql;

create table if not exists cinema.genres (
                                             id uuid default uuid_generate_v1() primary key,
                                             title varchar(80) not null
);

create table if not exists cinema.films (
                                            id uuid default uuid_generate_v1() primary key,
                                            title varchar(120) not null unique,
                                            duration interval not null check (interval '40 minutes' < duration and duration < interval '3 hours 30 minutes'),
                                            rental_start_date date not null check ( rental_start_date > current_date ),
                                            rental_end_date date not null check ( rental_end_date > rental_start_date )
);

create table if not exists cinema.films_genres (
                                                   film_id uuid references cinema.films(id) on delete cascade,
                                                   genre_id uuid references cinema.genres(id) on delete cascade,
                                                   constraint film_genre_pkey primary key (film_id, genre_id)
);

create table if not exists cinema.positions (
                                                id uuid default uuid_generate_v1() primary key,
                                                title varchar(120) not null unique
);

create table if not exists cinema.workers (
                                              id uuid default uuid_generate_v1() primary key,
                                              position_id uuid not null,
                                              name varchar(45) not null,
                                              surname varchar(45) not null,
                                              passport_number varchar(10) not null unique default random_sequence10(),
                                              foreign key (position_id) references cinema.positions(id) on delete cascade
);

create table if not exists cinema.halls (
                                            id uuid default uuid_generate_v1() primary key,
                                            number integer not null unique,
                                            type hall_type not null
);

create table if not exists cinema.halls_workers (
                                                    hall_id uuid references cinema.halls(id) on delete cascade,
                                                    worker_id uuid references cinema.workers(id) on delete cascade,
                                                    sector hall_sector not null
);

create table if not exists cinema.places (
                                             id uuid default uuid_generate_v1() primary key,
                                             row_number integer not null,
                                             place_number integer not null
);

create table if not exists cinema.halls_places (
                                                   hall_id uuid references cinema.halls(id) on delete cascade,
                                                   place_id uuid references cinema.places(id) on delete cascade,
                                                   constraint hall_place primary key (hall_id, place_id)
);

create table if not exists cinema.sessions (
                                               id uuid default uuid_generate_v1() primary key,
                                               film_id uuid not null,
                                               hall_id uuid not null,
                                               date date not null check ( date > current_date ),
                                               time time not null check ( time < time '23:00' and time > time '10:00'),
                                               foreign key (film_id) references cinema.films(id) on delete cascade,
                                               foreign key (hall_id) references cinema.halls(id) on delete cascade
);

create table if not exists cinema.tickets (
                                              id uuid default uuid_generate_v1() primary key,
                                              session_id uuid not null,
                                              worker_id uuid not null,
                                              price numeric(8, 2) not null check ( price > 0 and price < 60 ),
                                              foreign key (session_id) references cinema.sessions(id) on delete cascade,
                                              foreign key (worker_id) references cinema.workers(id)
);

create table if not exists cinema.tickets_places (
                                                     ticket_id uuid references cinema.tickets(id) on delete cascade,
                                                     place_id uuid references cinema.places(id) on delete cascade,
                                                     constraint ticket_place primary key (ticket_id, place_id)
);

-- --------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------
insert into cinema.genres (title)
values ('horror'),
       ('fantasy'),
       ('action'),
       ('drama'),
       ('comedy'),
       ('thriller');
select * from cinema.genres;

insert into cinema.films (title, duration, rental_start_date, rental_end_date)
values ('365 Days', interval '118 minutes', date '2021-10-15', date '2021-10-30'),
       ('The Courier', interval '114 minutes', date '2021-10-16', date '2021-10-27'),
       ('Tenet', interval '150 minutes', date '2021-10-11', date '2021-10-19'),
       ('News of the World', interval '120 minutes', date '2021-10-16', date '2021-10-30'),
       ('Extraction', interval '116 minutes', date '2021-11-01', date '2021-11-15'),
       ('The Night House', interval '107 minutes', date '2021-11-03', date '2021-11-17');
select * from cinema.films;

insert into cinema.films_genres (film_id, genre_id)
values ('73e176be-2607-11ec-8491-61ceeb4939bd', 'a9e58242-2606-11ec-8491-61ceeb4939bd'),
       ('73e176be-2607-11ec-8491-61ceeb4939bd', 'a9e58247-2606-11ec-8491-61ceeb4939bd'),
       ('73e176bf-2607-11ec-8491-61ceeb4939bd', 'a9e58243-2606-11ec-8491-61ceeb4939bd'),
       ('73e176c0-2607-11ec-8491-61ceeb4939bd', 'a9e58246-2606-11ec-8491-61ceeb4939bd'),
       ('73e176c1-2607-11ec-8491-61ceeb4939bd', 'a9e58245-2606-11ec-8491-61ceeb4939bd'),
       ('73e176c2-2607-11ec-8491-61ceeb4939bd', 'a9e58244-2606-11ec-8491-61ceeb4939bd'),
       ('73e176c2-2607-11ec-8491-61ceeb4939bd', 'a9e58242-2606-11ec-8491-61ceeb4939bd'),
       ('73e176c3-2607-11ec-8491-61ceeb4939bd', 'a9e58244-2606-11ec-8491-61ceeb4939bd');
select * from cinema.films_genres;

insert into cinema.films_genres (film_id, genre_id)
values ('73e176c2-2607-11ec-8491-61ceeb4939bd', 'a9e58246-2606-11ec-8491-61ceeb4939bd');


insert into cinema.positions (title)
values ('cashier'),
       ('cleaner'),
       ('technical operator');
select * from cinema.positions;

insert into cinema.positions (title)
values ('guard');

insert into cinema.workers (position_id, name, surname, passport_number)
values ('d2f7c9ae-2608-11ec-8491-61ceeb4939bd', 'John', 'Wick', random_sequence10()),
       ('d2f7c9af-2608-11ec-8491-61ceeb4939bd', 'Aldo', 'Apache', random_sequence10()),
       ('d2f7c9b0-2608-11ec-8491-61ceeb4939bd', 'Tony', 'Stark', random_sequence10()),
       ('d2f7c9b0-2608-11ec-8491-61ceeb4939bd', 'James', 'Burton', random_sequence10());
select * from cinema.workers;

-- cashiers++
insert into cinema.workers (position_id, name, surname, passport_number)
values ('d2f7c9ae-2608-11ec-8491-61ceeb4939bd', 'Emily', 'Black', random_sequence10()),
       ('d2f7c9ae-2608-11ec-8491-61ceeb4939bd', 'Jojo', 'Rabbit', random_sequence10());
select * from cinema.workers;
-- guards++
insert into cinema.workers (position_id, name, surname, passport_number)
values ('946c22ca-2739-11ec-92c0-415fe2b495ad', 'Will', 'Smith', random_sequence10()),
       ('946c22ca-2739-11ec-92c0-415fe2b495ad', 'Thomas', 'Hanks', random_sequence10());
select * from cinema.workers;


insert into cinema.places (row_number, place_number)
values (1, 1), (1, 2), (1, 3),
       (2, 1), (2, 2), (2, 3),
       (3, 1), (3, 2), (3, 3);
select * from cinema.places;

-- drop table cinema.tickets cascade;

-- alter table cinema.films add country varchar(40) not null ;

insert into cinema.halls (number, type)
values (1, '2D'), (2, '3D'), (3, 'IMAX');
select * from cinema.halls;

-- insert into cinema.halls (number, type)
-- values (1, '2D'),
--        (2, '3D'),
--        (3, 'IMAX');
-- select * from cinema.halls;

insert into cinema.halls_workers (hall_id, worker_id, sector)
values ('1e004ba6-2609-11ec-8491-61ceeb4939bd', 'f8f4c059-2608-11ec-8491-61ceeb4939bd', 'near the screen'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '7b99b226-260d-11ec-8491-61ceeb4939bd', 'center'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '7b99b227-260d-11ec-8491-61ceeb4939bd', 'balcony'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', 'f8f4c05a-2608-11ec-8491-61ceeb4939bd', 'near the screen'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', 'f8f4c059-2608-11ec-8491-61ceeb4939bd', 'center'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '7b99b226-260d-11ec-8491-61ceeb4939bd', 'balcony'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '7b99b227-260d-11ec-8491-61ceeb4939bd', 'near the screen'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', 'f8f4c05b-2608-11ec-8491-61ceeb4939bd', 'center'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', 'f8f4c05b-2608-11ec-8491-61ceeb4939bd', 'balcony');
select * from cinema.halls_workers;

insert into cinema.halls_places (hall_id, place_id)
values ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa422-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa423-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa424-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa425-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa426-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa427-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa428-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa429-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba6-2609-11ec-8491-61ceeb4939bd', '0d5fa42a-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa422-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa423-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa424-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa425-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa426-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa427-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa428-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa429-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba7-2609-11ec-8491-61ceeb4939bd', '0d5fa42a-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa422-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa423-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa424-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa425-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa426-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa427-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa428-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa429-2609-11ec-8491-61ceeb4939bd'),
       ('1e004ba8-2609-11ec-8491-61ceeb4939bd', '0d5fa42a-2609-11ec-8491-61ceeb4939bd');
select * from cinema.halls_places;

insert into cinema.sessions (film_id, hall_id, date, time)
values ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-10-17', time '17:30:00'),
       ('73e176c1-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-10-17', time '17:30:00');


insert into cinema.sessions (film_id, hall_id, date, time)
values        ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-25', time '19:00:00');


insert into cinema.sessions (film_id, hall_id, date, time)
values ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-17', time '14:30:00'),
       ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-10-20', time '16:30:00'),
       ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-10-25', time '19:00:00'),


       ('73e176bf-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-19', time '11:30:00'),
       ('73e176bf-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-10-18', time '18:30:00'),
       ('73e176bf-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-10-26', time '21:00:00'),

       ('73e176c0-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-12', time '11:30:00'),
       ('73e176c0-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-10-15', time '13:30:00'),
       ('73e176c0-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-10-18', time '20:00:00'),

       ('73e176c1-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-18', time '12:30:00'),
       ('73e176c1-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-10-22', time '15:30:00'),
       ('73e176c1-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-10-28', time '21:15:00'),

       ('73e176c2-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-11-03', time '13:30:00'),
       ('73e176c2-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-11-10', time '16:30:00'),
       ('73e176c2-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-11-12', time '21:40:00'),

       ('73e176c3-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-11-05', time '14:00:00'),
       ('73e176c3-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-11-11', time '17:30:00'),
       ('73e176c3-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-11-16', time '22:00:00');
select * from cinema.sessions;

insert into cinema.tickets (session_id, worker_id, price, payment_date)
values ('463a9ba4-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 30.50, date '2021-10-16'),
       ('463a9ba4-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 20.25, date '2021-10-16'),
       ('463a9ba4-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 48, date '2021-10-17'),

       ('463a9ba5-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 21.50, date '2021-10-19'),
       ('463a9ba5-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 25.25, date '2021-10-20'),
       ('463a9ba5-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 30, date '2021-10-20'),

       ('463a9ba6-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 12.50, date '2021-10-24'),
       ('463a9ba6-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 21.50, date '2021-10-24'),
       ('463a9ba6-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 35, date '2021-10-25'),

       ('463a9ba7-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 17, date '2021-10-18'),
       ('463a9ba7-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 25.50, date '2021-10-19'),
       ('463a9ba7-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 50, date '2021-10-19'),

       ('463a9ba8-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 30, date '2021-10-17'),
       ('463a9ba8-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 20.25, date '2021-10-18'),
       ('463a9ba8-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 48, date '2021-10-18'),

       ('463a9ba9-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 35.50, date '2021-10-24'),
       ('463a9ba9-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 25.25, date '2021-10-25'),
       ('463a9ba9-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 48, date '2021-10-26'),

       ('463a9baa-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 30.50, date '2021-10-12'),
       ('463a9baa-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 20.25, date '2021-10-12'),
       ('463a9baa-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 48, date '2021-10-12'),

       ('463a9bab-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 20, date '2021-10-14'),
       ('463a9bab-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 20, date '2021-10-15'),
       ('463a9bab-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 35, date '2021-10-15'),

       ('463a9bac-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 15, date '2021-10-16'),
       ('463a9bac-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 30, date '2021-10-17'),
       ('463a9bac-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 50, date '2021-10-18'),

       ('463a9bad-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 35, date '2021-10-18'),
       ('463a9bad-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 15.50, date '2021-10-18'),
       ('463a9bad-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 35, date '2021-10-18'),

       ('463a9bae-261c-11ec-8491-61ceeb4939bd', 'f8f4c058-2608-11ec-8491-61ceeb4939bd', 35.50, date '2021-10-21'),
       ('463a9bae-261c-11ec-8491-61ceeb4939bd', '9907212e-261f-11ec-8491-61ceeb4939bd', 15, date '2021-10-22'),
       ('463a9bae-261c-11ec-8491-61ceeb4939bd', '9907212f-261f-11ec-8491-61ceeb4939bd', 40.50, date '2021-10-22');
select * from cinema.tickets;


-- -----------------------------------------------------------------------
-- -----------------------------------------------------------------------
select t.price, t.payment_date, s.date, s.time, w.surname
from cinema.tickets t
join cinema.sessions s on t.session_id = s.id
join cinema.workers w on t.worker_id = w.id
where w.surname similar to '%bbi%';

insert into cinema.sessions (film_id, hall_id, date, time)
values ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-07', time '10:30:00'),
       ('73e176c0-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-10-07', time '10:30:00'),
       ('73e176c2-2607-11ec-8491-61ceeb4939bd', '1e004ba8-2609-11ec-8491-61ceeb4939bd', date '2021-10-07', time '11:45:00'),
       ('73e176c3-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-07', time '12:00:00'),
       ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-10-07', time '16:30:00');

select format('%s %s, №%s', s.date, s.time, h.number, g.title)
from cinema.sessions s
join cinema.halls h on s.hall_id = h.id
join cinema.films_genres fg on s.film_id = fg.film_id
join cinema.genres g on fg.genre_id = g.id
where g.title in ('thriller', 'action') and g.title != 'comedy' and s.time < current_time
order by s.date;

select distinct p.title
from cinema.positions p
join cinema.workers w on w.position_id = p.id
join cinema.halls_workers hw on w.id = hw.worker_id
join cinema.sessions s on s.hall_id = hw.hall_id
join cinema.films f on f.id = s.film_id
where f.rental_start_date > current_date;
-- -----------------------------------------------------------------------
-- -----------------------------------------------------------------------
-- query_1
select tab.number as hall_number, max(c) as sessions_count
from (
    select f.title, h.number, count(s.id) as c
    from cinema.films f
    join cinema.sessions s
    on s.film_id = f.id and s.date > current_date
    join cinema.halls h
    on h.id = s.hall_id
    group by f.title, h.number
) as tab
group by tab.number order by tab.number;
-- ---------------------------------------------------------------
select h.number as hall_number, f.title as film_title, count(s.id) as count
from cinema.films f
join cinema.sessions s
on s.film_id = f.id and s.date > current_date
join cinema.halls h
on h.id = s.hall_id
group by f.title, h.number;


with hall_film_counts as (
    -- выводим количество сеансов, которые запланированы для каждого фильмы в каждом зале
    select h.number as hall_number, f.title, count(s.id) as c
    from cinema.films f
             join cinema.sessions s
                  on s.film_id = f.id and s.date > current_date
             join cinema.halls h
                  on h.id = s.hall_id
    group by f.title, h.number
) select t1.hall_number, max(t1.c) as max_c
    from hall_film_counts t1
    group by t1.hall_number;
-- ######################################################################################

with hall_film_counts as (
    -- выделяем количество сеансов, которые запланированы для каждого фильмы в каждом зале
    select h.number as hall_number, f.title, count(s.id) as c
    from cinema.films f
        join cinema.sessions s
            on s.film_id = f.id and s.date > current_date
        join cinema.halls h
            on h.id = s.hall_id
    group by f.title, h.number
), title_max_counts as (
    -- выделяем максимальное количество сеансов в каждом зале
    select t1.hall_number, max(t1.c) as max_c
    from hall_film_counts t1
    group by t1.hall_number
) -- уникально выделяем соответсвия между популярными фильмами и максимальным количеством сеансов
select t1.hall_number as hall_number, t1.title as film_title, t1.c as max_sessions_count
from hall_film_counts t1
    join title_max_counts t2
        on t1.hall_number = t2.hall_number and t1.c = t2.max_c
order by t1.hall_number;

select * from cinema.films;

-- ######################################################################################
-- ----------------------------------------------------------------
-- query_2
select p.title, h.number
from cinema.workers w
join cinema.positions p
on p.id = w.position_id
join cinema.halls_workers hw
on hw.worker_id = w.id
join cinema.halls h
on h.id = hw.hall_id
group by h.number, p.title;

-- position --- halls count
with position_hall as (
    select p.title as position_title, h.number as hall_number
    from cinema.workers w
    join cinema.positions p
    on p.id = w.position_id
    join cinema.halls_workers hw
    on hw.worker_id = w.id
    join cinema.halls h
    on h.id = hw.hall_id
    group by h.number, p.title
) select ph.position_title, count(*) as halls_count
from position_hall ph
group by ph.position_title;

-- position --- sectors count
with position_sector as (
    select p.title as position_title, h.number as hall_number, hw.sector as hall_sector
    from cinema.workers w
    join cinema.positions p
    on w.position_id = p.id
    join cinema.halls_workers hw
    on w.id = hw.worker_id
    join cinema.halls h
    on h.id = hw.hall_id
    group by p.title, h.number, hw.sector
) select ps.position_title, count(*) as sectors_count
from position_sector ps
group by ps.position_title;
-- ---------------------------------------------
with position_sector as ( -- выделяем секторы и привязанные к ним должности
    select p.title as position_title, h.number as hall_number, hw.sector as hall_sector
    from cinema.workers w
             join cinema.positions p
                  on w.position_id = p.id
             join cinema.halls_workers hw
                  on w.id = hw.worker_id
             join cinema.halls h
                  on h.id = hw.hall_id
    group by p.title, h.number, hw.sector
) select ps.position_title as __position_title, count(*) as __sectors_count
from position_sector ps
group by ps.position_title;
-- ######################################################################################
with p_h as ( -- выделяем, сколько залов закреплено за каждой должностью
    with position_hall as ( -- выделяем залы и привязанные к ним должности
        select p.title as position_title, h.number as hall_number
        from cinema.workers w
            join cinema.positions p
                on p.id = w.position_id
            join cinema.halls_workers hw
                on hw.worker_id = w.id
            join cinema.halls h
                on h.id = hw.hall_id
        group by h.number, p.title
    ) select ph.position_title as __position_title, count(*) as __halls_count
    from position_hall ph
    group by ph.position_title
), p_s as ( -- выделяем, сколько секторов закреплено за каждой должностью в каждом зале
    with position_sector as ( -- выделяем секторы и привязанные к ним должности
        select p.title as position_title, h.number as hall_number, hw.sector as hall_sector
        from cinema.workers w
            join cinema.positions p
                on w.position_id = p.id
            join cinema.halls_workers hw
                on w.id = hw.worker_id
            join cinema.halls h
                on h.id = hw.hall_id
        group by p.title, h.number, hw.sector
    ) select ps.position_title as __position_title, count(*) as __sectors_count
    from position_sector ps
    group by ps.position_title
) select p_h.__position_title as position, p_h.__halls_count as halls, p_s.__sectors_count as sectors
from p_h -- выделяем соотвествия
join p_s
on p_h.__position_title = p_s.__position_title;

-- ######################################################################################
-- -------------------------------------------------------------------
-- query_3
-- place (hall, row, column) --- film --- tickets count
select (h.number, p.row_number, p.place_number) as place, f.title as film, count(tp.ticket_id) as count
from cinema.places p
         join cinema.halls_places hp
              on hp.place_id = p.id
         join cinema.halls h
              on h.id = hp.hall_id and h.number != 2
         join cinema.tickets_places tp
              on tp.place_id = p.id
         join cinema.tickets t
              on t.id = tp.ticket_id
         join cinema.sessions s
              on s.id = t.session_id
         join cinema.films f
              on f.id = s.film_id
group by place, f.title order by place, count desc;


with place_film_counts as (
    select (h.number, p.row_number, p.place_number) as place, f.title as film, count(tp.ticket_id) as count
    from cinema.places p
             join cinema.halls_places hp
                  on hp.place_id = p.id
             join cinema.halls h
                  on h.id = hp.hall_id and h.number != 2
             join cinema.tickets_places tp
                  on tp.place_id = p.id
             join cinema.tickets t
                  on t.id = tp.ticket_id
             join cinema.sessions s
                  on s.id = t.session_id
             join cinema.films f
                  on f.id = s.film_id
    group by h.number, p.row_number, p.place_number, f.title order by h.number, p.row_number, p.place_number
), place_max_count as (
    select t1.place, max(t1.count) as max_c
    from place_film_counts t1
    group by t1.place
) select t1.place as place, t1.film as film, t1.count as max_tickets_count
from place_film_counts t1
join place_max_count t2
on t1.place = t2.place and t1.count = t2.max_c order by t1.place, max_c;

with t1 as (
    select (h.number, p.row_number, p.place_number) as place, f.title as film, count(tp.ticket_id) as count
    from cinema.places p
             join cinema.halls_places hp
                  on hp.place_id = p.id
             join cinema.halls h
                  on h.id = hp.hall_id and h.number != 2
             join cinema.tickets_places tp
                  on tp.place_id = p.id
             join cinema.tickets t
                  on t.id = tp.ticket_id
             join cinema.sessions s
                  on s.id = t.session_id
             join cinema.films f
                  on f.id = s.film_id
    group by place, f.title order by place, count desc
) select t1.place, t1.film, t1.count, row_number() over (partition by t1.place order by t1.count desc)
from t1;
-- ---------------------------------------------------------------------
with place_film_count as ( -- выделяем количество сеансов, запланированное каждое место и на каждый фильм
    select (h.number, p.row_number, p.place_number) as place, f.title as film, count(tp.ticket_id) as count
    from cinema.places p
             join cinema.halls_places hp
                  on hp.place_id = p.id
             join cinema.halls h
                  on h.id = hp.hall_id and h.number != 2
             join cinema.tickets_places tp
                  on tp.place_id = p.id
             join cinema.tickets t
                  on t.id = tp.ticket_id
             join cinema.sessions s
                  on s.id = t.session_id
             join cinema.films f
                  on f.id = s.film_id
    group by place, f.title order by place, count desc
)
    select t1.place as place, t1.film as film, t1.count as count, row_number() over (partition by t1.place order by t1.count desc) as rn
    from place_film_count t1;
-- ######################################################################################

with place_film_count as (
    -- выделяем количество сеансов, запланированное каждое место и на каждый фильм
    select (h.number, p.row_number, p.place_number) as place, f.title as film, count(tp.ticket_id) as count
    from cinema.places p
             join cinema.halls_places hp
                  on hp.place_id = p.id
             join cinema.halls h
                  on h.id = hp.hall_id and h.number != 2
             join cinema.tickets_places tp
                  on tp.place_id = p.id
             join cinema.tickets t
                  on t.id = tp.ticket_id
             join cinema.sessions s
                  on s.id = t.session_id
             join cinema.films f
                  on f.id = s.film_id
    group by place, f.title order by place, count desc
), place_film_countrow_number as (
    -- нумеруем последовательности из фильмов, отсортированных по количеству проданных билетов,
    -- начиная каждую новую последовательность с нового места
    select t1.place as place,
           t1.film as film,
           t1.count as count,
           row_number() over (partition by t1.place order by t1.count desc) as rn
    from place_film_count t1
) -- выделяем первые 4 фильма из каждой последовательности
select t2.place, t2.film, t2.count
from place_film_countrow_number t2
where t2.rn <= 2;

-- ######################################################################################


insert into cinema.tickets_places
values ('bed0d63a-26d2-11ec-9773-a79c19a15566', '0d5fa422-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d63a-26d2-11ec-9773-a79c19a15566', '0d5fa423-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d63a-26d2-11ec-9773-a79c19a15566', '0d5fa424-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d63b-26d2-11ec-9773-a79c19a15566', '0d5fa425-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d63c-26d2-11ec-9773-a79c19a15566', '0d5fa426-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d63c-26d2-11ec-9773-a79c19a15566', '0d5fa427-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d63d-26d2-11ec-9773-a79c19a15566', '0d5fa428-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d63e-26d2-11ec-9773-a79c19a15566', '0d5fa429-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d63e-26d2-11ec-9773-a79c19a15566', '0d5fa42a-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d63f-26d2-11ec-9773-a79c19a15566', '0d5fa422-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d63f-26d2-11ec-9773-a79c19a15566', '0d5fa423-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d640-26d2-11ec-9773-a79c19a15566', '0d5fa424-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d641-26d2-11ec-9773-a79c19a15566', '0d5fa425-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d642-26d2-11ec-9773-a79c19a15566', '0d5fa426-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d643-26d2-11ec-9773-a79c19a15566', '0d5fa427-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d644-26d2-11ec-9773-a79c19a15566', '0d5fa428-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d645-26d2-11ec-9773-a79c19a15566', '0d5fa429-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d646-26d2-11ec-9773-a79c19a15566', '0d5fa42a-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d647-26d2-11ec-9773-a79c19a15566', '0d5fa422-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d648-26d2-11ec-9773-a79c19a15566', '0d5fa423-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d649-26d2-11ec-9773-a79c19a15566', '0d5fa424-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d64a-26d2-11ec-9773-a79c19a15566', '0d5fa425-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d64b-26d2-11ec-9773-a79c19a15566', '0d5fa426-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d64c-26d2-11ec-9773-a79c19a15566', '0d5fa427-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d64d-26d2-11ec-9773-a79c19a15566', '0d5fa428-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d64e-26d2-11ec-9773-a79c19a15566', '0d5fa429-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d64f-26d2-11ec-9773-a79c19a15566', '0d5fa42a-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d650-26d2-11ec-9773-a79c19a15566', '0d5fa422-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d651-26d2-11ec-9773-a79c19a15566', '0d5fa423-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d652-26d2-11ec-9773-a79c19a15566', '0d5fa424-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d652-26d2-11ec-9773-a79c19a15566', '0d5fa425-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d652-26d2-11ec-9773-a79c19a15566', '0d5fa426-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d652-26d2-11ec-9773-a79c19a15566', '0d5fa427-2609-11ec-8491-61ceeb4939bd'),

       ('bed0d657-26d2-11ec-9773-a79c19a15566', '0d5fa428-2609-11ec-8491-61ceeb4939bd'),
       ('bed0d657-26d2-11ec-9773-a79c19a15566', '0d5fa429-2609-11ec-8491-61ceeb4939bd');
select * from cinema.tickets_places;
-- ------------------------------------------------------------------
-- ------------------------------------------------------------------
insert into cinema.halls (number, type)
values (4, '2D'), (5, '3D'), (6, 'IMAX');
select * from cinema.halls;

-- view all unmentioned halls
select hls.id
from cinema.halls hls
where hls.id not in (
    select distinct h.id
    from cinema.halls h
    join cinema.sessions s
    on s.hall_id = h.id
);

-- ------------------------------------------------------------------------------------
-- SELECTION 1
-- ------------------------------------------------------------------------------------

begin transaction;
with next_monday as ( -- нахождение даты следующего понедельника
    select (date_trunc('week', current_date)+interval '7 days')::date as day
) -- вставка фильма на неделю, начиная со следующего понедельника
insert into cinema.films(title, duration, rental_start_date, rental_end_date)
values ('Человек-амфибия 3', interval '118 minutes', (select * from next_monday), ((select * from next_monday)+interval '7 days')::date);

insert into cinema.sessions (film_id, hall_id, date, time)
with sessions_selection as (
    with next_monday as ( -- нахождение даты следующего понедельника
        select (date_trunc('week', current_date)+interval '7 days')::date as day
    ), added_film_id as ( -- поиск только что добавленного фильма по названию
        select f.id from cinema.films f where f.title = 'Человек-амфибия 3' limit 1
    ), free_halls_id as ( -- нахождение всех свободных заллов
        select hls.id as hall_id from cinema.halls hls
        where hls.id not in (
            select distinct h.id from cinema.halls h join cinema.sessions s on s.hall_id = h.id
        )
    ), next_week_days as ( -- выделение последовательности дней следующей недели, начиная с понедельника
        select day::date as day_date
        from generate_series((select * from next_monday), ((select * from next_monday) + interval '7 days')::date, interval '1 day') day
    ), films_halls as ( -- фильмы и свободные заллы
        select (select * from added_film_id) as film_id, free.hall_id from free_halls_id free where free.hall_id::text != ''
    ), films_dates as ( -- фильмы и даты сеансов
        select (select * from added_film_id) as film_id, next_week_days.day_date as s_date
        from next_week_days where next_week_days.day_date::text != ''
    ) -- выделение совпадений по id фильмов
    select fh.film_id as s_film_id, fh.hall_id as s_hall_id, fd.s_date as s_date, time '21:00:00' as s_time
    from films_halls fh join films_dates fd on fh.film_id = fd.film_id
)
select ss.s_film_id, ss.s_hall_id, ss.s_date, ss.s_time  from sessions_selection ss;
commit;

-- ------------------------------------------------------------------------------------
-- c4fee89a-3112-11ec-a457-d12111e544d5
select * from cinema.sessions;
select * from cinema.films;
-- ------------------------------------------------------------------------------------
-- SELECTION 2
-- ------------------------------------------------------------------------------------
update cinema.tickets set price = 0.85 * price
where id in (
    select t.id from cinema.tickets t
    join cinema.sessions s
    on t.session_id = s.id and t.payment_date is null and s.id in (
        select s.id, s.time
        from cinema.sessions s
        where (s.time - interval '2 hours') <= current_time
    )
);
-- ------------------------------------------------------------------------------------
-- SELECTION 3
-- ------------------------------------------------------------------------------------
insert into cinema.sessions (film_id, hall_id, date, time)
values ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-09-07', time '10:30:00'),
       ('73e176c0-2607-11ec-8491-61ceeb4939bd', '1e004ba7-2609-11ec-8491-61ceeb4939bd', date '2021-09-07', time '10:30:00');
-- ------------------------------------------------------------------------------------
insert into cinema.tickets (session_id, worker_id, price, payment_date)
values ('1daed92a-3125-11ec-a457-d12111e544d5', '9907212e-261f-11ec-8491-61ceeb4939bd', 20.25, date '2021-10-14'),
       ('1daed92a-3125-11ec-a457-d12111e544d5', '9907212f-261f-11ec-8491-61ceeb4939bd', 48, date '2021-10-14'),

       ('1daed92b-3125-11ec-a457-d12111e544d5', '9907212e-261f-11ec-8491-61ceeb4939bd', 25.25, date '2021-10-15'),
       ('1daed92b-3125-11ec-a457-d12111e544d5', '9907212f-261f-11ec-8491-61ceeb4939bd', 30, date '2021-10-20');

select * from cinema.sessions;

-- ------------------------------------------------------------------------------------

insert into cinema.sessions (film_id, hall_id, date, time)
values ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-21', time '14:30:00'),
       ('73e176be-2607-11ec-8491-61ceeb4939bd', '1e004ba6-2609-11ec-8491-61ceeb4939bd', date '2021-10-20', time '14:30:00');

with sessions_selection as (
    select s.id as session_id, s.date as session_date, s.time as session_time, count(t.id) as tickets_count from cinema.sessions s
    join cinema.tickets t
    on t.session_id = s.id
    group by s.id
) select * from sessions_selection;

begin transaction;
with sessions_selection as (
    -- выделение всех завершенных сеансов за последний месяц
    select s.id as session_id, s.date as session_date, s.time as session_time, count(t.id) as tickets_count
    from cinema.sessions s
    join cinema.tickets t
    on t.session_id = s.id
        and s.date > date_trunc('month', current_date)
        and ((s.date != current_date and s.date < current_date) or (s.date = current_date and s.time < current_time))
    group by s.id
)
delete from cinema.sessions s
where s.id in (
    select ss.session_id from sessions_selection ss where ss.tickets_count <= 3
);
commit;
