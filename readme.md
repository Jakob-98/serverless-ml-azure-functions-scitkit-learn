# Serverless ML on Azure Functions with Scikit-Learn

This repo describes how to easily deploy an SciKit-learn model to azure functions, allowing the user to run the models 'serverlessly', on a cost-by-use basis. Alternatively, you can choose to deploy your SciKit model along the lines of [scikit-learn-model-deployment-on-azure-ml](https://learn.microsoft.com/en-us/azure/databricks/applications/mlflow/scikit-learn-model-deployment-on-azure-ml). 

## TL;DR - steps to recreate
1. Train an sklearn classifier - save it with joblib as `model.joblib` and place it into `/src/SklearnModelFunction/`. Update `/src/requirements.txt` to match your model's dependencies. 
2. Create a resource group on azure, note the subscription-id and resource group name. Generate & save secrets to github by following [these steps](#creating-a-service-principal-and-credentials-for-your-resource-group)
3. Add the resource group name to `env: AZURE_RESOURCE_GROUP_NAME = ""` in `.github/workflows/deploy-to-azure.yaml`.
4. **Github actions**: on-push, a github actions pipeline is triggered: `.github/workflows/deploy-to-azure.yaml`. This creates your azure functions app, as well as the python function in the app.

**Azure devops**: Marco TODO
5. Test your function endpoint


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
xtest contains rows of data the model has not seen before, so we use the predicted output labels, y_pred_test and y_test to check the performance of the model  
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


## creating a service principal and credentials for your resource group
Navigate to your cloud shell in the azure portal (or use the CLI) and generate your credentials: 

```bash
az ad sp create-for-rbac --name "" --role contributor \
                         --scopes /subscriptions/{your_subscription_id}/resourceGroups/{your_rg} \
                         --sdk-auth
```

copy the credentials and add them to your github secrets (under settings -> secrets -> actions) and name them `AZURE_CREDENTIALS`.

Additionally, for terraform to work correctly, manually add the following secrets as well (found in the credentials generated earlier): 
`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`. 

## generating predictions with the azure function
In our model example, we drop 2 columns : `carrier` and `ArrDelay` when training the model. Consequently, before sending the data to your function endpoint, we should drop these columns (i.e. perform your preprocessing before sending the data to your function). Alternatively, you can solve this in your functions `__init.py__` but that is not recommended. 



