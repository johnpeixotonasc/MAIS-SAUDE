# arquivo main principal
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "+ SAÚDE API funcionando! 🚀"}

