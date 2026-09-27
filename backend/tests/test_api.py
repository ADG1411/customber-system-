import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert data["api_v1"] == "/api/v1"

def test_health_endpoint():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "supabase" in data["data"]

def test_list_customers():
    response = client.get("/api/v1/customers")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) >= 5
    assert any(c["name"] == "Rahul Patel" for c in data["data"])

def test_list_orders():
    response = client.get("/api/v1/orders")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) >= 4
    assert any(o["order_number"] == "ORD-1025" for o in data["data"])

def test_production_capacity():
    response = client.get("/api/v1/capacity")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    current = data["data"]["current"]
    assert current["total_capacity_units"] == 100
    assert current["available_capacity_units"] == 50

def test_tracking_portal_lookup():
    response = client.get("/api/v1/track/SARJAN-2026-8F42")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["order_number"] == "ORD-1025"
    assert data["data"]["customer_name"] == "Rahul Patel"
    assert len(data["data"]["stages"]) == 9
