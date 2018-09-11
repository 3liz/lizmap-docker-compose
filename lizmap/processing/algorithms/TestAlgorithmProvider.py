""" Test processing Provider
"""

from qgis.core import (QgsApplication,
                       QgsProcessingProvider)

from .TestSimpleValue import TestSimpleValue
from .TestCopyLayer import TestCopyLayer
from .TestContextVectorLayer import TestContextVectorLayer
from .TestContextRasterLayer import TestContextRasterLayer
from .TestQgisBuffer import TestQgisBuffer


class TestAlgorithmProvider(QgsProcessingProvider):

    def __init__(self):
        super().__init__()

    def getAlgs(self):
       algs = [
            TestSimpleValue(),
            TestCopyLayer(),
            TestContextVectorLayer(),
            TestContextRasterLayer(),
            TestQgisBuffer()
       ]
       return algs

    def id(self):
        return 'lzmtest'

    def name(self):
        return "QyWPS Test"

    def loadAlgorithms(self):
        self.algs = self.getAlgs()
        for a in self.algs:
            self.addAlgorithm(a)

