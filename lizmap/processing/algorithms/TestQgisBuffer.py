""" Test just returning simple value
"""

from qgis.core import (QgsProcessingParameterVectorLayer,
                       QgsProcessingParameterFeatureSource,
                       QgsProcessingParameterNumber,
                       QgsProcessingParameterEnum,
                       QgsProcessingParameterBoolean,
                       QgsProcessingParameterVectorDestination,
                       QgsProcessingAlgorithm)


class TestQgisBuffer(QgsProcessingAlgorithm):

    INPUT = 'INPUT'
    DISTANCE = 'DISTANCE'
    SEGMENTS = 'SEGMENTS'
    END_CAP_STYLE = 'END_CAP_STYLE'
    END_CAP_STYLE_options = ['Round','Flat','Square']
    JOIN_STYLE = 'JOIN_STYLE'
    JOIN_STYLE_options = ['Round','Miter','Bevel']
    MITER_LIMIT = 'MITER_LIMIT'
    DISSOLVE = 'DISSOLVE'
    OUTPUT = 'OUTPUT'

    def __init__(self):
        super().__init__()

    def name(self):
        return 'qgisbuffer'

    def displayName(self):
        return 'QGIS Buffer'

    def createInstance(self, config={}):
        """ Virtual override

            see https://qgis.org/api/classQgsProcessingAlgorithm.html
        """
        return self.__class__()

    def initAlgorithm( self, config=None ):
        """ Virtual override

            see https://qgis.org/api/classQgsProcessingAlgorithm.html
        """
        self.addParameter(QgsProcessingParameterFeatureSource(self.INPUT,'Input layer'))
        self.addParameter(QgsProcessingParameterNumber(self.DISTANCE, 'Distance',
                          type=QgsProcessingParameterNumber.Double, defaultValue=0.1))
        self.addParameter(QgsProcessingParameterNumber(self.SEGMENTS, 'Segments',
                          type=QgsProcessingParameterNumber.Integer,
                          defaultValue=5, minValue=1))
        self.addParameter(QgsProcessingParameterEnum(self.END_CAP_STYLE, 'End cap style',
                          options=self.END_CAP_STYLE_options))
        self.addParameter(QgsProcessingParameterEnum(self.JOIN_STYLE, 'Join style',
                          options=self.JOIN_STYLE_options))
        self.addParameter(QgsProcessingParameterNumber(self.MITER_LIMIT, 'Miter limit',
                          type=QgsProcessingParameterNumber.Double,
                          defaultValue=2, minValue=1))
        self.addParameter(QgsProcessingParameterBoolean(self.DISSOLVE, 'Dissolve result',
                          defaultValue=False))
        self.addParameter(QgsProcessingParameterVectorDestination(self.OUTPUT,"Buffered"))

    def processAlgorithm(self, parameters, context, feedback):
        import processing
        output = self.parameterAsOutputLayer(parameters, self.OUTPUT, context)
        params = dict(parameters)
        params[self.OUTPUT] = output
        result = processing.run("qgis:buffer", params, context=context, feedback=feedback)
        return {self.OUTPUT: result['OUTPUT']}

