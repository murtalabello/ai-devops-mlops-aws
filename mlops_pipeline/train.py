import os
import joblib
import numpy as np
from sklearn.datasets import load_diabetes
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split

os.makedirs("artifacts", exist_ok=True)

X, y = load_diabetes(return_X_y=True)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = LinearRegression()
model.fit(X_train, y_train)

y_pred = model.predict(X_test)
mse = mean_squared_error(y_test, y_pred)

print(f"MSE: {mse}")

joblib.dump(model, "artifacts/model.pkl")

with open("artifacts/metrics.txt", "w") as f:
    f.write(f"MSE={mse}\n")
