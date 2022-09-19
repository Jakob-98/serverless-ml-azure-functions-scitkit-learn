import logging
from sklearn.ensemble import RandomForestClassifier as RF
import joblib
import pandas as pd
import pathlib

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    try: 
        req_body = req.get_body()
        parsed_body = eval(req_body)
        df = pd.DataFrame.from_dict(parsed_body)   

    except ValueError:
        return func.HttpResponse("Bad request: invalid body structure",status_code=400)

    except Exception as err:
        return func.HttpResponse("Exception while parsing body: " + str(err), status_code=400)

    try:
        model = joblib.load(pathlib.Path(__file__).parent / 'model.joblib')
        result = model.predict(df)

        return func.HttpResponse(str(result))

    except Exception as err:
        return func.HttpResponse("Error while loading or predicting with model, exception: " + str(err), status_code=500)