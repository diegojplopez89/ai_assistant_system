# tgi-switcher/main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "TGI Switcher placeholder active."}
