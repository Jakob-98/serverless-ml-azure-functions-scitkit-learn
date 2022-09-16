import logging
from sklearn.ensemble import RandomForestClassifier as RF
import joblib
import pandas as pd
import pathlib

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    return func.HttpResponse("huzza!", status_code=200)
    
