""" Test datastore rest api
"""
import os
import requests


def test_get_capabilities( host, data ):
    """ Test Get capabilities"""
    rv = requests.get(host + "/?SERVICE=WPS&Request=GetCapabilities")
    
    assert rv.status_code == 200 

def test_describeprocess( host, data ):
    """ Test describe process"""
    rv = requests.get(host + "/?SERVICE=WPS&Request=DescribeProcess&Identifier=lzmtest:testcopylayer&Version=1.0.0"

    assert rv.status_code == 200

def test_executeprocess( host, data ):
    """  Test execute process """
    rv = requests.get(baseurl+("?SERVICE=WPS&Request=Execute&Identifier=lzmtest:testcopylayer&Version=1.0.0"
                               "&MAP=france_parts&DATAINPUTS=INPUT=france_parts;OUTPUT=france_parts_2")
    assert rv.status_code == 200
  

