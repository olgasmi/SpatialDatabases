create database lab5;

create table objects (
	geom_id int primary key not null,
	name varchar(50) not null,
	geom geometry 	
);


--ex1
insert into objects values (
	1, 'obiekt1', ST_Collect(array[ST_GeomFromText('LINESTRING(0 0, 1 1)'),
                              ST_GeomFromText('CIRCULARSTRING(1 1, 2 0, 3 1)'),
                              ST_GeomFromText('LINESTRING(5 1, 6 1)'),
                              ST_GeomFromText('CIRCULARSTRING(3 1, 4 2, 5 1)')]));

insert into objects values (
	2, 'obiekt2', ST_Collect(array[ST_GeomFromText('LINESTRING(10 6, 10 2)'),
                              ST_GeomFromText('CIRCULARSTRING(10 2, 12 0, 14 2)'),
                              ST_GeomFromText('CIRCULARSTRING(14 2, 16 4, 14 6)'),
                              ST_GeomFromText('LINESTRING(14 6, 10 6)'),
                              ST_GeomFromText('CIRCULARSTRING(11 2, 12 1, 13 2)'),
                              ST_GeomFromText('CIRCULARSTRING(13 2, 12 3, 11 2)')]));


insert into objects values (
	3, 'obiekt3', ST_GeomFromText('POLYGON((7 15, 12 13, 10 17, 7 15))'));
	

insert into objects values (
	4, 'obiekt4', ST_Collect(array[ST_GeomFromText('LINESTRING(20.5 19.5, 22 19)'),
                              ST_GeomFromText('LINESTRING(22 19, 26 21)'),
                              ST_GeomFromText('LINESTRING(26 21, 25 22)'),
                              ST_GeomFromText('LINESTRING(25 22, 27 24)'),
                              ST_GeomFromText('LINESTRING(27 24, 25 25)'),
                              ST_GeomFromText('LINESTRING(25 25, 20 20)')]));
                              
                             
insert into objects values (
	5, 'obiekt5', ST_Collect(ST_GeomFromText('POINT(30 30 59)'),
                             ST_GeomFromText('POINT(38 32 234)')));
                             
                             
insert into objects values (
	6, 'obiekt6', ST_Collect(array[ST_GeomFromText('LINESTRING(1 1, 3 2)'),
                              ST_GeomFromText('POINT(4 2)')]));


select * from objects;


--ex2
select 
	ST_Area(ST_Buffer(ST_ShortestLine(obiekt3.geom, obiekt4.geom), 5))
from
(select geom from objects where geom_id = 3) as obiekt3,
(select geom from objects where geom_id = 4) as obiekt4;


--ex3
update objects
set geom =  ST_GeomFromText('POLYGON((26 21, 22 19, 20.5 19.5, 20 20, 25 25, 27 24, 25 22, 26 21))')
where geom_id = 4;

select * from objects where geom_id = 4;


--ex4
insert into objects values (
	7, 'obiekt7', (select 
						ST_Collect(obiekt3.geom, obiekt4.geom)
				   from
				   (select geom from objects where geom_id = 3) as obiekt3,
                   (select geom from objects where geom_id = 4) as obiekt4));

select * from objects where geom_id = 7;


--ex5
select
	geom_id,
	name, 
	geom,
	ST_Area(ST_Buffer(geom, 5))
from objects 
where 
	ST_HasArc(geom) = false; 