import coremltools
import keras
from keras.utils.np_utils import to_categorical

model = keras.models.load_model('./model_checkpoint.hdf5')
coreml_model = coremltools.converters.keras.convert(model)
coreml_model.save('superMnist.mlmodel')
