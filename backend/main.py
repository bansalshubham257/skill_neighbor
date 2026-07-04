from fastapi import FastAPI, Depends, HTTPException, Request
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from typing import List, Optional
from pydantic import BaseModel
from models import Base, User, Society, Skill, AdToken
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost/skillneighbor")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

Base.metadata.create_all(bind=engine)

app = FastAPI()

# --- Schemas ---
class UserCreate(BaseModel):
    google_id: str
    email: str
    lat: float
    lng: float
    society_id: Optional[int] = None

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

# --- Endpoints ---

@app.post("/users/sync")
async def sync_user(data: UserCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.google_id == data.google_id).first()
    if not user:
        user = User(
            google_id=data.google_id,
            email=data.email,
            location=f"POINT({data.lng} {data.lat})",
            society_id=data.society_id,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.location = f"POINT({data.lng} {data.lat})"
        user.society_id = data.society_id
        db.commit()
    return {"status": "success", "user_id": user.id}

@app.post("/skills/create")
async def create_skill(user_id: int, data: SkillCreate, db: Session = Depends(get_db)):
    skill = Skill(**data.model_dump(), user_id=user_id)
    db.add(skill)
    db.commit()
    db.refresh(skill)
    return {"status": "success", "skill_id": skill.id}

@app.post("/societies/create")
async def create_society(user_id: int, data: SocietyCreate, db: Session = Depends(get_db)):
    society = Society(name=data.name, location=f"POINT({data.lng} {data.lat})")
    db.add(society)
    db.commit()
    db.refresh(society)

    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.society_id = society.id
        db.commit()

    return {"status": "success", "society_id": society.id, "name": society.name}

@app.get("/skills/nearby")
async def get_nearby_skills(lat: float, lng: float, radius: float = 5.0, db: Session = Depends(get_db)):
    query = text(
        "SELECT s.*, u.email FROM skills s "
        "JOIN users u ON s.user_id = u.id "
        "WHERE ST_DWithin(u.location, ST_GeogFromText(:point), :dist)"
    )
    result = db.execute(query, {"point": f"POINT({lng} {lat})", "dist": radius * 1000})
    rows = result.fetchall()
    return [dict(row._mapping) for row in rows]

@app.get("/skills/society/{society_id}")
async def get_society_skills(society_id: int, db: Session = Depends(get_db)):
    skills = db.query(Skill).join(User).filter(User.society_id == society_id).all()
    return skills

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
