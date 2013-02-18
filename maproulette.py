from flask import Flask, request, abort, send_from_directory, jsonify, render_template
import geojson
from pyspatialite import dbapi2 as db
from hamlish_jinja import HamlishExtension
from flaskext.coffee import coffee
from markdown import markdown
import settings

# creating/connecting the test_db`
conn = db.connect('noaddr.sqlite')
app = Flask(__name__)
app.config.from_object(__name__)
app.config.from_envvar('REMAPATRON_SETTINGS', silent = True)

# Add haml support
app.jinja_env.add_extension(HamlishExtension)
app.jinja_env.hamlish_mode = 'indented'
app.debug = True

coffee(app)

@app.route('/meta')
def meta():
    """Returns the metadata for the current challenge"""
    return jsonify({
            'name': settings.name,
            'description': settings.description,
            'difficulty': settings.difficulty,
            'blurb': settings.blurb,
            'help': markdown(settings.help),
            })

@app.route('/stats')
def stats():
    """Returns statistics about the challenge"""
    conn = db.connect('noaddr.sqlite')
    cur = conn.cursor()
    results = cur.execute("SELECT COUNT(id) from anomaly").fetchall()
    total = results[0][0]
    results = cur.execute("SELECT COUNT (id) from anomaly WHERE seen > 2").fetchall()
    done = results[0][0]
    return jsonify({'total': total, 'done': done})

@app.route('/task')
def get_anomaly():
    """Retrieves a candidate anomaly and returns as geoJSON"""
    conn = db.connect('noaddr.sqlite')
    cur = conn.cursor()
    recs = cur.execute("""
SELECT id, description, AsGeoJSON(pt) from anomaly WHERE seen < 3
ORDER BY RANDOM() LIMIT 1""").fetchall()
    anomaly_id, text, point = recs[0]
    fc = geojson.FeatureCollection([
            geojson.Feature(geometry = geojson.loads(point),
                            properties = {
                    # There must be one object in the FeatureCollection
                    # That has a key = True. Then that object must have
                    # it's OSM element type (type) and OSM ID (id)
                    'selected': True,
                    'type': 'node',
                    'id': anomaly_id,
                    'text': text})])
    
    return geojson.dumps({
            'id': anomaly_id,
            'text': text,
            'features': fc})

@app.route('/task/<task_id>', methods = ['POST'])
def store_attempt(task_id):
    """Stores information about the task"""
    conn = db.connect('noaddr.sqlite')
    cur = conn.cursor()
    res = cur.execute("SELECT id from anomaly where id IS %d" % int(task_id))
    recs = res.fetchall()
    if not len(recs) == 1:
        abort(404)
    #dct = geojson.loads(request.json)
    dct = request.form
    # We can now handle this object as we like, but for now, let's
    # just handle the action
    action = dct['action']
    if action == 'fixed':
        pass
    elif action == 'notfixed':
        pass
    elif action == 'someonebeatme':
        pass
    elif action == 'falsepositive':
        pass
    elif action == 'skip':
        pass
    elif action == 'noerrorafterall':
        pass
    # We need to return something, so let's return an empty
    # string. Maybe in the future we'll think of something useful to
    # return and return that instead
    return ""


#	fixflag: {
#		fixed: 100,
#		notfixed: 0,
#		someonebeatme: 100,
#		noerrorafterall: 100,
#		falsepositive: 1,
#		skip: -1   

# Fallback to serving a file
@app.route('/')
def index():
    return render_template('index.haml')

@app.route('/<path:path>')
def catch_all(path):
    return send_from_directory('static', path)

if __name__ == '__main__':
    app.run()