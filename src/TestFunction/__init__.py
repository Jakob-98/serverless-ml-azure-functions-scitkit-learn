import logging
import pandas as pd
import pathlib

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    return func.HttpResponse("huzza!", status_code=200)
    
