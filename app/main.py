from fastapi import FastAPI
from config import APP_NAME, APP_VERSION, ENVIRONMENT
import logging

logging.basicConfig(level=logging.INFO)

app = FastAPI(title=APP_NAME)

@app.get("/")
def root():
    return {
        "app": APP_NAME,
        "version": APP_VERSION,
        "environment": ENVIRONMENT
    }

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/version")
def version():
    return {"version": APP_VERSION}
