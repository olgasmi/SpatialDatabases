create database lab3
--ex1
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2018_KAR_BUILDINGS.shp t2018_kar_buildings | psql -U postgres -h localhost -p 5432 -d lab3
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2019_KAR_BUILDINGS.shp t2019_kar_buildings | psql -U postgres -h localhost -p 5432 -d lab3


with new_buildings as (
	select 
		tkb2019.gid, tkb2019.polygon_id, tkb2019.name, tkb2019.type, tkb2019.height, tkb2019.geom 
	from t2019_kar_buildings tkb2019 
	left join t2018_kar_buildings tkb2018 
	on tkb2019.geom = tkb2018.geom  
	where tkb2018.gid is null )
	
select * from new_buildings


--ex2
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2018_KAR_POI_TABLE.shp t2018_kar_poi_table | psql -U postgres -h localhost -p 5432 -d lab3
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2019_KAR_POI_TABLE.shp t2019_kar_poi_table | psql -U postgres -h localhost -p 5432 -d lab3

with new_points as (
	select 
		tkpt2019.gid, tkpt2019.poi_id, tkpt2019.link_id, tkpt2019.type, tkpt2019.poi_name, tkpt2019.st_name, tkpt2019.lat, tkpt2019.lon, tkpt2019.geom 
	from t2019_kar_poi_table tkpt2019
	left join t2018_kar_poi_table tkpt2018
	on tkpt2019.geom = tkpt2018.geom  
	where tkpt2018.gid is null ),
	
	new_buildings as (
	select 
		tkb2019.gid, tkb2019.polygon_id, tkb2019.name, tkb2019.type, tkb2019.height, tkb2019.geom 
	from t2019_kar_buildings tkb2019 
	left join t2018_kar_buildings tkb2018 
	on tkb2019.geom = tkb2018.geom  
	where tkb2018.gid is null ),
	
	res as (
	select p.poi_id, p.type, p.poi_name 
	from new_buildings b 
	join new_points p 
	on ST_DWITHIN(p.geom, b.geom, 500) --returns true if the geometries are within a given distance
	)
	
	
select distinct count(poi_id), type from res group by type


--ex3
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2019_KAR_STREETS.shp t2019_kar_streets | psql -U postgres -h localhost -p 5432 -d lab3
select * from t2019_kar_streets tks 

select gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel, ST_Transform(ST_SetSRID(geom, 4326), 3068) geom 
into streets_reprojected
from t2019_kar_streets

select * from streets_reprojected


--ex4
create table input_points (id int not null primary key, geom geometry, name VARCHAR(25))

insert into input_points values
(1, 'POINT(8.36093 49.03174)', 'point1'),
(2, 'POINT(8.39876 49.00644)', 'point2')

select * from input_points


--ex5
update input_points
set geom = ST_Transform(ST_SetSRID(geom, 4326), 3068)

select * from input_points


--ex6
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2019_KAR_STREET_NODE.shp t2019_kar_street_node | psql -U postgres -h localhost -p 5432 -d lab3
select * from t2019_kar_street_node tksn 

update t2019_kar_street_node 
set geom = ST_Transform(ST_SetSRID(geom, 4326), 3068)

with lines as (
	select ST_MAKELINE(geom) as line FROM input_points)
	
select tksn.gid
from t2019_kar_street_node tksn 
join lines l
on ST_DWITHIN(l.line, tksn.geom, 200) --returns true if the geometries are within a given distance


--ex7
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2019_KAR_LAND_USE_A.shp t2019_kar_land_use_a | psql -U postgres -h localhost -p 5432 -d lab3

select * from t2019_kar_land_use_a tklua 

select count(distinct tkpt.gid)
from t2019_kar_poi_table tkpt
join t2019_kar_land_use_a tklua   
on ST_DWITHIN(tkpt.geom, tklua.geom, 300) --returns true if the geometries are within a given distance
where tkpt.type = 'Sporting Goods Store'


--ex8
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2019_KAR_WATER_LINES.shp t2019_kar_water_lines | psql -U postgres -h localhost -p 5432 -d lab3
--shp2pgsql -D -I C:/Users/Olga/Desktop/SpatialDatabases/SpatialDatabases/lab3/T2019_KAR_RAILWAYS.shp t2019_kar_railways | psql -U postgres -h localhost -p 5432 -d lab3

select ST_Intersection(tkr.geom, tkwl.geom) as geom 
into T2019_KAR_BRIDGES
from t2019_kar_railways tkr, t2019_kar_water_lines tkwl

select * from T2019_KAR_BRIDGES
