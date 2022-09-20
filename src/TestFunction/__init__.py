import logging
import pathlib
import pandas

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    return func.HttpResponse("1 huzza!", status_code=200)
    
