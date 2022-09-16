import logging
from sklearn.ensemble import RandomForestClassifier as RF
import joblib
import pandas as pd
import pathlib

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    try: 
        req_body = req.get_body()
    except ValueError: 
        return func.HttpResponse("Bad request: no body",status_code=400)
    
    parsed_body = eval(req_body)
    try: 
        df = pd.DataFrame.from_dict(parsed_body)
        df.drop('ArrDelay', axis=1, inplace=True)
        df.drop('Carrier', axis=1, inplace=True)
        

        model = joblib.load(pathlib.Path(__file__).parent / 'model.joblib')
        result = model.predict(df)
        return func.HttpResponse(str(result))

    except ValueError:
        return func.HttpResponse("Bad request: invalid body structure",status_code=400)
