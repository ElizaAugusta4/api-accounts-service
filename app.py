from fastapi import FastAPI, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from . import models, schemas
from .database import get_db, engine

app = FastAPI(title="Accounts Service", version="1.0.0")

@app.get("/")
def read_root():
    return {"message": "Accounts Service running!"}

@app.post("/accounts", response_model=schemas.AccountOut, status_code=201)
def create_account(account: schemas.AccountCreate, db: Session = Depends(get_db)):
    existing_account = db.query(models.Account).filter(models.Account.name == account.name).first()
    if existing_account:
        raise HTTPException(status_code=400, detail="Já existe uma conta com este nome")
    db_account = models.Account(**account.dict())
    db.add(db_account)
    db.commit()
    db.refresh(db_account)
    return db_account

@app.get("/accounts", response_model=List[schemas.AccountOut])
def list_accounts(db: Session = Depends(get_db)):
    return db.query(models.Account).all()

@app.get("/accounts/{account_id}", response_model=schemas.AccountOut)
def get_account(account_id: int, db: Session = Depends(get_db)):
    account = db.query(models.Account).get(account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Conta não encontrada")
    return account
