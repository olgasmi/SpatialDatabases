--ex2
create database lab2;

--ex3
create extension postgis;

--ex4
create table if not exists building (id integer primary key, geom geometry, name varchar(255));
create table if not exists roads (id integer primary key, geom geometry, name varchar(255));
create table if not exists poi (id integer primary key, geom geometry, name varchar(255));

--ex5
insert into building values 
	(1, 'POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', 'BuildingA'),
	(2, 'POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', 'BuildingB'),
	(3, 'POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', 'BuildingC'),
	(4, 'POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', 'BuildingD'),
	(5, 'POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', 'BuildingE');
	
insert into roads values 
	(1, 'LINESTRING(0 4.5, 12 4.5)', 'RoadX'),
	(2, 'LINESTRING(7.5 10.5, 7.5 0)', 'RoadY');
	
insert into poi values 
	(1, 'POINT(5.5 1.5)', 'H'),
	(2, 'POINT(1 3.5)', 'G'),
	(3, 'POINT(9.5 6)', 'I'),
	(4, 'POINT(6.5 6)', 'J'),
	(5, 'POINT(6 9.5)', 'K');
	
--ex6
--a
select SUM(ST_Length(geom)) from roads;

--b
select 
	ST_AsText(geom) as WKT, 
	ST_Area(geom) as Area, 
	ST_Perimeter(geom) as Perimeter 
from building where name = 'BuildingA';

--c
select name, ST_Area(geom) as Area from building order by name;

--d
select name, ST_Perimeter(geom) as Area from building order by ST_Area(geom) desc limit 2;

--e
select 
	ST_Distance(b.geom, p.geom) as Distance 
from building b 
cross join poi p 
where b.name = 'BuilidngB' and p.name ='K' ;

--f
with geom_BuildingB as (select geom from building where name = 'BuildingB'),
     geom_BuildingC as (select geom from building where name = 'BuildingC'),
     helper as (
     	select 
     		b.geom as geom_BuildingB,
     		c.geom as geom_BuildingC
     	from geom_BuildingB as b cross join geom_BuildingC as c),
     intersection_bc as (
     	select 
     		geom_BuildingC, ST_Intersection(ST_Buffer(geom_BuildingB, 0.5), geom_BuildingC) as intersection_bc
     	from helper)
     
select ST_Area(geom_BuildingC) - ST_Area(intersection_bc) from intersection_bc;

--g
with centroids as (
	select 
		b.name as building_name, 
		ST_Centroid(b.geom) as building_centroid,
		ST_Centroid(r.geom) as road_centroid
	from building b
	cross join roads as r
	where 
		r.name = 'RoadX')

select building_name
from centroids
where ST_Y(building_centroid) > ST_Y(road_centroid);

--h 
select
	ST_Area(ST_Union(geom, 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')) 
	- ST_Area(ST_Intersection(geom, 'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))
from building 
where name = 'BuildingC';