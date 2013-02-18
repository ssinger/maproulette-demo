# importing pyspatialite
from pyspatialite import dbapi2 as db

# creating/connecting the test_db
conn = db.connect('noaddr.sqlite')

# creating a Cursor
cur = conn.cursor()

# testing library versions
rs = cur.execute('SELECT sqlite_version(), spatialite_version()')
for row in rs:
    msg = "> SQLite v%s Spatialite v%s" % (row[0], row[1])
    print msg

# initializing Spatial MetaData
# using v.2.4.0 this will automatically create
# GEOMETRY_COLUMNS and SPATIAL_REF_SYS
sql = 'SELECT InitSpatialMetadata()'
cur.execute(sql)

cur.execute("""
CREATE TABLE anomaly (
   id BIGINT NOT NULL PRIMARY KEY,
   seen TINY DEFAULT 0,
   description TEXT);""")

cur.execute("""
SELECT AddGeometryColumn('anomaly', 'pt',
       4326, 'POINT', 'XY');
""")
