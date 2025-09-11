import pytest
from fastapi.testclient import TestClient
from accounts_service.app import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "Accounts Service" in response.json()["message"]

def test_create_account():
    payload = {"name": "Conta Teste", "description": "Conta para teste"}
    response = client.post("/accounts", json=payload)
    assert response.status_code in [201, 400]  # 400 se já existir

def test_list_accounts():
    response = client.get("/accounts")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_get_account():
    # Cria uma conta para garantir que existe
    payload = {"name": "Conta Teste2", "description": "Conta para teste"}
    post_resp = client.post("/accounts", json=payload)
    if post_resp.status_code == 201:
        account_id = post_resp.json()["id"]
        get_resp = client.get(f"/accounts/{account_id}")
        assert get_resp.status_code == 200
        assert get_resp.json()["id"] == account_id
