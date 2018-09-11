""" Test just returning simple value
"""

from qgis.core import (QgsProcessingParameterNumber,
                       QgsProcessingParameterString,
                       QgsProcessingOutputNumber,
                       QgsProcessingOutputString,
                       QgsProcessingAlgorithm,
                       QgsMapLayer)


class TestContextRasterLayer(QgsProcessingAlgorithm):

    OUTPUT = 'OUTPUT'

    def __init__(self):
        super().__init__()

    def name(self):
        return 'testcontextrasterlayer'

    def displayName(self):
        return 'Test Context Raster Layer'

    def createInstance(self, config={}):
        """ Virtual override

            see https://qgis.org/api/classQgsProcessingAlgorithm.html
        """
        return self.__class__()

    def initAlgorithm( self, config=None ):
        """ Virtual override

            see https://qgis.org/api/classQgsProcessingAlgorithm.html
        """

        self.addOutput(QgsProcessingOutputString(self.OUTPUT,"Output"))

    def processAlgorithm(self, parameters, context, feedback):

        rasters = []
        project = context.project()
        if project :
            for l in project.mapLayers().values():
                if l.type() == QgsMapLayer.RasterLayer:
                    rasters.append( l.name() )

        return {self.OUTPUT: ", ".join( rasters )}

