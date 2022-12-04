 create database project;
create extension postgis;


alter schema schema_name rename to smistek;
create extension postgis_raster;

select * from vectors.railroad r;


CREATE TABLE smistek.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table smistek.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON smistek.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('smistek'::name,
'intersects'::name,'rast'::name);

select * from smistek.intersects i;


CREATE TABLE smistek.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

select * from smistek.clip;


CREATE TABLE smistek.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

select * from smistek.union;


CREATE TABLE smistek.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

select * from smistek.porto_parishes;


DROP TABLE smistek.porto_parishes; --> drop table porto_parishes first
CREATE TABLE smistek.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


DROP TABLE smistek.porto_parishes; --> drop table porto_parishes first
CREATE TABLE smistek.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

select * from smistek.porto_parishes;


create table smistek.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


select * from smistek.intersection;



CREATE TABLE smistek.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


select * from smistek.dumppolygons;



--rasters analysis

CREATE TABLE smistek.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

select * from smistek.landsat_nir;



CREATE TABLE smistek.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

select * from smistek.paranhos_dem;




CREATE TABLE smistek.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM smistek.paranhos_dem AS a;

select * from smistek.paranhos_slope;



CREATE TABLE smistek.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM smistek.paranhos_slope AS a;

select * from smistek.paranhos_slope_reclass;



SELECT st_summarystats(a.rast) AS stats
FROM smistek.paranhos_dem AS a;



SELECT st_summarystats(ST_Union(a.rast))
FROM smistek.paranhos_dem AS a;


WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;



WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM smistek.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;



--TPI
create table smistek.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON smistek.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('smistek'::name,
'tpi30'::name,'rast'::name);



create table smistek.tpi30porto as 
select ST_TPI(a.rast,1) as rast
from rasters.dem AS a, vectors.porto_parishes AS b
WHERE  ST_Intersects(a.rast, b.geom) 
AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_rast_gist_porto ON smistek.tpi30porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('smistek'::name, 
'tpi30porto'::name,'rast'::name);



--algrbra map:

CREATE TABLE smistek.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON smistek.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('smistek'::name,
'porto_ndvi'::name,'rast'::name);

select * from smistek.porto_ndvi;



create or replace function smistek.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;


CREATE TABLE smistek.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'smistek.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;


CREATE INDEX idx_porto_ndvi2_rast_gist ON smistek.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('smistek'::name,
'porto_ndvi2'::name,'rast'::name);

select * from smistek.porto_ndvi2;



--data export
SELECT ST_AsTiff(ST_Union(rast))
FROM smistek.porto_ndvi;


SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM smistek.porto_ndvi;


SELECT ST_GDALDrivers();


CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
 ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 
'PREDICTOR=2', 'PZLEVEL=9'])
 ) AS loid
FROM smistek.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid,
'D:\myraster.tiff') 
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
 FROM tmp_out;

