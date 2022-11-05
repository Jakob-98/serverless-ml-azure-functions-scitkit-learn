# Serverless ML on Azure Functions with Scikit-Learn

This repo describes how to easily deploy a Scikit-learn model to azure functions, allowing the user to run the models 'serverlessly', on a cost-by-use basis. Alternatively, you can choose to deploy your Scikit model along the lines of [scikit-learn-model-deployment-on-azure-ml](https://learn.microsoft.com/en-us/azure/databricks/applications/mlflow/scikit-learn-model-deployment-on-azure-ml). 

## TL;DR - steps to reproduce using Github Actions
0. Fork this repository.
1. Enable Actions in the actions tab of your respository.
2. Train an sklearn classifier - save it with joblib as `model.joblib` and place it into `/src/SklearnModelFunction/`. Update `/src/requirements.txt` to match your model's dependencies. More info [here](#creating-an-sklearn-model)
3. Create a resource group on azure, note the **subscription-id** and **resource group name**. 
4. Create a storage account in that resource group. This will be used for the terraform state files. Keep track of the **storage account name**. Create a private container in the storage account, name it `state`. 
5. Generate and save secrets to github by following [these steps](#creating-a-service-principal-and-credentials-for-your-resource-group). 
6. Add the names you noted down to `.github/workflows/deploy-to-azure.yaml` in:
```yaml
env: 
  AZURE_RESOURCE_GROUP_NAME: {name of your resource group}
  TERRAFORM_BACKEND_STORAGEACCOUNT: {name of your storage account}
  ENVIRONMENT_NAME: {e.g. sklearnmodel}
  ENVIRONMENT_TYPE: {e.g. dev, prod}
  TERRAFORM_BACKEND_RESOURCEGROUP: {name of your resource group}
```
7. Commit the changes to your fork. **on-push**, a github actions pipeline is triggered: `.github/workflows/deploy-to-azure.yaml`. This creates your azure functions app, as well as the python function in the app. Alternatively, you can manually trigger from the actions tab. 
8. Test your function endpoint, e.g. using postman. See [here](#generating-predictions-with-the-azure-function). 

## TL;DR - steps to reproduce using Azure Devops

Coming soon...

## Creating an sklearn model
The notebook `./randomforest_example/model_creation.ipynb`shows how to create a simple randomforest model which predicts whether or not flights will be delayed by 15 minutes or more. The most important stepts are as follows: 

### Splitting the dataset into training and test data
We split the dataset into training and test to be able to verify the performance on unseen data after model training:
```py 
x, y = data.iloc[:,:-1], data.iloc[:,-1]
xtrain, xtest, ytrain, ytest = train_test_split(x, y)
```

### Creating and fitting the classifier model: 
A randomforest classifier object is created and fit with the training data and labels: 
```py
clf = RF()
clf.fit(xtrain, ytrain)
```

### Checking the performance of the model:
xtest contains rows of data the model has not seen before, so we use the predicted output labels, y_pred_test and y_test to check the performance of the model.  
```py
y_pred_test = clf.predict(xtest)
print(accuracy_score(ytest, y_pred_test))
 >> 0.9204
```

### Saving the model
Using the joblib library we dump the model into `model.joblib`

**!!Note** -  this model is now saved in the `./randomforest_example/model` folder and should be (manually) placed in the `/SklearnModelFunction/` folder to deploy it in later steps. 
```py
joblib.dump(clf, "./model/model.joblib")
```

## Creating an azure function to support our model
The azure function can be found in `/src/SklearnModelFunction/`. Most importantly, this folder contains the model: `/src/SklearnModelFunction/model.joblib`, and the logic for loading the model and running a prediction: `/src/SklearnModelFunction/__init__.py`. The file `/src/requirements.txt` should contain all the requirements you import in your functions. You can find the general documentation on azure functions + python [here](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=asgi%2Capplication-level).  


## Creating a service principal and credentials for your resource group
Navigate to your cloud shell in the azure portal (or use the CLI) and generate your credentials (for powershell remove the "\"): 

```bash
az ad sp create-for-rbac --name "sp_sklearnmodel" --role contributor \
                         --scopes /subscriptions/{your_subscription_id}/resourceGroups/{your_rg} \
                         --sdk-auth
```

copy the credentials and use them to populate your github secrets, under settings -> secrets -> actions. Manually add the following secrets from the credentials: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SUBSCRIPTION_ID`, and `AZURE_TENANT_ID`. 

## Generating predictions with the azure function
Navigate to your function app -> functions, and grab the URL of the endpoint. As we set it up, with a simple HTTP POST with a list of dicts in the the body, we can test our function:

```json
[
    {'Year': 2013, 'Month': 4, 'DayofMonth': 19, 'DayOfWeek': 5,'OriginAirportID': 11433, 'DestAirportID': 13303, 'CRSDepTime': 837, 'DepDelay': '-3.0', 'DepDel15': 0.0, 'CRSArrTime': 1138, 'ArrDelay': 0.0, 'Cancelled': 0.0 }
] 
```

It returns the prediction (a binary variable) in the form of a list of predictions, one for each entries in the body of your POST request. 
 
**Note:** in our model example, we drop 2 columns : `carrier` and `ArrDelay` when training the model. Consequently, before sending the data to our function endpoint, we should drop these columns. We recommand to perform such preprocessing before sending the data to your function. Alternatively, you can solve this in your functions `__init.py__` but that is not recommended. 

## License
This repository is under the [MIT License](https://github.com/Jakob-98/serverless-ml-azure-functions-scitkit-learn/blob/master/licence.md).
