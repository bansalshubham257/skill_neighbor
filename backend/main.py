from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from typing import Optional
from pydantic import BaseModel
from models import Base, User, Society, Skill, AdToken, SkillRequest, SkillRating, SCHEMA
import bcrypt
import os
import math
import datetime

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is not set")
# Connect with search_path set to the schema
engine = create_engine(
    DATABASE_URL,
    connect_args={"options": f"-csearch_path={SCHEMA}"}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Password hashing
def hash_password(password: str) -> str:
    pwd_bytes = password[:72].encode('utf-8')
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    pwd_bytes = plain_password[:72].encode('utf-8')
    return bcrypt.checkpw(pwd_bytes, hashed_password.encode('utf-8'))

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

with engine.connect() as conn:
    conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {SCHEMA}"))
    conn.commit()
Base.metadata.create_all(bind=engine)

# Run startup tasks (cleanup)
def startup_tasks():
    db = SessionLocal()
    try:
        # Cleanup old requests (30 days)
        cutoff = datetime.datetime.utcnow() - datetime.timedelta(days=30)
        db.query(SkillRequest).filter(SkillRequest.created_at < cutoff).delete()
        db.commit()
        print("Cleanup complete")
    except Exception as e:
        print(f"Cleanup failed: {e}")
    finally:
        db.close()

startup_tasks()

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
    share_phone: int = 1

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
    user = db.query(User).filter(User.username == data.username).first()
    if not user or not verify_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid username or password")
    society_name = None
    if user.society_id:
        society = db.query(Society).filter(Society.id == user.society_id).first()
        society_name = society.name if society else None
    return {
        "status": "success",
        "user_id": user.id,
        "username": user.username,
        "email": user.email,
        "society_id": user.society_id,
        "society_name": society_name,
    }

@app.post("/auth/register")
async def register(data: RegisterRequest, db: Session = Depends(get_db)):
    # Only check for username existence
    existing = db.query(User).filter(User.username == data.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Optionally check for email existence if provided
    if data.email:
        existing_email = db.query(User).filter(User.email == data.email).first()
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already exists")

    user = User(
        username=data.username,
        password=hash_password(data.password),
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

@app.get("/skills/my")
async def get_my_skills(user_id: int, db: Session = Depends(get_db)):
    skills = db.query(Skill).filter(Skill.user_id == user_id).all()
    result = []
    for s in skills:
        result.append({
            "id": s.id,
            "user_id": s.user_id,
            "category": s.category,
            "title": s.title,
            "description": s.description,
            "price_type": s.price_type,
            "hourly_rate": s.hourly_rate,
            "phone_number": s.phone_number,
        })
    return result

@app.put("/skills/update")
async def update_skill(skill_id: int, user_id: int, data: SkillCreate, db: Session = Depends(get_db)):
    skill = db.query(Skill).filter(Skill.id == skill_id, Skill.user_id == user_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found or not yours")
    for key, val in data.model_dump().items():
        setattr(skill, key, val)
    db.commit()
    return {"status": "success", "skill_id": skill.id}

@app.delete("/skills/delete")
async def delete_skill(skill_id: int, user_id: int, db: Session = Depends(get_db)):
    skill = db.query(Skill).filter(Skill.id == skill_id, Skill.user_id == user_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found or not yours")
    db.delete(skill)
    db.commit()
    return {"status": "success", "message": "Skill deleted"}

@app.get("/skills/favorites")
async def get_favorite_skills(user_id: int, db: Session = Depends(get_db)):
    print(f"DEBUG: Fetching favorites for user_id={user_id}")
    likes = db.query(SkillLike).filter(SkillLike.user_id == user_id).all()
    print(f"DEBUG: Found likes: {likes}")
    skill_ids = [l.skill_id for l in likes]
    if not skill_ids:
        print("DEBUG: No liked skill IDs found.")
        return []
    skills = db.query(Skill).filter(Skill.id.in_(skill_ids)).all()
    print(f"DEBUG: Found skills: {skills}")
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
            "society_id": u.society_id if u else None,
            "society_name": db.query(Society.name).filter(Society.id == u.society_id).scalar() if u and u.society_id else None,
        })
    print(f"DEBUG: Returning result: {result}")
    return result

# --- Society Endpoints ---

def check_society_change_limit(user):
    if user.last_society_change and (datetime.datetime.utcnow() - user.last_society_change).days < 30:
        remaining = 30 - (datetime.datetime.utcnow() - user.last_society_change).days
        raise HTTPException(status_code=400,
            detail=f"You can only change society once per month. {remaining} days remaining.")

def set_society(user, society_id, db):
    user.society_id = society_id
    user.last_society_change = datetime.datetime.utcnow()
    db.commit()

@app.get("/societies/list")
async def list_societies(db: Session = Depends(get_db)):
    societies = db.query(Society).all()
    return [{"id": s.id, "name": s.name, "latitude": s.latitude, "longitude": s.longitude} for s in societies]

@app.post("/societies/create")
async def create_society(user_id: int, data: SocietyCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.society_id is not None:
        raise HTTPException(status_code=400, detail="You are already in a society. Leave it first to create a new one.")
    check_society_change_limit(user)

    society = Society(name=data.name, latitude=data.lat, longitude=data.lng)
    db.add(society)
    db.commit()
    db.refresh(society)

    set_society(user, society.id, db)
    return {"status": "success", "society_id": society.id, "name": society.name}

@app.post("/societies/leave")
async def leave_society(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.society_id = None
    user.last_society_change = datetime.datetime.utcnow()
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
    if user.society_id is not None:
        raise HTTPException(status_code=400, detail="You are already in a society. Leave it first.")
    check_society_change_limit(user)
    set_society(user, society.id, db)
    return {"status": "success", "society_id": society.id, "name": society.name}

# --- Search Endpoints ---

@app.get("/skills/nearby")
async def get_nearby_skills(lat: float, lng: float, radius: float = 5.0, current_user_id: int = None, db: Session = Depends(get_db)):
    users = db.query(User).all()
    nearby_user_ids = []
    for u in users:
        if u.latitude is not None and u.longitude is not None:
            dist = haversine(lat, lng, u.latitude, u.longitude)
            if dist <= radius * 1000:
                nearby_user_ids.append(u.id)

    if not nearby_user_ids:
        return []

    liked_skill_ids = set()
    if current_user_id:
        likes = db.query(SkillLike).filter(SkillLike.user_id == current_user_id).all()
        liked_skill_ids = {l.skill_id for l in likes}

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
            "society_id": u.society_id if u else None,
            "society_name": db.query(Society.name).filter(Society.id == u.society_id).scalar() if u and u.society_id else None,
            "is_liked": s.id in liked_skill_ids,
            "user_lat": u.latitude if u else None,
            "user_lng": u.longitude if u else None,
        })
    return result

@app.get("/skills/society/{society_id}")
async def get_society_skills(society_id: int, current_user_id: int = None, db: Session = Depends(get_db)):
    society = db.query(Society).filter(Society.id == society_id).first()
    society_name = society.name if society else None

    liked_skill_ids = set()
    if current_user_id:
        likes = db.query(SkillLike).filter(SkillLike.user_id == current_user_id).all()
        liked_skill_ids = {l.skill_id for l in likes}

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
            "society_id": society_id,
            "society_name": society_name,
            "is_liked": s.id in liked_skill_ids,
            "user_lat": u.latitude if u else None,
            "user_lng": u.longitude if u else None,
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

# --- Like Endpoints ---

# --- Rating Endpoints ---

@app.post("/ratings/add")
async def add_rating(skill_id: int, from_user_id: int, rating: int, comment: str = "", db: Session = Depends(get_db)):
    skill = db.query(Skill).filter(Skill.id == skill_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    # Simple check: can only rate if accepted request exists? 
    # For now, allow rating any skill.
    
    rating_entry = SkillRating(
        skill_id=skill_id, 
        from_user_id=from_user_id, 
        to_user_id=skill.user_id,
        rating=rating, 
        comment=comment
    )
    db.add(rating_entry)
    db.commit()
    return {"status": "success"}

@app.get("/ratings/get/{skill_id}")
async def get_ratings(skill_id: int, db: Session = Depends(get_db)):
    ratings = db.query(SkillRating).filter(SkillRating.skill_id == skill_id).all()
    result = []
    for r in ratings:
        from_user = db.query(User).filter(User.id == r.from_user_id).first()
        result.append({
            "rating": r.rating,
            "comment": r.comment,
            "username": from_user.username if from_user else "Unknown",
        })
    return result

@app.post("/requests/send")
async def send_request(skill_id: int, from_user_id: int, message: str = "", db: Session = Depends(get_db)):
    skill = db.query(Skill).filter(Skill.id == skill_id).first()
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    if from_user_id == skill.user_id:
        raise HTTPException(status_code=400, detail="Cannot request your own skill")
    existing = db.query(SkillRequest).filter(
        SkillRequest.skill_id == skill_id,
        SkillRequest.from_user_id == from_user_id,
        SkillRequest.status == "pending",
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Request already sent")
    req = SkillRequest(skill_id=skill_id, from_user_id=from_user_id, to_user_id=skill.user_id, message=message)
    db.add(req)
    db.commit()
    db.refresh(req)
    return {"status": "success", "request_id": req.id}

@app.get("/requests/sent")
async def get_sent_requests(user_id: int, db: Session = Depends(get_db)):
    requests = db.query(SkillRequest).filter(SkillRequest.from_user_id == user_id).order_by(SkillRequest.created_at.desc()).all()
    result = []
    for r in requests:
        skill = db.query(Skill).filter(Skill.id == r.skill_id).first()
        result.append({
            "id": r.id,
            "skill_id": r.skill_id,
            "skill_title": skill.title if skill else "Unknown",
            "status": r.status,
            "message": r.message,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        })
    return result

@app.get("/requests/received")
async def get_received_requests(user_id: int, db: Session = Depends(get_db)):
    requests = db.query(SkillRequest).filter(SkillRequest.to_user_id == user_id).order_by(SkillRequest.created_at.desc()).all()
    result = []
    for r in requests:
        skill = db.query(Skill).filter(Skill.id == r.skill_id).first()
        from_user = db.query(User).filter(User.id == r.from_user_id).first()
        entry = {
            "id": r.id,
            "skill_id": r.skill_id,
            "skill_title": skill.title if skill else "Unknown",
            "from_username": from_user.username if from_user else "Unknown",
            "status": r.status,
            "message": r.message,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "requester_phone": None,
        }
        if r.status == "accepted" and from_user:
            entry["requester_phone"] = from_user.phone
        result.append(entry)
    return result

@app.get("/requests/sent/details")
async def get_sent_request_details(user_id: int, db: Session = Depends(get_db)):
    requests = db.query(SkillRequest).filter(SkillRequest.from_user_id == user_id).order_by(SkillRequest.created_at.desc()).all()
    result = []
    for r in requests:
        skill = db.query(Skill).filter(Skill.id == r.skill_id).first()
        owner = db.query(User).filter(User.id == r.to_user_id).first()
        owner_phone = None
        if r.status == "accepted" and skill:
            if skill.share_phone:
                owner_phone = skill.phone_number
        result.append({
            "id": r.id,
            "skill_id": r.skill_id,
            "skill_title": skill.title if skill else "Unknown",
            "to_username": owner.username if owner else "Unknown",
            "status": r.status,
            "message": r.message,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "owner_phone": owner_phone,
        })
    return result

@app.put("/requests/respond")
async def respond_request(request_id: int, user_id: int, status: str, db: Session = Depends(get_db)):
    req = db.query(SkillRequest).filter(SkillRequest.id == request_id, SkillRequest.to_user_id == user_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if status not in ("accepted", "rejected"):
        raise HTTPException(status_code=400, detail="Invalid status")
    req.status = status
    db.commit()
    return {"status": "success", "request_id": req.id, "new_status": req.status}

# --- Notification Endpoints ---

# --- End of Endpoints ---
