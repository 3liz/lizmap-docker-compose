""" Test just returning simple value
"""

from qgis.core import (QgsProcessingParameterNumber,
                       QgsProcessingParameterString,
                       QgsProcessingOutputNumber,
                       QgsProcessingOutputString,
                       QgsProcessingAlgorithm,
                       QgsMapLayer)


class TestContextVectorLayer(QgsProcessingAlgorithm):

    OUTPUT = 'OUTPUT'

    def __init__(self):
        super().__init__()

    def name(self):
        return 'testcontextvectorlayer'

    def displayName(self):
        return 'Test Context Vector Layer'

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

        vectors = []
        project = context.project()
        if project :
            for l in project.mapLayers().values():
                if l.type() == QgsMapLayer.VectorLayer:
                    vectors.append( l.name() )

        return {self.OUTPUT: ", ".join( vectors )}

