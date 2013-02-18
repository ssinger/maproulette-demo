#!/usr/bin/env python
"""This is the TIGER expansion library and command line script"""

import sys
from xml.sax import make_parser
import argparse
from pyxbot import OSMHandler
from os import remove
import codecs
from pyspatialite import dbapi2 as db

# creating/connecting the test_db
conn = db.connect('noaddr.sqlite')

def add_or_incr(dct, item):
    """Takes a dictionary and item and increments the number on that
    item in the dictionary (like a set only with a counter)"""
    if dct.has_key(item):
        dct[item] = dct[item] + 1
    else:
        dct[item] = 1

class NoAddrHandler(OSMHandler):
    """This is the unclosed building expansion class"""

    def startDocument(self):
         self.conn = db.connect('noaddr.sqlite')
         self.cur = self.conn.cursor()

    def selectElement(self):
        if not self.tags.has_key('addr:housenumber'):
            return True

    def transformElement(self):
        self.fixed = True
        name = self.tags['name']
        description = "%s does not have an address"
        point = "GeomFromText('POINT(%s, %s)', 4326)" % (self.attrs['lat'],
                                                         self.attrs['lon'])
        s = "INSERT INTO anomaly (id, description, pt) VALUES (%s, '%s', %s)" \
            % (self.attrs['id'], description, point)
        self.cur.execute(s)
        print "hi!"

    def endDocument(self):
        self.conn.commit()
        self.conn.close()

def main():
    """Function run by command line"""
    argparser = argparse.ArgumentParser(description="Tiger expansion bot")
    argparser.add_argument('--infile', dest = 'infname',
                           help = 'The input filename')
    argparser.add_argument('--outdir', dest = 'outdirname',
                           default = 'processed', help = 'The output directory')
    argparser.add_argument('--checkways', dest = 'checkways_fname',
                           default = 'ways.csv',
                           help = "Unfixable way csv file")
    args = argparser.parse_args()
    if not args.infname:
        argparser.print_help()
        return -1
    if args.infname == '-':
        input_file = sys.stdin
        args.infname = 'expansion'
    else:
        input_file = open(args.infname, 'r')

    if not args.outdirname:
        args.outdirname = args.infname
    dirname = args.outdirname

    parser = make_parser()
    handler = NoAddrHandler(dirname)
    parser.setContentHandler(handler)
    parser.parse(input_file)

if __name__ == '__main__':
    sys.exit(main())
