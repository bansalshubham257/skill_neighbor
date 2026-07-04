"""
Seed script: Creates 10 societies at varying distances from center,
10 users with different skills, 1 user per society, with reward tokens.
Run: DATABASE_URL="..." python3 seed.py
"""
import os, math, sys

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from models import Base, User, Society, Skill, AdToken, SkillLike, SCHEMA
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


clat, clng = 12.9655, 77.7092

def offset(lat, lng, dist_km, angle_deg):
    rad = math.radians(angle_deg)
    dlat = dist_km * math.cos(rad) / 111.0
    dlng = dist_km * math.sin(rad) / (111.0 * math.cos(math.radians(lat)))
    return lat + dlat, lng + dlng

societies_data = [
    ("Indiranagar Heights", 0.5, 0), ("Koramangala Gardens", 0.5, 90),
    ("MG Road Residency", 0.5, 180), ("Brigade Meadows", 0.5, 270),
    ("Lavelle View", 0.5, 45), ("Whitefield Estate", 1.2, 135),
    ("JP Nagar Towers", 1.2, 225), ("Malleshwaram Enclave", 1.2, 315),
    ("Electronic City Phase 1", 1.8, 180), ("Hebbal Lake View", 1.8, 0),
]

users_data = [
    ("admin","admin","admin@test.com","Math Tutoring","Expert math tutor for grades 1-10","Tutoring",500,"+919000000001"),
    ("user2","user2","user2@test.com","Yoga & Fitness","Certified yoga instructor","Fitness",400,"+919000000002"),
    ("user3","user3","user3@test.com","Piano Lessons","Grade 8 pianist","Music",600,"+919000000003"),
    ("user4","user4","user4@test.com","Cooking Classes","Italian & Indian cuisine","Cooking",350,"+919000000004"),
    ("user5","user5","user5@test.com","Plumbing Services","10 years experience","Plumbing",300,"+919000000005"),
    ("user6","user6","user6@test.com","Electrical Repairs","Licensed electrician","Electrical",350,"+919000000006"),
    ("user7","user7","user7@test.com","Photography","Event & portrait","Photography",800,"+919000000007"),
    ("user8","user8","user8@test.com","Gardening","Landscaping & plant care","Gardening",250,"+919000000008"),
    ("user9","user9","user9@test.com","Pet Grooming","Dogs & cats grooming","Pet Care",300,"+919000000009"),
    ("user10","user10","user10@test.com","Web Development","Full-stack dev","IT Support",1000,"+919000000010"),
    ("shubham","shubham","shubham@test.com","Carpentry","Custom furniture & repair","Carpentry",450,"+919000000011"),
]

def seed_all(db):
    """Seed all data into the database using an existing session."""

    # Clear existing data
    db.query(SkillLike).delete()
    db.query(AdToken).delete()
    db.query(Skill).delete()
    admin = db.query(User).filter(User.username == "admin").first()
    if admin:
        admin.society_id = None
        db.commit()
    db.query(User).filter(User.username != "admin").delete()
    db.query(Society).delete()
    db.commit()

    created_societies = []
    for i, (name, dist, angle) in enumerate(societies_data):
        lat, lng = offset(clat, clng, dist, angle)
        society = Society(name=name, latitude=lat, longitude=lng)
        db.add(society); db.commit(); db.refresh(society)
        created_societies.append(society)
        print(f"  Society: {name} ({dist}km, {angle}°)")

    print("")
    for i, (uname, pwd, email, stitle, sdesc, cat, rate, phone) in enumerate(users_data):
        if uname == "shubham":
            user = db.query(User).filter(User.username == uname).first()
        if not user:
            user = User(username=uname, password=hash_password(pwd), email=email, latitude=clat, longitude=clng)
            db.add(user); db.commit(); db.refresh(user)
        db.add(Skill(user_id=user.id, title=stitle, description=sdesc, category=cat, price_type="Fixed", hourly_rate=rate, phone_number=phone))
            for tt in ["CONTACT", "CHAT", "BOOKMARK"]:
                db.add(AdToken(user_id=user.id, token_type=tt, count=5))
            db.commit()
            print(f"  User: {uname} -> {stitle} (no society)")
            continue

        slat, slng = offset(clat, clng, societies_data[i][1], societies_data[i][2])
        user = db.query(User).filter(User.username == uname).first()
    if not user:
        user = User(username=uname, password=hash_password(pwd), email=email, latitude=slat, longitude=slng, society_id=created_societies[i].id)
        db.add(user); db.commit(); db.refresh(user)
    else:
        user.latitude = slat; user.longitude = slng; user.society_id = created_societies[i].id; user.password = hash_password(pwd); db.commit()

        db.add(Skill(user_id=user.id, title=stitle, description=sdesc, category=cat, price_type="Fixed", hourly_rate=rate, phone_number=phone))
        for tt in ["CONTACT", "CHAT", "BOOKMARK"]:
            db.add(AdToken(user_id=user.id, token_type=tt, count=5))
        db.commit()
        print(f"  User: {uname} -> {stitle} in {created_societies[i].name}")

    print("\nSeed complete!")


if __name__ == "__main__":
    DATABASE_URL = os.getenv("DATABASE_URL")
    if not DATABASE_URL:
        print("Set DATABASE_URL env var"); sys.exit(1)
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {SCHEMA}"))
        conn.commit()
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        seed_all(db)
    finally:
        db.close()
