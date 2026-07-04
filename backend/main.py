from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from typing import Optional
from pydantic import BaseModel
from models import Base, User, Society, Skill, AdToken
import os
import math

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is not set")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

Base.metadata.create_all(bind=engine)

# Seed test user
def seed_test_user():
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.username == "admin").first()
        if not existing:
            user = User(
                username="admin",
                password="admin",
                email="admin@test.com",
                latitude=12.9716,
                longitude=77.5946,
            )
            db.add(user)
            db.commit()
    finally:
        db.close()

seed_test_user()

app = FastAPI()

# --- Schemas ---
class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    username: str
    password: str
    email: str
    lat: float
    lng: float

class SkillCreate(BaseModel):
    title: str
    description: str
    category: str
    price_type: str
    hourly_rate: Optional[float] = None
    phone_number: str

class SocietyCreate(BaseModel):
    name: str
    lat: float
    lng: float

# --- Helpers ---
def haversine(lat1, lng1, lat2, lng2):
    R = 6371000
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# --- Auth Endpoints ---

@app.post("/auth/login")
async def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data.username, User.password == data.password).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")
    return {
        "status": "success",
        "user_id": user.id,
        "username": user.username,
        "email": user.email,
        "society_id": user.society_id,
    }

@app.post("/auth/register")
async def register(data: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(
        (User.username == data.username) | (User.email == data.email)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username or email already exists")
    user = User(
        username=data.username,
        password=data.password,
        email=data.email,
        latitude=data.lat,
        longitude=data.lng,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"status": "success", "user_id": user.id}

# --- User Endpoints ---

@app.post("/users/sync")
async def sync_user(data: LoginRequest, db: Session = Depends(get_db)):
    # Kept for backward compatibility
    return await login(data, db)

# --- Skill Endpoints ---

@app.post("/skills/create")
async def create_skill(user_id: int, data: SkillCreate, db: Session = Depends(get_db)):
    skill = Skill(**data.model_dump(), user_id=user_id)
    db.add(skill)
    db.commit()
    db.refresh(skill)
    return {"status": "success", "skill_id": skill.id}

# --- Society Endpoints ---

@app.post("/societies/create")
async def create_society(user_id: int, data: SocietyCreate, db: Session = Depends(get_db)):
    society = Society(name=data.name, latitude=data.lat, longitude=data.lng)
    db.add(society)
    db.commit()
    db.refresh(society)

    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.society_id = society.id
        db.commit()

    return {"status": "success", "society_id": society.id, "name": society.name}

@app.post("/societies/leave")
async def leave_society(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.society_id = None
    db.commit()
    return {"status": "success", "message": "Left society"}

@app.post("/societies/join")
async def join_society(user_id: int, society_id: int, db: Session = Depends(get_db)):
    society = db.query(Society).filter(Society.id == society_id).first()
    if not society:
        raise HTTPException(status_code=404, detail="Society not found")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.society_id = society.id
    db.commit()
    return {"status": "success", "society_id": society.id, "name": society.name}

# --- Search Endpoints ---

@app.get("/skills/nearby")
async def get_nearby_skills(lat: float, lng: float, radius: float = 5.0, db: Session = Depends(get_db)):
    users = db.query(User).all()
    nearby_user_ids = []
    for u in users:
        if u.latitude is not None and u.longitude is not None:
            dist = haversine(lat, lng, u.latitude, u.longitude)
            if dist <= radius * 1000:
                nearby_user_ids.append(u.id)

    if not nearby_user_ids:
        return []

    skills = db.query(Skill).filter(Skill.user_id.in_(nearby_user_ids)).all()
    result = []
    for s in skills:
        u = db.query(User).filter(User.id == s.user_id).first()
        result.append({
            "id": s.id,
            "user_id": s.user_id,
            "category": s.category,
            "title": s.title,
            "description": s.description,
            "price_type": s.price_type,
            "hourly_rate": s.hourly_rate,
            "phone_number": s.phone_number,
            "email": u.email if u else None,
        })
    return result

@app.get("/skills/society/{society_id}")
async def get_society_skills(society_id: int, db: Session = Depends(get_db)):
    skills = db.query(Skill).join(User).filter(User.society_id == society_id).all()
    result = []
    for s in skills:
        u = db.query(User).filter(User.id == s.user_id).first()
        result.append({
            "id": s.id,
            "user_id": s.user_id,
            "category": s.category,
            "title": s.title,
            "description": s.description,
            "price_type": s.price_type,
            "hourly_rate": s.hourly_rate,
            "phone_number": s.phone_number,
            "email": u.email if u else None,
        })
    return result

# --- Reward Endpoints ---

@app.post("/rewards/claim")
async def claim_reward(user_id: int, token_type: str, db: Session = Depends(get_db)):
    token = db.query(AdToken).filter(
        AdToken.user_id == user_id, AdToken.token_type == token_type
    ).first()
    if not token:
        token = AdToken(user_id=user_id, token_type=token_type, count=1)
        db.add(token)
    else:
        token.count += 1
    db.commit()
    return {"status": "success", "tokens": token.count}

@app.post("/rewards/consume")
async def consume_reward(user_id: int, token_type: str, db: Session = Depends(get_db)):
    token = db.query(AdToken).filter(
        AdToken.user_id == user_id, AdToken.token_type == token_type
    ).first()
    if not token or token.count <= 0:
        raise HTTPException(status_code=403, detail="Insufficient tokens. Watch an ad!")
    token.count -= 1
    db.commit()
    return {"status": "success", "remaining": token.count}
